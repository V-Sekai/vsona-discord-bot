
defmodule VSona do
  use Application

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    VSona.Supervisor.start_link(name: VSona.Supervisor)
  end
end

# Bot Permissions integer: 268443712
defmodule VSona.Supervisor do
  use Supervisor
  require Logger

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.error("INIT IS HAPPENING")
    children = [VSona.Module]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule VSona.Module do
  use Nostrum.Consumer
  require Logger

  alias Nostrum.Api

  def start_link do
    Consumer.start_link(__MODULE__);
  end

  def handle_event({:MESSAGE_REACTION_ADD, msg, _ws_state}) do
    Logger.debug("msg_delete");
    Logger.debug(msg);
    DEFAULT_CHANNEL_ID = 12345 # FIXME
    # Api.create_message!(DEFAULT_CHANNEL_ID, %{:content=> "Test", :nonce=> nonce});
    if msg.channel_id == DEFAULT_CHANNEL_ID do
      # Causes infinite recursion! Api.create_reaction!(....)
      Api.delete_user_reaction!(msg.channel_id, msg.message_id, "\xf0\x9f\x91\x8d", msg.user_id) # Thumbs up
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    Logger.debug("msg_create");
    Logger.debug(msg.content);
    case msg.content do
      "!sleep" ->
        Api.create_message(msg.channel_id, "Going to sleep...")
        # This won't stop other events from being handled.
        Process.sleep(3000)

      "!ping" ->
        Api.create_message(msg.channel_id, "pong!")

      "!raise" ->
        # This won't crash the entire Consumer.
        raise "No problems here!"

      _ ->
        :ignore
    end
  end

  def handle_event({event_name, _, _}) do
    Logger.debug(fn -> "VSona would handle #{event_name} here" end)
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  #def handle_event(_event) do
  #  :noop
  #end
end
