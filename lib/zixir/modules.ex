defmodule Zixir.Modules do
  @moduledoc """
  Module system for Zixir: import resolution, caching, and dependency management.
  
  Supports:
  - Local imports: `import "./local_module"`
  - Standard library: `import "std/math"`
  - Package imports: `import "package_name/module"`
  - Circular import detection
  - Module caching for performance
  """

  use GenServer

  require Logger

  @stdlib_modules %{
    "std/math" => :math,
    "std/string" => :string,
    "std/list" => :list,
    "std/io" => :io,
    "std/json" => :json,
    "std/regex" => :regex,
    "std/http" => :http,
    "std/file" => :file
  }

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Resolve and load a module by path.
  Returns {:ok, module_ast} or {:error, reason}
  """
  def resolve(path, from_file \\ nil) do
    GenServer.call(__MODULE__, {:resolve, path, from_file}, 30_000)
  end

  @doc """
  Import a module and merge its public exports into the current scope.
  """
  def import_module(path, from_file \\ nil) do
    case resolve(path, from_file) do
      {:ok, module} -> {:ok, extract_exports(module)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Check if a module is cached.
  """
  def cached?(path) do
    GenServer.call(__MODULE__, {:cached?, path})
  end

  @doc """
  Clear the module cache.
  """
  def clear_cache do
    GenServer.cast(__MODULE__, :clear_cache)
  end

  @doc """
  Get cache statistics.
  """
  def cache_stats do
    GenServer.call(__MODULE__, :cache_stats)
  end

  @doc """
  Get the search paths for module resolution.
  """
  def search_paths do
    default_paths = [
      Path.join(File.cwd!(), "lib"),
      Path.join(File.cwd!(), "modules"),
      Path.join(File.cwd!(), "vendor")
    ]
    
    Application.get_env(:zixir, :module_paths, default_paths)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    state = %{
      cache: %{},           # path => {ast, mtime}
      loading: MapSet.new(), # paths currently being loaded (for circular detection)
      import_stack: [],     # stack for error reporting
      stats: %{
        hits: 0,
        misses: 0,
        errors: 0
      }
    }
    
    {:ok, state}
  end

  @impl true
  def handle_call({:resolve, path, from_file}, _from, state) do
    case do_resolve(path, from_file, state) do
      {:ok, ast, new_state} ->
        {:reply, {:ok, ast}, new_state}
      
      {:error, reason, new_state} ->
        {:reply, {:error, reason}, new_state}
    end
  end

  def handle_call({:cached?, path}, _from, state) do
    cached = Map.has_key?(state.cache, path)
    {:reply, cached, state}
  end

  def handle_call(:cache_stats, _from, state) do
    stats = Map.put(state.stats, :size, map_size(state.cache))
    {:reply, stats, state}
  end

  @impl true
  def handle_cast(:clear_cache, state) do
    {:noreply, %{state | cache: %{}}}
  end

  # Private Functions

  defp do_resolve(path, from_file, state) do
    # Check for circular imports
    if MapSet.member?(state.loading, path) do
      error = "Circular import detected: #{path}"
      Logger.error(error)
      {:error, error, update_stats(state, :errors)}
    else
      # Check cache first
      case Map.get(state.cache, path) do
        {ast, mtime} ->
          # Verify file hasn't changed
          case get_file_mtime(path) do
            {:ok, current_mtime} when current_mtime == mtime ->
              # Cache hit
              {:ok, ast, update_stats(state, :hits)}
            
            _ ->
              # Cache stale, reload
              load_module(path, from_file, state)
          end
        
        nil ->
          # Cache miss
          load_module(path, from_file, update_stats(state, :misses))
      end
    end
  end

  defp load_module(path, from_file, state) do
    # Mark as loading
    state = %{state | loading: MapSet.put(state.loading, path)}
    
    result = case resolve_path(path, from_file) do
      {:ok, full_path} ->
        case File.read(full_path) do
          {:ok, source} ->
            case parse_and_compile(source, full_path) do
              {:ok, ast} ->
                # Cache the result
                {:ok, mtime} = get_file_mtime(full_path)
                cache = Map.put(state.cache, path, {ast, mtime})
                {:ok, ast, %{state | cache: cache}}
              
              {:error, reason} ->
                {:error, "Failed to compile #{path}: #{reason}", state}
            end
          
          {:error, reason} ->
            {:error, "Cannot read #{path}: #{reason}", state}
        end
      
      {:error, reason} ->
        {:error, "Cannot resolve #{path}: #{reason}", state}
    end
    
    # Unmark as loading
    {status, ast_or_error, final_state} = result
    final_state = %{final_state | loading: MapSet.delete(final_state.loading, path)}
    
    {status, ast_or_error, final_state}
  end

  defp resolve_path(path, from_file) do
    cond do
      # Absolute path
      Path.type(path) == :absolute ->
        find_file(path)
      
      # Relative path
      String.starts_with?(path, "./") or String.starts_with?(path, "../") ->
        base = if from_file, do: Path.dirname(from_file), else: File.cwd!()
        find_file(Path.join(base, path))
      
      # Standard library
      String.starts_with?(path, "std/") ->
        resolve_stdlib(path)
      
      # Package/module search
      true ->
        search_in_paths(path)
    end
  end

  defp find_file(path) do
    extensions = [".zr", ".zixir", ""]
    
    found = Enum.find_value(extensions, fn ext ->
      full = path <> ext
      if File.exists?(full), do: full, else: nil
    end)
    
    if found do
      {:ok, found}
    else
      {:error, "File not found: #{path}"}
    end
  end

  defp resolve_stdlib(path) do
    case Map.get(@stdlib_modules, path) do
      nil ->
        # Generate built-in module AST
        {:ok, generate_stdlib_module(path)}
      
      _module_name ->
        {:ok, generate_stdlib_module(path)}
    end
  end

  defp generate_stdlib_module("std/math") do
    {:program, [
      {:function, "sin", [{"x", {:type, :Float}}], {:type, :Float}, 
       {:call, {:field, {:var, "python", 1, 1}, "math"}, [
         {:call, {:var, "sin", 1, 1}, [{:var, "x", 1, 1}]}
       ]}, true, 1, 1},
      {:function, "cos", [{"x", {:type, :Float}}], {:type, :Float}, 
       {:call, {:field, {:var, "python", 1, 1}, "math"}, [
         {:call, {:var, "cos", 1, 1}, [{:var, "x", 1, 1}]}
       ]}, true, 1, 1},
      {:function, "sqrt", [{"x", {:type, :Float}}], {:type, :Float}, 
       {:call, {:field, {:var, "python", 1, 1}, "math"}, [
         {:call, {:var, "sqrt", 1, 1}, [{:var, "x", 1, 1}]}
       ]}, true, 1, 1},
      {:function, "pow", [{"x", {:type, :Float}}, {"y", {:type, :Float}}], {:type, :Float}, 
       {:call, {:field, {:var, "python", 1, 1}, "math"}, [
         {:call, {:var, "pow", 1, 1}, [{:var, "x", 1, 1}, {:var, "y", 1, 1}]}
       ]}, true, 1, 1}
    ]}
  end

  defp generate_stdlib_module("std/list") do
    {:program, [
      {:function, "map", [{"list", {:type, :Array, {:type, :Float}}}, {"f", {:type, :Function}}], 
       {:type, :Array, {:type, :Float}}, 
       {:call, {:field, {:var, "engine", 1, 1}, "map_mul"}, [{:var, "list", 1, 1}]}, 
       true, 1, 1},
      {:function, "filter", [{"list", {:type, :Array, {:type, :Float}}}, {"pred", {:type, :Function}}], 
       {:type, :Array, {:type, :Float}}, 
       {:call, {:field, {:var, "engine", 1, 1}, "filter_gt"}, [{:var, "list", 1, 1}]}, 
       true, 1, 1},
      {:function, "sum", [{"list", {:type, :Array, {:type, :Float}}}], {:type, :Float}, 
       {:call, {:field, {:var, "engine", 1, 1}, "list_sum"}, [{:var, "list", 1, 1}]}, 
       true, 1, 1},
      {:function, "sort", [{"list", {:type, :Array, {:type, :Float}}}], {:type, :Array, {:type, :Float}}, 
       {:call, {:field, {:var, "engine", 1, 1}, "sort_asc"}, [{:var, "list", 1, 1}]}, 
       true, 1, 1}
    ]}
  end

  defp generate_stdlib_module(_path) do
    # Default empty module
    {:program, []}
  end

  defp search_in_paths(path) do
    paths = search_paths()
    
    found = Enum.find_value(paths, fn dir ->
      case find_file(Path.join(dir, path)) do
        {:ok, full} -> full
        _ -> nil
      end
    end)
    
    if found do
      {:ok, found}
    else
      {:error, "Module not found in search paths: #{path}"}
    end
  end

  defp parse_and_compile(source, path) do
    case Zixir.Compiler.Parser.parse(source) do
      {:ok, ast} ->
        # Process imports within the module
        {:ok, processed_ast} = process_imports(ast, path)
        {:ok, processed_ast}
      
      {:error, error} ->
        {:error, "Parse error in #{path}: #{error.message}"}
    end
  end

  defp process_imports({:program, statements}, path) do
    {imports, other} = Enum.split_with(statements, fn
      {:import, _, _, _} -> true
      _ -> false
    end)
    
    # Resolve all imports
    resolved_imports = Enum.reduce(imports, [], fn {:import, import_path, line, col}, acc ->
      case resolve(import_path, path) do
        {:ok, module} -> [{import_path, module} | acc]
        {:error, reason} -> 
          Logger.warning("Failed to import #{import_path}: #{reason}")
          acc
      end
    end)
    
    # Create new program with resolved imports
    {:ok, {:program, other, imports: resolved_imports}}
  end

  defp get_file_mtime(path) do
    case File.stat(path) do
      {:ok, %{mtime: mtime}} -> {:ok, mtime}
      {:error, reason} -> {:error, reason}
    end
  end

  defp update_stats(state, key) do
    %{state | stats: Map.update!(state.stats, key, &(&1 + 1))}
  end

  defp extract_exports({:program, statements, _opts}) do
    Enum.filter(statements, fn
      {:function, _, _, _, _, is_pub, _, _} -> is_pub
      {:type_def, _, _, _, _} -> true
      _ -> false
    end)
  end

  defp extract_exports({:program, statements}) do
    Enum.filter(statements, fn
      {:function, _, _, _, _, is_pub, _, _} -> is_pub
      {:type_def, _, _, _, _} -> true
      _ -> false
    end)
  end
end
