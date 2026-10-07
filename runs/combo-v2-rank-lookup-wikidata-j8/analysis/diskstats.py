import sys, glob, collections, statistics, os, re, datetime, zoneinfo
TZ=zoneinfo.ZoneInfo("Europe/Berlin")
def window(run, name):
    m=re.match(r"combo-(.*)-cold-(\w+)-r(\d+)$", name)
    q,arm,rep=m.groups()
    log=open(f"{run}/cold/{q}/{arm}/raw/r{rep}-cold/qlever-server.log").read()
    ts=lambda pat: datetime.datetime.strptime(re.search(r"^(\S+ \S+) - INFO: "+pat, log, re.M).group(1), "%Y-%m-%d %H:%M:%S.%f").replace(tzinfo=TZ).timestamp()
    return ts("Processing the following SPARQL query"), ts("Done processing query")
# /proc/diskstats samples -> per trial: read GB, mean/peak MB/s, mean/peak IOPS, mean aqu-sz, mean %util, mean/max in_flight (per NVMe, summed)
def load(f):
    rows=collections.defaultdict(list)
    for l in open(f).read().split("\n")[1:]:
        p=l.split()
        if len(p)!=9: continue
        rows[p[1]].append([float(p[0])]+[int(x) for x in p[2:]])
    return rows
print("| trial | read GB | window s | mean MB/s | peak MB/s (0.25 s) | mean IOPS | peak IOPS | mean aqu-sz (2 NVMe) | mean %util (per NVMe) | in-flight mean / max |")
print("|---|---|---|---|---|---|---|---|---|---|")
for f in sorted(glob.glob(sys.argv[1]+"/disk/*.tsv")):
    rows=load(f); devs=["nvme0n1","nvme1n1"]
    t0,t1=window(sys.argv[1], os.path.basename(f)[:-4])
    for d in list(rows): rows[d]=[r for r in rows[d] if t0-0.3<=r[0]<=t1+0.3]
    n=min(len(rows[d]) for d in devs)
    if n<3: continue
    ivs=[]
    for i in range(1,n):
        dt=rows[devs[0]][i][0]-rows[devs[0]][i-1][0]
        rd=sum(rows[d][i][1]-rows[d][i-1][1] for d in devs)
        sec=sum(rows[d][i][3]-rows[d][i-1][3] for d in devs)
        tick=[rows[d][i][6]-rows[d][i-1][6] for d in devs]
        w=sum(rows[d][i][7]-rows[d][i-1][7] for d in devs)
        infl=sum(rows[d][i][5] for d in devs)
        ivs.append((dt,rd,sec*512,tick,w,infl))
    act=ivs   # all intervals of the query window
    if not act: continue
    T=sum(v[0] for v in act); B=sum(v[2] for v in act); R=sum(v[1] for v in act)
    tot=sum(v[2] for v in ivs)
    mbs=[v[2]/v[0]/1e6 for v in act]; iops=[v[1]/v[0] for v in act]
    aq=sum(v[4] for v in act)/(T*1000); util=sum(sum(v[3]) for v in act)/(T*1000*2)*100
    infl=[v[5] for v in act]
    name=os.path.basename(f)[6:-4]
    print(f"| {name} | {tot/1e9:.2f} | {T:.1f} | {B/T/1e6:.0f} | {max(mbs):.0f} | {R/T:.0f} | {max(iops):.0f} | {aq:.1f} | {util:.0f} % | {statistics.mean(infl):.1f} / {max(infl)} |")
