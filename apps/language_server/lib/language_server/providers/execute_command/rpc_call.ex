defmodule ElixirLS.LanguageServer.Providers.ExecuteCommand.RpcCall do
  @moduledoc """
  Perform RPC call to remote node and return result.
  """

  # alias ElixirLS.LanguageServer.Server

  @behaviour ElixirLS.LanguageServer.Providers.ExecuteCommand

  @impl ElixirLS.LanguageServer.Providers.ExecuteCommand
  def execute([node, module, function, arguments], state)
      when is_binary(node) and is_binary(module) and is_binary(function) and is_list(arguments) do

    [node, module, function] = Enum.map([node, module, function], fn string ->
      String.replace_prefix(string, "__atom__", "") |> String.to_atom()
    end)

    arguments = recursive_string_to_atom(arguments)
    dbg([node, module, function, arguments])

    # Ensure we are in distributed mode
    node_name = "vscode-#{:rand.uniform(65536)}" |> String.to_atom()
    case :net_kernel.start(node_name, %{name_domain: :shortnames}) do
      {:ok, _pid} ->
        Node.set_cookie(:secretcookie)
        {:ok, :rpc.call(node, module, function, arguments) |> inspect()}

      {:error, {:already_started, _}} ->
        {:ok, :rpc.call(node, module, function, arguments) |> inspect()}

      {:error, reason} ->
        {:error, {:cannot_bring_up_net, reason}}
    end
  end

  def recursive_string_to_atom(list) when is_list(list) do
    Enum.map(list, &recursive_string_to_atom/1)
  end

  def recursive_string_to_atom(map) when is_map(map) do
    # map keys and values
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      Map.put(acc, recursive_string_to_atom(k), recursive_string_to_atom(v))
    end)
  end

  def recursive_string_to_atom(string) when is_binary(string) do
    if String.starts_with?(string, "__atom__") do
      String.to_atom(String.replace_prefix(string, "__atom__", ""))
    else
      string
    end
  end

  def recursive_string_to_atom(other), do: other
end
