| category (by leaf function) | idea 3 (v2, rank off) | ideas 2+3 (rank on) | ideas 2+3 + prefetch + huge pages |
|---|---|---|---|
| in-RAM membership: binary search / rank lookup | 43.6 % | 5.4 % | 19.2 % |
| FSST decoding | 12.2 % | 17.2 % | 17.9 % |
| building lookup results | 5.5 % | 9.3 % | 2.3 % |
| reading the in-RAM entry | 8.8 % | 14.2 % | 1.8 % |
| runtime checks | 4.9 % | 8.0 % | 8.6 % |
| query evaluation (scan, join, libzstd, compareThreeWay) | 3.1 % | 5.7 % | 5.7 % |
| memory allocation and copies | 5.4 % | 10.6 % | 11.7 % |
| formatting and escaping | 0.2 % | 0.4 % | 0.5 % |
| kernel / syscalls / I/O | 0.7 % | 1.0 % | 1.0 % |
| rest | 6.7 % | 16.4 % | 19.1 % |
| (below 0.1 % each, not listed) | 8.8 % | 11.8 % | 12.1 % |

### top self symbols: idea 3 (v2, rank off)
- 43.29 % [in-RAM membership: binary search / rank lookup] ad_utility::vocabulary::VocabularyInMemoryBinSearch::positionOfIndex
- 9.06 % [FSST decoding] fsst_decompress
- 8.81 % [reading the in-RAM entry] ad_utility::vocabulary::VocabularyInMemoryBinSearch::wordAtPosition
- 5.54 % [building lookup results] ad_utility::vocabulary::makePmrVocabBatchLookupResult
- 4.92 % [runtime checks] void ad_utility::detail::adCorrectnessCheckImpl<>
- 1.76 % [memory allocation and copies] std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > ql::engine::export_v2::
- 1.27 % [memory allocation and copies] std::vector<std::optional<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, cha
- 1.09 % [rest] 0x000000000007772d
- 0.90 % [query evaluation (scan, join, libzstd, compareThreeWay)] ValueId::compareThreeWay
- 0.90 % [FSST decoding] ad_utility::vocabulary::CompressedVocabulary<ad_utility::vocabulary::VocabularyInternalExternal, ad_utility::vocabulary:
- 0.74 % [memory allocation and copies] std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string
- 0.65 % [query evaluation (scan, join, libzstd, compareThreeWay)] void ad_utility::detail::BlockZipperJoinImplCRTP<ad_utility::detail::BlockZipperJoinImpl<ad_utility::detail::JoinSide<ad
- 0.62 % [query evaluation (scan, join, libzstd, compareThreeWay)] ql::engine::export_v2::ExportEngineV2::appendSerializedRows
- 0.60 % [FSST decoding] FsstDecoder::maxDecompressedSize
- 0.54 % [memory allocation and copies] std::optional<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, char const*> > 
- 0.50 % [rest] 0x0000000000188d22
- 0.50 % [FSST decoding] FsstRepeatedDecoder<2ul>::decompressInto
- 0.48 % [FSST decoding] FsstDecoder::decompressInto
- 0.45 % [memory allocation and copies] operator new
- 0.44 % [kernel / syscalls / I/O] rep_movs_alternative
- 0.44 % [FSST decoding] ad_utility::vocabulary::detail::DecoderMultiplexer<FsstRepeatedDecoder<2ul> >::decompressInto
- 0.41 % [query evaluation (scan, join, libzstd, compareThreeWay)] ad_utility::AddCombinedRowToIdTable::flush

### top self symbols: ideas 2+3 (rank on)
- 14.23 % [reading the in-RAM entry] ad_utility::vocabulary::VocabularyInMemoryBinSearch::wordAtPosition
- 10.71 % [FSST decoding] fsst_decompress
- 9.30 % [building lookup results] ad_utility::vocabulary::makePmrVocabBatchLookupResult
- 7.98 % [runtime checks] void ad_utility::detail::adCorrectnessCheckImpl<>
- 3.73 % [in-RAM membership: binary search / rank lookup] ad_utility::vocabulary::VocabularyInMemoryBinSearch::positionOfIndex
- 3.36 % [memory allocation and copies] std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > ql::engine::export_v2::
- 2.44 % [rest] 0x000000000007772d
- 1.97 % [query evaluation (scan, join, libzstd, compareThreeWay)] ValueId::compareThreeWay
- 1.92 % [memory allocation and copies] std::vector<std::optional<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, cha
- 1.76 % [FSST decoding] ad_utility::vocabulary::CompressedVocabulary<ad_utility::vocabulary::VocabularyInternalExternal, ad_utility::vocabulary:
- 1.63 % [memory allocation and copies] std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string
- 1.34 % [query evaluation (scan, join, libzstd, compareThreeWay)] void ad_utility::detail::BlockZipperJoinImplCRTP<ad_utility::detail::BlockZipperJoinImpl<ad_utility::detail::JoinSide<ad
- 1.20 % [FSST decoding] FsstDecoder::decompressInto
- 1.08 % [FSST decoding] FsstDecoder::maxDecompressedSize
- 1.06 % [in-RAM membership: binary search / rank lookup] __popcountdi2
- 1.05 % [query evaluation (scan, join, libzstd, compareThreeWay)] ql::engine::export_v2::ExportEngineV2::appendSerializedRows
- 1.02 % [FSST decoding] FsstRepeatedDecoder<2ul>::decompressInto
- 0.95 % [memory allocation and copies] std::optional<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, char const*> > 
- 0.93 % [FSST decoding] ad_utility::vocabulary::detail::DecoderMultiplexer<FsstRepeatedDecoder<2ul> >::decompressInto
- 0.90 % [rest] 0x0000000000188d22
- 0.71 % [query evaluation (scan, join, libzstd, compareThreeWay)] ad_utility::AddCombinedRowToIdTable::flush
- 0.70 % [memory allocation and copies] operator new

### top self symbols: ideas 2+3 + prefetch + huge pages
- 10.69 % [FSST decoding] fsst_decompress
- 9.94 % [in-RAM membership: binary search / rank lookup] ad_utility::vocabulary::VocabularyInternalExternal::lookupBatch
- 8.58 % [runtime checks] void ad_utility::detail::adCorrectnessCheckImpl<>
- 8.27 % [in-RAM membership: binary search / rank lookup] ad_utility::vocabulary::VocabularyInMemoryBinSearch::positionOfIndex
- 3.38 % [memory allocation and copies] std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> > ql::engine::export_v2::
- 2.91 % [rest] 0x000000000007772d
- 2.53 % [memory allocation and copies] std::vector<std::optional<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, cha
- 2.32 % [building lookup results] ad_utility::vocabulary::makePmrVocabBatchLookupResult
- 1.97 % [FSST decoding] ad_utility::vocabulary::CompressedVocabulary<ad_utility::vocabulary::VocabularyInternalExternal, ad_utility::vocabulary:
- 1.81 % [memory allocation and copies] std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >::basic_string
- 1.80 % [query evaluation (scan, join, libzstd, compareThreeWay)] ValueId::compareThreeWay
- 1.79 % [reading the in-RAM entry] ad_utility::vocabulary::VocabularyInMemoryBinSearch::wordAtPosition
- 1.46 % [query evaluation (scan, join, libzstd, compareThreeWay)] void ad_utility::detail::BlockZipperJoinImplCRTP<ad_utility::detail::BlockZipperJoinImpl<ad_utility::detail::JoinSide<ad
- 1.29 % [FSST decoding] FsstDecoder::decompressInto
- 1.21 % [FSST decoding] FsstDecoder::maxDecompressedSize
- 1.17 % [FSST decoding] FsstRepeatedDecoder<2ul>::decompressInto
- 1.13 % [rest] 0x0000000000188d22
- 1.09 % [query evaluation (scan, join, libzstd, compareThreeWay)] ql::engine::export_v2::ExportEngineV2::appendSerializedRows
- 1.03 % [in-RAM membership: binary search / rank lookup] __popcountdi2
- 1.00 % [memory allocation and copies] std::optional<std::pair<std::__cxx11::basic_string<char, std::char_traits<char>, std::allocator<char> >, char const*> > 
- 0.91 % [rest] 0x000000000007722e
- 0.88 % [FSST decoding] ad_utility::vocabulary::detail::DecoderMultiplexer<FsstRepeatedDecoder<2ul> >::decompressInto
