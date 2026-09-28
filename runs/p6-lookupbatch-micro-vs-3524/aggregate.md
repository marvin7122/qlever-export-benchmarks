# part 6 synthetic rows, ns per word, median [min-max], each measurement >= 10 s

## ondisk-128
base | lookupBatch | 1314.6 [1250.2-1320.6] n=10
base | single lookups | 1014.5 [993.9-1019.1] n=10
variant | lookupBatch | 1314.0 [1300.7-1322.9] n=10
variant | single lookups | 1014.3 [1008.1-1015.9] n=10
same binary (base): lookupBatch vs single lookups: +29.6 % slower
same binary (variant): lookupBatch vs single lookups: +29.5 % slower
cross binary: lookupBatch variant vs base: -0.0 % parity
cross binary: single lookups variant vs base: -0.0 % parity

## hybrid-128
base | lookupBatch | 509.3 [503.4-516.0] n=10
base | single lookups | 501.3 [495.4-504.3] n=10
variant | lookupBatch | 627.8 [620.2-631.9] n=10
variant | single lookups | 501.9 [492.8-511.7] n=10
same binary (base): lookupBatch vs single lookups: +1.6 % parity
same binary (variant): lookupBatch vs single lookups: +25.1 % slower
cross binary: lookupBatch variant vs base: +23.3 % slower
cross binary: single lookups variant vs base: +0.1 % parity

## ondisk-2048
base | lookupBatch | 1779.7 [1733.7-1795.4] n=10
base | single lookups | 997.6 [979.2-1005.4] n=10
variant | lookupBatch | 1791.5 [1776.3-1800.3] n=10
variant | single lookups | 996.9 [990.3-1003.0] n=10
same binary (base): lookupBatch vs single lookups: +78.4 % slower
same binary (variant): lookupBatch vs single lookups: +79.7 % slower
cross binary: lookupBatch variant vs base: +0.7 % parity
cross binary: single lookups variant vs base: -0.1 % parity

## hybrid-2048
base | lookupBatch | 584.9 [575.7-591.1] n=10
base | single lookups | 568.7 [560.0-572.4] n=10
variant | lookupBatch | 924.9 [913.0-925.9] n=10
variant | single lookups | 569.0 [554.3-571.9] n=10
same binary (base): lookupBatch vs single lookups: +2.9 % slower
same binary (variant): lookupBatch vs single lookups: +62.5 % slower
cross binary: lookupBatch variant vs base: +58.1 % slower
cross binary: single lookups variant vs base: +0.1 % parity

## e2e-200k-50k
base | lookupBatch | 718.1 [704.8-721.6] n=10
base | sequential single-word lookups | 650.2 [642.9-654.8] n=10
variant | lookupBatch | 1073.7 [1068.8-1076.3] n=10
variant | sequential single-word lookups | 649.4 [640.2-660.1] n=10
same binary (base): lookupBatch vs sequential single-word lookups: +10.4 % slower
same binary (variant): lookupBatch vs sequential single-word lookups: +65.3 % slower
cross binary: lookupBatch variant vs base: +49.5 % slower
cross binary: sequential single-word lookups variant vs base: -0.1 % parity
