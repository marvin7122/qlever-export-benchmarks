total samples: 17765

| category | share |
|---|---|
| other | 96.7 % |
| result streaming / HTTP | 1.2 % |
| kernel other | 1.0 % |
| other syscalls (futex, mmap, ...) | 0.7 % |
| page faults | 0.2 % |
| page-cache fast path (preadv2, kernel+libc) | 0.1 % |
| allocation / refcount | 0.0 % |
| string building / memcpy | 0.0 % |

| # | symbol (self) | share | main call paths |
|---|---|---|---|
| 1 | `qlever-server` | 96.6 % |  (100 %) |
| 2 | `rep_movs_alternative` | 0.3 % |  (62 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (38 %) |
| 3 | `kernel_init_pages` | 0.2 % |  (59 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (41 %) |
| 4 | `exit_to_user_mode_loop` | 0.2 % |  (100 %) |
| 5 | `srso_safe_ret` | 0.1 % |  (85 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (15 %) |
| 6 | `task_tick_fair` | 0.1 % |  (100 %) |
| 7 | `update_curr` | 0.1 % |  (100 %) |
| 8 | `futex_do_wait` | 0.1 % |  (100 %) |
| 9 | `ep_send_events` | 0.1 % | epoll_wait < boost::asio::detail::epoll_reactor::run < boost::asio::detail::scheduler::run < std::thread::_State_impl<std::thread::_Invoker<std::tuple<HttpServer< (55 %);  (45 %) |
| 10 | `__sysvec_apic_timer_interrupt` | 0.1 % | epoll_wait < boost::asio::detail::epoll_reactor::run < boost::asio::detail::scheduler::run < std::thread::_State_impl<std::thread::_Invoker<std::tuple<HttpServer< (55 %);  (45 %) |
| 11 | `futex_unqueue` | 0.1 % |  (100 %) |
| 12 | `__rmqueue_pcplist` | 0.1 % |  (56 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (44 %) |
| 13 | `memset_orig` | 0.1 % | sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (56 %);  (44 %) |
| 14 | `__futex_wait` | 0.0 % |  (88 %); [libc.so.6] < pthread_cond_wait < ad_utility::streams::detail::AsyncStreamGenerator<cppcoro::generator<s < ad_utility::InputRangeFromGet<std::__cxx11::basic_string<char, std::ch (12 %) |
| 15 | `arch_exit_to_user_mode_prepare.isra.0` | 0.0 % |  (86 %); epoll_wait < boost::asio::detail::epoll_reactor::run < boost::asio::detail::scheduler::run < std::thread::_State_impl<std::thread::_Invoker<std::tuple<HttpServer< (14 %) |
| 16 | `native_write_msr` | 0.0 % |  (100 %) |
| 17 | `asm_sysvec_apic_timer_interrupt` | 0.0 % |  (100 %) |
| 18 | `__const_udelay` | 0.0 % |  (100 %) |
| 19 | `x86_pmu_disable_all` | 0.0 % |  (100 %) |
| 20 | `restore_fpregs_from_fpstate` | 0.0 % |  (100 %) |
