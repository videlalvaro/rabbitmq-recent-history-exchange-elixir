# RabbitMQ Recent History Exchange

This an example RabbitMQ plugin implemented in the __Elixir Programming Language__

Keeps track of the last 20 messages that passed through the exchange. Every time a queue is bound to the exchange it delivers that last 20 messages to them. This is useful for implementing a very simple __Chat History__ where clients that join the conversation can get the latest messages.

Exchange Type: `x-recent-history`

## Requirements

To build this plugin you need to have [Elixir](http://elixir-lang.org/) installed in your machine. Follow the instructions on their website.

## Installation

Install and setup the RabbitMQ Public Umbrella as explained here: [http://www.rabbitmq.com/plugin-development.html#getting-started](http://www.rabbitmq.com/plugin-development.html#getting-started).

Then `cd` into the umbrella folder and type:

```bash
git clone git://github.com/videlalvaro/elixir_wrapper.git
git clone git://github.com/videlalvaro/rabbitmq-recent-history-exchange-elixir.git
cd rabbitmq-recent-history-exchange-elixir
make
```

Finally copy the file `elixir.*.ez` and `rabbitmq_recent_history_exchange_elixir*.ez` from the `dist` folder into the `$RABBITMQ_HOME/plugins` folder.

## License

See LICENSE.md
