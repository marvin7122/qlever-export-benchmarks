# NVMe passthrough engaged probe on AWS i4i.large (conclusion)

Date: 2026-09-22. Box: i4i.large, eu-north-1, Ubuntu 24.04, kernel
6.17.0-1017-aws, 2 vCPU, 15 GB RAM. Instance store `/dev/nvme1n1`
(435.9 GB) verified raw (blkid finds no filesystem); namespace char
device `/dev/ng1n1` exists (root-only).

## Result: BLOCKED. The Nitro-virtualized NVMe rejects guest passthrough.

Probes (standalone C, liburing, reads only, exact QLever SQE preparation
mirrored from `src/util/NvmePassthrough.h` on `bench/ch7-nvmept`):

| # | Path | Outcome |
|---|------|---------|
| 1 | `NVME_IOCTL_ID` on `/dev/ng1n1` | nsid = 1, works |
| 2 | Identify via `NVME_IOCTL_ADMIN_CMD` | works, LBA size 512, flbas 0 |
| 3 | NVM read via `IORING_OP_URING_CMD` + SQE128 (QLever's `preparePassthroughRead` field for field) | `cqe.res = -95` (EOPNOTSUPP), 200/200 |
| 4 | Admin identify via `IORING_OP_URING_CMD` | `cqe.res = -95` |
| 5 | NVM read via `NVME_IOCTL_SUBMIT_IO` | device-side rejection (rc 8320, buffer untouched) |

Controls: kernel exports `nvme_uring_cmd` (4 hits in kallsyms),
`CONFIG_IO_URING=y`, ring negotiates SQE128 (flags 1024), plain
`IORING_OP_READ` through the same ring returns 17 bytes, and `pread` on
`/dev/nvme1n1` medians 302 ns. O_RDONLY vs O_RDWR changes nothing.

## Reading

The submission machinery is healthy; the refusal sits below it. Admin
identify succeeds through ioctl but every NVM data command fails on both
the ioctl and the uring path, and uring rejects even admin. The
consistent reading is that the Nitro card filters guest-direct NVMe
commands, so no guest submission path can engage passthrough on this
instance type. QLever's fallback (plain block-layer read on any failed
probe) is therefore the only operative path here, which the feature
already implements.

## Update 2026-09-22: ENGAGED on Hetzner bare metal, root cause found

Same `-EOPNOTSUPP` on real hardware (2x Toshiba KXG60, kernel 6.8,
`/dev/ng0n1`) proved the failure was in the submission, not the
hypervisor. bpftrace showed io_uring core plus the kernel dispatcher
`nvme_ns_chr_uring_cmd` both run, and the exact 6.8 source of the
dispatcher names the gate: `nvme_uring_cmd_checks` rejects any ring
without **both** `IORING_SETUP_SQE128` and `IORING_SETUP_CQE32`. The
probes (and QLever's `IoUringManager`) requested SQE128 only. Adding
`IORING_SETUP_CQE32` gives `cqe.res=0` on identify plus NVM reads:
ENGAGED OK. Single-shot 1-block read medians 18.4 us passthrough vs
0.62 us cached pread (the pread re-read the same LBAs hot; not a fair
race, only an engagement proof). Fixed in QLever as
`bench/ch7-nvmept` commit `e688eaabb` (request CQE32 alongside SQE128,
plain-ring fallback with warning otherwise); test build queued as 4383
(`IoUringManagerTest`).

## Consequence

A full QLever engaged A/B still needs raw namespace space: both Hetzner
disks are RAID1 members (`md0`/`md1`/`md2`), so reads-only probing is
safe but serving an index from raw LBAs needs a reinstall without RAID
(Robot decision). The i4i.large instance should be stopped.
