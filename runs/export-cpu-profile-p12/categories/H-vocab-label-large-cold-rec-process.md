total samples: 18369

| category | share |
|---|---|
| other | 96.3 % |
| result streaming / HTTP | 1.3 % |
| kernel other | 1.1 % |
| other syscalls (futex, mmap, ...) | 0.7 % |
| page-cache fast path (preadv2, kernel+libc) | 0.3 % |
| page faults | 0.3 % |
| string building / memcpy | 0.0 % |

| # | symbol (self) | share | main call paths |
|---|---|---|---|
| 1 | `qlever-server` | 96.3 % |  (100 %) |
| 2 | `rep_movs_alternative` | 0.4 % |  (71 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (29 %) |
| 3 | `kernel_init_pages` | 0.4 % |  (66 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (34 %) |
| 4 | `exit_to_user_mode_loop` | 0.2 % |  (97 %); [libc.so.6] < pthread_cond_wait < ad_utility::streams::detail::AsyncStreamGenerator<cppcoro::generator<s < ad_utility::InputRangeFromGet<std::__cxx11::basic_string<char, std::ch (3 %) |
| 5 | `srso_safe_ret` | 0.1 % |  (94 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (6 %) |
| 6 | `futex_unqueue` | 0.1 % |  (100 %) |
| 7 | `asm_sysvec_apic_timer_interrupt` | 0.1 % |  (100 %) |
| 8 | `restore_fpregs_from_fpstate` | 0.1 % |  (100 %) |
| 9 | `task_tick_fair` | 0.1 % |  (100 %) |
| 10 | `xas_load` | 0.1 % |  (100 %) |
| 11 | `__rmqueue_pcplist` | 0.0 % |  (78 %); sendmsg < boost::asio::detail::socket_ops::non_blocking_send < boost::asio::detail::reactive_socket_send_op_base<boost::beast::buffer < boost::asio::detail::reactive_socket_service_base::do_start_op (22 %) |
| 12 | `native_read_msr` | 0.0 % |  (100 %) |
| 13 | `update_curr` | 0.0 % |  (100 %) |
| 14 | `__rcu_read_lock` | 0.0 % |  (100 %) |
| 15 | `ep_send_events` | 0.0 % | epoll_wait < boost::asio::detail::epoll_reactor::run < boost::asio::detail::scheduler::run < std::thread::_State_impl<std::thread::_Invoker<std::tuple<HttpServer< (100 %) |
| 16 | `ep_item_poll.isra.0` | 0.0 % | epoll_wait < boost::asio::detail::epoll_reactor::run < boost::asio::detail::scheduler::run < std::thread::_State_impl<std::thread::_Invoker<std::tuple<HttpServer< (100 %) |
| 17 | `tcp_poll` | 0.0 % | epoll_wait < boost::asio::detail::epoll_reactor::run < boost::asio::detail::scheduler::run < std::thread::_State_impl<std::thread::_Invoker<std::tuple<HttpServer< (100 %) |
| 18 | `rb_next` | 0.0 % |  (100 %) |
| 19 | `sched_tick` | 0.0 % |  (100 %) |
| 20 | `x86_pmu_disable_all` | 0.0 % |  (100 %) |
