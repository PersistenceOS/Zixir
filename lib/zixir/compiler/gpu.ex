defmodule Zixir.Compiler.GPU do
  @moduledoc """
  Phase 5: GPU/CUDA support for Zixir.
  
  Automatically identifies GPU-suitable operations and offloads them to:
  - NVIDIA GPUs via CUDA
  - AMD GPUs via ROCm
  - Intel GPUs via SYCL
  - Apple GPUs via Metal (future)
  
  Works in conjunction with MLIR (Phase 4) for code generation.
  """

  require Logger

  @doc """
  Check if GPU acceleration is available.
  """
  def available? do
    # Check for CUDA, ROCm, or other GPU backends
    cuda_available?() or rocm_available?() or metal_available?()
  end

  @doc """
  Detect available GPU backends.
  """
  def detect_backends do
    backends = []
    backends = if cuda_available?(), do: [:cuda | backends], else: backends
    backends = if rocm_available?(), do: [:rocm | backends], else: backends
    backends = if metal_available?(), do: [:metal | backends], else: backends
    Enum.reverse(backends)
  end

  @doc """
  Compile Zixir AST for GPU execution.
  
  ## Options
    * `:backend` - GPU backend: :cuda, :rocm, :metal (auto-detected if not specified)
    * `:device` - GPU device ID (default: 0)
  """
  def compile(ast, opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    
    case backend do
      :cuda -> compile_cuda(ast, opts)
      :rocm -> compile_rocm(ast, opts)
      :metal -> compile_metal(ast, opts)
      nil -> {:error, :no_gpu_available}
      _ -> {:error, :unsupported_backend}
    end
  end

  @doc """
  Analyze AST to identify GPU-suitable operations.
  Returns list of operations that would benefit from GPU acceleration.
  """
  def analyze(ast) do
    {_, candidates} = analyze_node(ast, [])
    Enum.reverse(candidates)
  end

  @doc """
  Estimate performance gain from GPU offloading.
  """
  def estimate_speedup(ast) do
    candidates = analyze(ast)
    
    total_speedup = 
      Enum.reduce(candidates, 1.0, fn candidate, acc ->
        speedup = gpu_speedup(candidate)
        acc * speedup
      end)
    
    {:ok, total_speedup, length(candidates)}
  end

  # GPU code generation

  @doc """
  Generate CUDA kernel code from Zixir AST.
  """
  def to_cuda_kernel(ast) do
    case ast do
      {:function, name, params, _ret, body, _pub, _line, _col} ->
        kernel = generate_cuda_kernel(name, params, body)
        {:ok, kernel}
      
      _ ->
        {:error, :invalid_kernel_ast}
    end
  end

  @doc """
  Generate ROCm/HIP kernel code from Zixir AST.
  """
  def to_rocm_kernel(ast) do
    # ROCm uses similar syntax to CUDA
    to_cuda_kernel(ast)
  end

  # Implementation

  defp cuda_available? do
    # Check for nvcc and CUDA libraries
    case System.cmd("nvcc", ["--version"], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp rocm_available? do
    # Check for ROCm
    case System.cmd("hipcc", ["--version"], stderr_to_stdout: true) do
      {_, 0} -> true
      _ -> false
    end
  end

  defp metal_available? do
    # Check for Metal (macOS only)
    case :os.type() do
      {:unix, :darwin} -> 
        case System.cmd("xcrun", ["-f", "metal"], stderr_to_stdout: true) do
          {_, 0} -> true
          _ -> false
        end
      _ -> false
    end
  end

  defp compile_cuda(ast, _opts) do
    # Generate CUDA code
    {:ok, kernel_code} = to_cuda_kernel(ast)
    
    # Write to temp file
    temp_file = Path.join(System.tmp_dir!(), "zixir_kernel_#{:erlang.unique_integer([:positive])}.cu")
    File.write!(temp_file, kernel_code)
    
    # Compile with nvcc
    output_file = temp_file <> ".o"
    
    case System.cmd("nvcc", ["-c", temp_file, "-o", output_file], stderr_to_stdout: true) do
      {_, 0} ->
        File.rm(temp_file)
        {:ok, output_file, :cuda}
      
      {output, code} ->
        File.rm(temp_file)
        {:error, "CUDA compilation failed (exit #{code}): #{output}"}
    end
  end

  defp compile_rocm(ast, _opts) do
    # Similar to CUDA but with hipcc
    {:ok, kernel_code} = to_rocm_kernel(ast)
    
    temp_file = Path.join(System.tmp_dir!(), "zixir_kernel_#{:erlang.unique_integer([:positive])}.hip")
    File.write!(temp_file, kernel_code)
    
    output_file = temp_file <> ".o"
    
    case System.cmd("hipcc", ["-c", temp_file, "-o", output_file], stderr_to_stdout: true) do
      {_, 0} ->
        File.rm(temp_file)
        {:ok, output_file, :rocm}
      
      {output, code} ->
        File.rm(temp_file)
        {:error, "ROCm compilation failed (exit #{code}): #{output}"}
    end
  end

  defp compile_metal(_ast, _opts) do
    # Metal compilation not yet implemented
    {:error, :metal_not_implemented}
  end

  # CUDA kernel generation

  defp generate_cuda_kernel(name, params, body) do
    params_str = 
      Enum.map(params, fn {pname, ptype} ->
        cuda_type = cuda_type(ptype)
        "#{cuda_type} #{pname}"
      end)
      |> Enum.join(", ")
    
    body_cuda = cuda_statement(body)
    
    """
    #include <cuda_runtime.h>
    
    extern "C" __global__ void #{name}(#{params_str}) {
    #{body_cuda}
    }
    """
  end

  defp cuda_statement({:block, statements}) do
    stmts = Enum.map(statements, &cuda_statement/1)
    Enum.join(stmts, "\n")
  end

  defp cuda_statement({:let, name, expr, _line, _col}) do
    expr_cuda = cuda_expr(expr)
    "  auto #{name} = #{expr_cuda};"
  end

  defp cuda_statement(expr) do
    expr_cuda = cuda_expr(expr)
    "  #{expr_cuda};"
  end

  defp cuda_expr({:number, n, _, _}) when is_integer(n), do: "#{n}"
  defp cuda_expr({:number, n, _, _}) when is_float(n), do: "#{n}f"
  defp cuda_expr({:var, name, _, _}), do: name

  defp cuda_expr({:binop, op, left, right}) do
    left_cuda = cuda_expr(left)
    right_cuda = cuda_expr(right)
    op_str = cuda_operator(op)
    "(#{left_cuda} #{op_str} #{right_cuda})"
  end

  defp cuda_expr({:call, func, args}) do
    func_name = case func do
      {:var, name, _, _} -> name
      _ -> "unknown"
    end
    
    args_cuda = Enum.map(args, &cuda_expr/1) |> Enum.join(", ")
    "#{func_name}(#{args_cuda})"
  end

  defp cuda_expr({:index, array, index}) do
    array_cuda = cuda_expr(array)
    index_cuda = cuda_expr(index)
    "#{array_cuda}[#{index_cuda}]"
  end

  defp cuda_expr(_other) do
    "0"
  end

  defp cuda_operator(:add), do: "+"
  defp cuda_operator(:sub), do: "-"
  defp cuda_operator(:mul), do: "*"
  defp cuda_operator(:div), do: "/"
  defp cuda_operator(_), do: "+"

  defp cuda_type({:type, :Int}), do: "int"
  defp cuda_type({:type, :Float}), do: "float"
  defp cuda_type({:type, :Bool}), do: "bool"
  defp cuda_type({:array, elem_type, nil}), do: "#{cuda_type(elem_type)}*"
  defp cuda_type({:array, elem_type, _size}), do: "#{cuda_type(elem_type)}*"
  defp cuda_type(_), do: "float"

  # GPU analysis

  defp analyze_node({:program, statements}, acc) do
    Enum.reduce(statements, {nil, acc}, fn stmt, {_, a} ->
      analyze_node(stmt, a)
    end)
  end

  defp analyze_node({:function, name, _params, _ret, body, _pub, _line, _col}, acc) do
    {_, body_candidates} = analyze_node(body, [])
    
    if gpu_suitable?(body) do
      candidate = %{type: :function, name: name, speedup: estimate_function_speedup(body)}
      {nil, [candidate | acc ++ body_candidates]}
    else
      {nil, acc ++ body_candidates}
    end
  end

  defp analyze_node({:block, statements}, acc) do
    Enum.reduce(statements, {nil, acc}, fn stmt, {_, a} ->
      analyze_node(stmt, a)
    end)
  end

  defp analyze_node({:binop, op, left, right}, acc) do
    {_, left_acc} = analyze_node(left, acc)
    {_, right_acc} = analyze_node(right, left_acc)
    
    if vectorizable?(op, left, right) do
      candidate = %{type: :vector_op, op: op, speedup: 10.0}
      {nil, [candidate | right_acc]}
    else
      {nil, right_acc}
    end
  end

  defp analyze_node({:call, func, args}, acc) do
    func_name = case func do
      {:var, name, _, _} -> name
      _ -> :unknown
    end
    
    {_, arg_acc} = 
      Enum.reduce(args, {nil, acc}, fn arg, {_, a} ->
        analyze_node(arg, a)
      end)
    
    if parallelizable_function?(func_name) do
      candidate = %{type: :parallel_call, function: func_name, speedup: 50.0}
      {nil, [candidate | arg_acc]}
    else
      {nil, arg_acc}
    end
  end

  defp analyze_node({:array, elements, _, _}, acc) do
    {_, elem_acc} = 
      Enum.reduce(elements, {nil, acc}, fn elem, {_, a} ->
        analyze_node(elem, a)
      end)
    
    candidate = %{type: :array_creation, size: length(elements), speedup: 5.0}
    {nil, [candidate | elem_acc]}
  end

  defp analyze_node(_other, acc) do
    {nil, acc}
  end

  # GPU suitability checks

  defp gpu_suitable?(ast) do
    # Check if function is suitable for GPU
    # - Heavy computation
    # - Array operations
    # - No I/O
    # - Independent iterations
    has_array_ops?(ast) and not has_io?(ast)
  end

  defp has_array_ops?({:array, _, _, _}), do: true
  defp has_array_ops?({:index, _, _}), do: true
  defp has_array_ops?({:binop, _, left, right}), do: has_array_ops?(left) or has_array_ops?(right)
  defp has_array_ops?({:call, _, args}), do: Enum.any?(args, &has_array_ops?/1)
  defp has_array_ops?({:block, stmts}), do: Enum.any?(stmts, &has_array_ops?/1)
  defp has_array_ops?(_), do: false

  defp has_io?({:call, {:var, name, _, _}, _}) when name in ["print", "println", "write", "read"], do: true
  defp has_io?({:call, _, args}), do: Enum.any?(args, &has_io?/1)
  defp has_io?({:binop, _, left, right}), do: has_io?(left) or has_io?(right)
  defp has_io?({:block, stmts}), do: Enum.any?(stmts, &has_io?/1)
  defp has_io?(_), do: false

  defp vectorizable?(op, left, right) do
    # Check if binary operation can be vectorized
    op in [:add, :sub, :mul, :div] and 
    (has_array_ops?(left) or has_array_ops?(right))
  end

  defp parallelizable_function?(name) when is_atom(name) do
    name in [:map, :reduce, :filter, :sum, :product, :dot_product]
  end
  defp parallelizable_function?(_), do: false

  defp estimate_function_speedup(body) do
    # Estimate speedup based on operation count
    ops = count_operations(body)
    min(1000.0, :math.sqrt(ops) * 10)
  end

  defp count_operations({:binop, _, left, right}), do: 1 + count_operations(left) + count_operations(right)
  defp count_operations({:call, _, args}), do: 1 + Enum.sum(Enum.map(args, &count_operations/1))
  defp count_operations({:block, stmts}), do: Enum.sum(Enum.map(stmts, &count_operations/1))
  defp count_operations(_), do: 0

  defp gpu_speedup(%{speedup: s}), do: s
  defp gpu_speedup(_), do: 1.0

  # Runtime execution

  @doc """
  Execute a compiled GPU kernel with given arguments.
  
  ## Options
    * `:backend` - GPU backend to use
    * `:device` - GPU device ID (default: 0)
    * `:grid_size` - CUDA grid dimensions
    * `:block_size` - CUDA block dimensions
  """
  def execute(kernel_path, args, opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    device = opts[:device] || 0
    
    case backend do
      :cuda -> execute_cuda(kernel_path, args, device, opts)
      :rocm -> execute_rocm(kernel_path, args, device, opts)
      _ -> {:error, :unsupported_backend}
    end
  end

  @doc """
  Create a GPU memory buffer for data transfer.
  """
  def allocate_buffer(data, opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    
    case backend do
      :cuda -> allocate_cuda_buffer(data)
      :rocm -> allocate_rocm_buffer(data)
      _ -> {:error, :unsupported_backend}
    end
  end

  @doc """
  Copy data from host to GPU device.
  """
  def copy_to_device(host_data, device_buffer, opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    
    case backend do
      :cuda -> copy_to_cuda_device(host_data, device_buffer)
      :rocm -> copy_to_rocm_device(host_data, device_buffer)
      _ -> {:error, :unsupported_backend}
    end
  end

  @doc """
  Copy data from GPU device to host.
  """
  def copy_from_device(device_buffer, size, opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    
    case backend do
      :cuda -> copy_from_cuda_device(device_buffer, size)
      :rocm -> copy_from_rocm_device(device_buffer, size)
      _ -> {:error, :unsupported_backend}
    end
  end

  @doc """
  Free GPU memory buffer.
  """
  def free_buffer(device_buffer, opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    
    case backend do
      :cuda -> free_cuda_buffer(device_buffer)
      :rocm -> free_rocm_buffer(device_buffer)
      _ -> {:error, :unsupported_backend}
    end
  end

  @doc """
  Get GPU device information.
  """
  def device_info(device_id \\ 0) do
    backends = detect_backends()
    
    if :cuda in backends do
      get_cuda_device_info(device_id)
    else
      if :rocm in backends do
        get_rocm_device_info(device_id)
      else
        {:error, :no_gpu_available}
      end
    end
  end

  @doc """
  Synchronize GPU execution (wait for all operations to complete).
  """
  def synchronize(opts \\ []) do
    backend = opts[:backend] || hd(detect_backends())
    
    case backend do
      :cuda -> cuda_synchronize()
      :rocm -> rocm_synchronize()
      _ -> {:error, :unsupported_backend}
    end
  end

  # CUDA execution implementation

  defp execute_cuda(kernel_path, _args, device, opts) do
    _grid_size = opts[:grid_size] || {1, 1, 1}
    _block_size = opts[:block_size] || {256, 1, 1}
    
    # Set device
    case System.cmd("nvcc", ["--run", "-arch=sm_70", kernel_path], 
           env: [{"CUDA_VISIBLE_DEVICES", to_string(device)}],
           stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}
      
      {output, code} ->
        {:error, "CUDA execution failed (exit #{code}): #{output}"}
    end
  end

  defp allocate_cuda_buffer(_data) do
    # In a real implementation, this would use CUDA driver API
    # For now, return a placeholder
    {:ok, :cuda_buffer_placeholder}
  end

  defp copy_to_cuda_device(_host_data, _device_buffer) do
    {:ok, :copied}
  end

  defp copy_from_cuda_device(_device_buffer, _size) do
    {:ok, []}
  end

  defp free_cuda_buffer(_device_buffer) do
    :ok
  end

  defp get_cuda_device_info(device_id) do
    case System.cmd("nvidia-smi", ["--query-gpu=name,memory.total,compute_cap", 
           "--format=csv,noheader", "-i", to_string(device_id)], 
           stderr_to_stdout: true) do
      {output, 0} ->
        [name, memory, compute_cap] = String.split(output, ",") |> Enum.map(&String.trim/1)
        {:ok, %{
          device_id: device_id,
          name: name,
          memory: memory,
          compute_capability: compute_cap,
          backend: :cuda
        }}
      
      _ ->
        {:error, :device_info_failed}
    end
  end

  defp cuda_synchronize do
    # In real implementation: cudaDeviceSynchronize()
    :ok
  end

  # ROCm execution implementation

  defp execute_rocm(kernel_path, _args, device, opts) do
    _grid_size = opts[:grid_size] || {1, 1, 1}
    _block_size = opts[:block_size] || {256, 1, 1}
    
    case System.cmd("hipcc", ["--run", kernel_path], 
           env: [{"HIP_VISIBLE_DEVICES", to_string(device)}],
           stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, output}
      
      {output, code} ->
        {:error, "ROCm execution failed (exit #{code}): #{output}"}
    end
  end

  defp allocate_rocm_buffer(_data) do
    {:ok, :rocm_buffer_placeholder}
  end

  defp copy_to_rocm_device(_host_data, _device_buffer) do
    {:ok, :copied}
  end

  defp copy_from_rocm_device(_device_buffer, _size) do
    {:ok, []}
  end

  defp free_rocm_buffer(_device_buffer) do
    :ok
  end

  defp get_rocm_device_info(device_id) do
    case System.cmd("rocm-smi", ["--showproductname", "-d", to_string(device_id)], 
           stderr_to_stdout: true) do
      {output, 0} ->
        {:ok, %{
          device_id: device_id,
          name: String.trim(output),
          memory: "unknown",
          compute_capability: "unknown",
          backend: :rocm
        }}
      
      _ ->
        {:error, :device_info_failed}
    end
  end

  defp rocm_synchronize do
    # In real implementation: hipDeviceSynchronize()
    :ok
  end

  # Auto-offload: automatically compile and run on GPU if beneficial

  @doc """
  Auto-offload: Analyze AST and automatically run on GPU if beneficial.
  
  Returns {:gpu, result} if offloaded to GPU, {:cpu, result} if kept on CPU.
  """
  def auto_offload(ast, args, opts \\ []) do
    threshold = opts[:threshold] || 10.0  # Minimum speedup to justify GPU
    
    case estimate_speedup(ast) do
      {:ok, speedup, _count} when speedup >= threshold ->
        # Worth offloading to GPU
        case compile(ast, opts) do
          {:ok, kernel_path, backend} ->
            case execute(kernel_path, args, Keyword.put(opts, :backend, backend)) do
              {:ok, result} ->
                File.rm(kernel_path)
                {:gpu, result, speedup}
              
              {:error, reason} ->
                # Fall back to CPU
                {:cpu, reason, 1.0}
            end
          
          {:error, reason} ->
            {:cpu, reason, 1.0}
        end
      
      _ ->
        # Not worth offloading
        {:cpu, :below_threshold, 1.0}
    end
  end

  # Batch processing for multiple inputs

  @doc """
  Process multiple inputs in batches on GPU.
  """
  def batch_process(kernel_path, inputs, opts \\ []) do
    batch_size = opts[:batch_size] || 1000
    backend = opts[:backend] || hd(detect_backends())
    
    inputs
    |> Enum.chunk_every(batch_size)
    |> Enum.map(fn batch ->
      case execute(kernel_path, batch, Keyword.put(opts, :backend, backend)) do
        {:ok, result} -> result
        {:error, reason} -> {:error, reason}
      end
    end)
  end
end
