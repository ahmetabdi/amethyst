defmodule ExampleConnectionHandler do
  defmodule State do
    defstruct host: "irc.chat.twitch.tv",#"irc.twitch.tv",
              port: 6667,
              pass: "oauth:96mca2gjfoo5oahe3i66chla1p7nsx",
              nick: "skrillux",
              client: nil
  end

  def start_link(client, state \\ %State{}) do
    GenServer.start_link(__MODULE__, [%{state | client: client}])
  end

  def init([state]) do
    ExIrc.Client.add_handler state.client, self()
    ExIrc.Client.connect! state.client, state.host, state.port
    {:ok, state}
  end

  def handle_info({:connected, server, port}, state) do
    debug "Connected to #{server}:#{port}"
    ExIrc.Client.logon state.client, state.pass, state.nick, state.nick, state.nick
    {:noreply, state}
  end

  # Echos private messages back to the sender
  def handle_info({:received, message, from}, client) do
    IO.puts IO.ANSI.yellow() <> "#{from.nick} sent us a private message: #{message}"  <> IO.ANSI.reset()
    ExIrc.Client.msg client, :privmsg, from.nick, message
    {:noreply, client}
  end

  def handle_info({:received, message, from, channel}, client) do
    IO.puts IO.ANSI.yellow() <> "#{from.nick} sent a message to #{channel}: #{message}" <> IO.ANSI.reset()
    ExIrc.Client.msg client, :privmsg, from.nick, message
    {:noreply, client}
  end

  # Catch-all for messages you don't care about
  def handle_info(msg, state) do
    debug "Received unknown messsage:"
    IO.inspect msg
    {:noreply, state}
  end

  def terminate(_, state) do
    # Quit the channel and close the underlying client connection when the process is terminating
    ExIrc.Client.quit state.client, "Goodbye, cruel world."
    ExIrc.Client.stop! state.client
    :ok
  end

  defp debug(msg) do
    IO.puts IO.ANSI.yellow() <> msg <> IO.ANSI.reset()
  end
end

defmodule ExampleLoginHandler do
  @moduledoc """
  This is an example event handler that listens for login events and then
  joins the appropriate channels. We actually need this because we can't
  join channels until we've waited for login to complete. We could just
  attempt to sleep until login is complete, but that's just hacky. This
  as an event handler is a far more elegant solution.
  """
  def start_link(client, channels) do
    GenServer.start_link(__MODULE__, [client, channels])
  end

  def init([client, channels]) do
    ExIrc.Client.add_handler client, self()
    {:ok, {client, channels}}
  end

  def handle_info(:logged_in, state = {client, channels}) do
    debug "Logged in to server"
    channels |> Enum.map(&ExIrc.Client.join client, &1)
    {:noreply, state}
  end

  # Catch-all for messages you don't care about
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp debug(msg) do
    IO.puts IO.ANSI.yellow() <> msg <> IO.ANSI.reset()
  end
end
