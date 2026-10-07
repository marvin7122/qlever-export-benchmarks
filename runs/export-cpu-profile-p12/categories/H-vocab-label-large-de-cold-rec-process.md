total samples: 17130

| category | share |
|---|---|
| page-cache fast path (preadv2, kernel+libc) | 58.0 % |
| vocab lookup: internal/external membership probe | 16.2 % |
| triple instantiation | 4.3 % |
| FSST decode | 4.1 % |
| allocation / refcount | 3.4 % |
| other | 2.1 % |
| sort / dedup of IDs | 1.9 % |
| vocab lookup: offsets / batch plumbing | 1.7 % |
| Turtle formatting / escaping | 1.6 % |
| io_uring (submit/wait, kernel+lib) | 1.5 % |
| string building / memcpy | 1.4 % |
| other syscalls (futex, mmap, ...) | 1.2 % |
| correctness checks | 0.9 % |
| kernel other | 0.7 % |
| IdCache (LRU) | 0.5 % |
| result streaming / HTTP | 0.4 % |
| page faults | 0.2 % |

| # | symbol (self) | share | main call paths |
|---|---|---|---|
| 1 | `VocabularyInMemoryBinSearch::positionOfIndex` | 15.6 % | VocabularyInMemoryBinSearch::operator[] < VocabularyInternalExternal::lookupBatch < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular (100 %) |
| 2 | `xas_load` | 6.6 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (46 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (46 %) |
| 3 | `rep_movs_alternative` | 3.9 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (47 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (45 %) |
| 4 | `filemap_get_read_batch` | 3.7 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (49 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (48 %) |
| 5 | `fsst_decompress` | 3.4 % | FsstRepeatedDecoder<2ul>::decompressInto < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < PolymorphicVocabulary::lookupBatch (100 %) |
| 6 | `qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByColumn` | 2.6 % | qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q < ad_utility::RangeToInputRangeFromGet<std::ranges::join_view<std::range < ad_utility::InputRangeFromGetCallable<std::__cxx11::basic_string<char, (99 %); qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q < std::ranges::join_view<std::ranges::transform_view<std::ranges::owning < ad_utility::RangeToInputRangeFromGet<std::ranges::join_view<std::range (1 %) |
| 7 | `kernel_init_pages` | 1.9 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (56 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (40 %) |
| 8 | `srso_safe_ret` | 1.8 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (48 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (47 %) |
| 9 | `filemap_read` | 1.8 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (48 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (46 %) |
| 10 | `std::_Sp_counted_base<` | 1.7 % | qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByCo < qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q < ad_utility::RangeToInputRangeFromGet<std::ranges::join_view<std::range (73 %); ad_utility::InputRangeFromGetCallable<std::__cxx11::basic_string<char, < ad_utility::InputRangeFromGet<std::__cxx11::basic_string<char, std::ch < ExportQueryExecutionTrees::constructQueryResultToStream < ad_utility::InputRangeFromLoopControlGet<ExportQueryExecutionTrees::co (12 %) |
| 11 | `[libc.so.6]` | 1.4 % | ql::export_formatting::FastExportStreamFormatter::writeRaw < ql::export_formatting::FastExportStreamFormatter::writeTriple < ad_utility::InputRangeFromGetCallable<std::__cxx11::basic_string<char, < ad_utility::InputRangeFromGet<std::__cxx11::basic_string<char, std::ch (21 %); std::__cxx11::basic_string<char, std::char_traits<char>, std::allocato < ad_utility::InputRangeFromLoopControlGet<ExportQueryExecutionTrees::co < ad_utility::InputRangeFromGet<std::__cxx11::basic_string<char, std::ch < ExportQueryExecutionTrees::computeResult[abi:cxx11] (14 %) |
| 12 | `ValueId::compareThreeWay` | 1.4 % | absl::lts_20260107::container_internal::raw_hash_set<absl::lts_2026010 < qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByCo < qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q (69 %); qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByCo < qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q < ad_utility::RangeToInputRangeFromGet<std::ranges::join_view<std::range (19 %) |
| 13 | `vfs_readv` | 1.4 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (52 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (48 %) |
| 14 | `[libjemalloc.so.2]` | 0.9 % | [libjemalloc.so.2] < [libjemalloc.so.2] < [libjemalloc.so.2] < [libjemalloc.so.2] (33 %); [libjemalloc.so.2] < std::_Sp_counted_base< < qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByCo < qlever::constructExport::ConstructBatchEvaluator::evaluateBatch (14 %) |
| 15 | `void ad_utility::detail::adCorrectnessCheckImpl<>` | 0.9 % | CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < PolymorphicVocabulary::lookupBatch < Vocabulary<PolymorphicVocabulary, TripleComponentComparatorImpl<Locale (35 %); FsstRepeatedDecoder<2ul>::decompressInto < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < CompressedVocabulary<VocabularyInternalExternal, ad_utility::vocabular < PolymorphicVocabulary::lookupBatch (14 %) |
| 16 | `ext4_file_read_iter` | 0.8 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (49 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (46 %) |
| 17 | `std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_str` | 0.8 % | qlever::constructExport::ConstructBatchEvaluator::stringAndTypeToEvalu < qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByCo < qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q (82 %); std::vector<std::optional<std::pair<std::__cxx11::basic_string<char, s < qlever::constructExport::ConstructBatchEvaluator::evaluateVariableByCo < qlever::constructExport::ConstructBatchEvaluator::evaluateBatch < std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q (18 %) |
| 18 | `qlever::constructExport::instantiateBatch` | 0.8 % | std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q < ad_utility::RangeToInputRangeFromGet<std::ranges::join_view<std::range < ad_utility::InputRangeFromGetCallable<std::__cxx11::basic_string<char, < ad_utility::InputRangeFromGet<std::__cxx11::basic_string<char, std::ch (99 %); std::vector<qlever::constructExport::EvaluatedTriple, std::allocator<q < std::ranges::join_view<std::ranges::transform_view<std::ranges::owning < ad_utility::RangeToInputRangeFromGet<std::ranges::join_view<std::range < ad_utility::InputRangeFromGetCallable<std::__cxx11::basic_string<char, (1 %) |
| 19 | `:2532440` | 0.7 % |  (100 %) |
| 20 | `do_iter_readv_writev` | 0.7 % | preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readOffsetPairs < VocabularyOnDisk::lookupBatch (51 %); preadv64v2 < ad_utility::readPageCacheHits < VocabularyOnDisk::readStrings < VocabularyOnDisk::lookupBatch (49 %) |
