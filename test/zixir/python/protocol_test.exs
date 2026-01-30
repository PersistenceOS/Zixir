defmodule Zixir.Python.ProtocolTest do
  use ExUnit.Case, async: true

  describe "encode_request/3 and decode_response/1" do
    test "roundtrip request and response" do
      req = Zixir.Python.Protocol.encode_request("math", "sqrt", [4.0])
      assert is_binary(req)
      assert req =~ "math"
      assert req =~ "sqrt"

      line = "{\"ok\": 2.0}\n"
      assert {:ok, 2.0} == Zixir.Python.Protocol.decode_response(line)
    end

    test "decode error response" do
      line = "{\"error\": \"module not found\"}\n"
      assert {:error, "module not found"} == Zixir.Python.Protocol.decode_response(line)
    end
  end
end
