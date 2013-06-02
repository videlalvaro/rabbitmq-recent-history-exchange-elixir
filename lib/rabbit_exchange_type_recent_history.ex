defmodule RabbitExchangeTypeRecentHistory do

  @behaviour :rabbit_exchange_type

  Module.register_attribute __MODULE__,
         :rabbit_boot_step,
         accumulate: true, persist: true

  @rabbit_boot_step { __MODULE__,
                      [{:description, "exchange type x-recent-history"},
                       {:mfa, {:rabbit_registry, :register,
                               [:exchange, <<"x-recent-history">>, __MODULE__]}},
                       {:requires, :rabbit_registry},
                       {:enables, :kernel_ready}]}

  @rabbit_boot_step { :rabbit_exchange_type_recent_history_mnesia,
                      [{:description, "recent history exchange type: mnesia"},
                       {:mfa, {__MODULE__, :setup_schema, []}},
                       {:requires, :database},
                       {:enables, :external_infrastructure}]}

  defrecord :exchange, Record.extract(:exchange,
                                     from_lib: "rabbit_common/include/rabbit.hrl")

  defrecord :delivery, Record.extract(:delivery,
                                     from_lib: "rabbit_common/include/rabbit.hrl")

  defrecord :binding, Record.extract(:binding,
                                     from_lib: "rabbit_common/include/rabbit.hrl")

  defrecord :basic_message, Record.extract(:basic_message,
                                     from_lib: "rabbit_common/include/rabbit.hrl")

  defrecord :cached, key: nil, content: nil

  def description() do
    [{:name, <<"x-recent-history">>}, {:description, <<"Recent History Exchange.">>}]
  end

  def serialise_events() do
    false
  end

  def route(:exchange[name: x_name], :delivery[message: :basic_message[content: content]]) do
    cache_msg(x_name, content)
    :rabbit_router.match_routing_key(x_name, [:_])
  end

  def validate(_x) do
    :ok
  end

  def validate_binding(_x, _b) do
    :ok
  end

  def create(_tx, _x) do
    :ok
  end

  def delete(:transaction, :exchange[name: x_name ], _bs) do
    f = fn -> :mnesia.delete(:rh_exchange_table, x_name, :write) end
    :rabbit_misc.execute_mnesia_transaction(f)
    :ok
  end

  def delete(:none, _exchange, _bs) do
    :ok
  end

  def policy_changed(_x1, _x2) do
    :ok
  end

  def add_binding(:transaction, :exchange[name: x_name ], :binding[destination: q_name ]) do
    case :rabbit_amqqueue.lookup(q_name) do
      {:error, :not_found} ->
        queue_not_found_error(q_name)
      {:ok, q} ->
        cached = get_msgs_from_cache(x_name)
        msgs = msgs_from_content(x_name, cached)
        deliver_messages(q, msgs)
    end
    :ok
  end

  def add_binding(:none, _exchange, _binding) do
    :ok
  end

  def remove_bindings(_tx, _x, _bs) do
    :ok
  end

  def assert_args_equivalence(x, args) do
    :rabbit_exchange.assert_args_equivalence(x, args)
  end

  def setup_schema() do
    case :mnesia.create_table(:rh_exchange_table,
                             [{:attributes, [:key, :content]},
                              {:record_name, :cached},
                              {:type, :set}]) do
        {:atomic, :ok} -> :ok
        {:aborted, {:already_exists, :rh_exchange_table}} -> :ok
    end
  end

  defp cache_msg(x_name, content) do
    f = fn ->
          cached = get_msgs_from_cache(x_name)
          store_msg(x_name, cached, content)
        end
    :rabbit_misc.execute_mnesia_transaction(f)
  end

  defp get_msgs_from_cache(x_name) do
    # TODO see how to match against x_name
    f = fn ->
          case :mnesia.read(:rh_exchange_table, x_name) do
            [] ->
              []
            [:cached[key: _x_name, content: cached]] ->
              cached
          end
        end
    :rabbit_misc.execute_mnesia_transaction(f)
  end

  defp store_msg(key, cached, content) do
    to_keep = 19
    :mnesia.write(:rh_exchange_table,
                  :cached[key: key,
                         content: [content | :lists.sublist(cached, to_keep)]],
                  :write)
  end

  defp msgs_from_content(x_name, cached) do
    f = fn content ->
             {props, payload} = :rabbit_basic.from_content(content)
             :rabbit_basic.message(x_name, <<"">>, props, payload)
        end
    :lists.map(f, cached)
  end

  defp deliver_messages(queue, msgs) do
    f = fn msg ->
             delivery = :rabbit_basic.delivery(false, msg, :undefined)
             :rabbit_amqqueue.deliver([queue], delivery)
        end
    :lists.map(f, :lists.reverse(msgs))
  end

  defp queue_not_found_error(q_name) do
    :rabbit_misc.protocol_error(:internal_error, "could not find queue '~s'", [q_name])
  end

end