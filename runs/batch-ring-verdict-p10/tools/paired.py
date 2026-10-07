import csv,glob,statistics as st,collections,sys
run=sys.argv[1]; base=sys.argv[2]
for scen in ['cold','warm']:
  for q in ['H-vocab-label-large-de','H-vocab-random-label-de-200k','H-vocab-label-large']:
    W=collections.defaultdict(dict)
    for f in glob.glob(f'{run}/{scen}/{q}/*/raw/results.csv'):
        arm=f.split('/')[-3]
        for r in csv.DictReader(open(f)):
            if r['status']!='complete': continue
            W[int(r['run_id'].rsplit('-r',1)[1])][arm]=(float(r['elapsed_s']),float(r['first_byte_s'] or 0))
    if not W: continue
    arms=sorted({a for v in W.values() for a in v})
    for a in arms:
        if a==base: continue
        d=[(W[r][a][0]/W[r][base][0]-1)*100 for r in W if a in W[r] and base in W[r]]
        tb=st.median(W[r][a][1] for r in W if a in W[r]); tbb=st.median(W[r][base][1] for r in W if base in W[r])
        print(f"{scen} {q} {a}: paired n={len(d)} median {st.median(d):+.1f}% [{min(d):+.1f},{max(d):+.1f}]  ttfb {tbb:.2f}->{tb:.2f}")
