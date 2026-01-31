defmodule Zixir.AutonomousAITest do
  @moduledoc """
  Tests for autonomous AI features:
  - Drift Detection
  - A/B Testing (Experiment)
  - Data Quality Validation
  """

  use ExUnit.Case, async: false

  describe "Drift Detection" do
    test "detect drift with KS test" do
      # Create baseline
      baseline = Enum.to_list(1..100)
      
      # Current data with drift
      current = Enum.to_list(50..150)
      
      result = Zixir.Drift.detect(current, baseline, method: :ks_test, threshold: 0.05)
      
      assert result.drift_detected == true
      assert result.score > 0.05
      assert result.method == :ks_test
      assert result.severity in [:low, :medium, :high]
    end

    test "no drift for similar distributions" do
      baseline = Enum.to_list(1..100)
      current = Enum.to_list(1..100)
      
      result = Zixir.Drift.detect(current, baseline, method: :ks_test, threshold: 0.05)
      
      assert result.drift_detected == false
      assert result.score < 0.05
    end

    test "create and retrieve baseline" do
      predictions = Enum.to_list(1..100)
      
      {:ok, baseline} = Zixir.Drift.create_baseline(predictions, name: "test_baseline")
      
      assert baseline.name == "test_baseline"
      assert baseline.sample_size == 100
      assert is_map(baseline.stats)
      
      # Retrieve
      {:ok, retrieved} = Zixir.Drift.get_baseline("test_baseline")
      assert retrieved.name == "test_baseline"
    end

    test "multivariate drift detection" do
      # Multiple features
      current_features = [
        Enum.to_list(1..100),
        Enum.to_list(50..150)
      ]
      
      baseline_features = [
        Enum.to_list(1..100),
        Enum.to_list(1..100)
      ]
      
      result = Zixir.Drift.detect_multivariate(current_features, baseline_features, 
        method: :ks_test, threshold: 0.05)
      
      assert result.drift_detected == true
      assert result.drift_count >= 1
      assert result.total_features == 2
    end

    test "PSI drift detection" do
      baseline = Enum.to_list(1..100)
      current = Enum.to_list(50..150)
      
      result = Zixir.Drift.detect(current, baseline, method: :psi, threshold: 0.1)
      
      assert is_map(result)
      assert result.method == :psi
    end
  end

  describe "A/B Testing (Experiment)" do
    test "create experiment with variants" do
      experiment = Zixir.Experiment.new("test_experiment")
      |> Zixir.Experiment.add_variant("control", fn x -> x end, traffic: 0.5)
      |> Zixir.Experiment.add_variant("treatment", fn x -> x * 2 end, traffic: 0.5)
      |> Zixir.Experiment.set_metric(:conversion_rate, min_samples: 10)
      
      assert experiment.name == "test_experiment"
      assert map_size(experiment.variants) == 2
      assert map_size(experiment.metrics) == 1
    end

    test "traffic assignment" do
      experiment = Zixir.Experiment.new("traffic_test")
      |> Zixir.Experiment.add_variant("A", fn -> "A" end, traffic: 0.5)
      |> Zixir.Experiment.add_variant("B", fn -> "B" end, traffic: 0.5)
      
      # Start experiment
      {:ok, _} = Zixir.Experiment.run(experiment, duration: 100)
      
      # Get variant assignments
      assignments = for _ <- 1..100 do
        {:ok, variant} = Zixir.Experiment.get_variant("traffic_test", "user_#{:rand.uniform(1000)}")
        variant
      end
      
      # Check roughly 50/50 split
      count_a = Enum.count(assignments, &(&1 == "A"))
      count_b = Enum.count(assignments, &(&1 == "B"))
      
      assert count_a > 30
      assert count_b > 30
    end

    test "record outcomes and calculate metrics" do
      experiment = Zixir.Experiment.new("outcome_test")
      |> Zixir.Experiment.add_variant("control", fn -> "control" end, traffic: 0.5)
      |> Zixir.Experiment.add_variant("treatment", fn -> "treatment" end, traffic: 0.5)
      |> Zixir.Experiment.set_metric(:revenue, type: :continuous)
      
      {:ok, _} = Zixir.Experiment.run(experiment, duration: 100)
      
      # Record outcomes
      for i <- 1..50 do
        Zixir.Experiment.record_outcome("outcome_test", "control", :revenue, 100.0 + i)
        Zixir.Experiment.record_outcome("outcome_test", "treatment", :revenue, 110.0 + i)
      end
      
      # Get status
      {:ok, status} = Zixir.Experiment.status("outcome_test")
      assert status.name == "outcome_test"
    end

    test "statistical significance calculation" do
      # Create two variants with different means
      variant_a = %{
        name: "A",
        metrics: %{
          revenue: %{
            count: 100,
            mean: 100.0,
            variance: 10.0
          }
        }
      }
      
      variant_b = %{
        name: "B",
        metrics: %{
          revenue: %{
            count: 100,
            mean: 110.0,
            variance: 10.0
          }
        }
      }
      
      result = Zixir.Experiment.calculate_significance(variant_a, variant_b, :revenue)
      
      assert is_map(result)
      assert result.significant == true
      assert result.p_value < 0.05
    end

    test "auto-promote configuration" do
      experiment = Zixir.Experiment.new("auto_promote_test")
      |> Zixir.Experiment.set_auto_promote(true, confidence: 0.95, min_duration: :days_1)
      
      assert experiment.config.auto_promote.enabled == true
      assert experiment.config.auto_promote.confidence == 0.95
    end
  end

  describe "Data Quality Validation" do
    test "validate data against schema" do
      schema = %{
        age: [type: :integer, range: 0..120],
        name: [type: :string]
      }
      
      data = %{age: 25, name: "John"}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: false)
      
      assert result.valid == true
      assert result.quality_score == 1.0
      assert length(result.violations) == 0
    end

    test "detect type violations" do
      schema = %{
        age: [type: :integer]
      }
      
      data = %{age: "twenty-five"}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: false)
      
      assert result.valid == false
      assert length(result.violations) == 1
      assert hd(result.violations).type == :type_error
    end

    test "auto-fix type coercion" do
      schema = %{
        age: [type: :integer]
      }
      
      data = %{age: "25"}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: true)
      
      assert result.data.age == 25
      assert length(result.fixes_applied) == 1
      assert hd(result.fixes_applied).type == :type_coerced
    end

    test "detect range violations" do
      schema = %{
        age: [type: :integer, range: 0..120]
      }
      
      data = %{age: 150}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: false)
      
      assert result.valid == false
      assert length(result.violations) == 1
    end

    test "auto-fix range violations" do
      schema = %{
        age: [type: :integer, range: 0..120]
      }
      
      data = %{age: 150}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: true)
      
      assert result.data.age == 120
      assert length(result.fixes_applied) == 1
    end

    test "detect format violations" do
      schema = %{
        email: [type: :string, format: ~r/@/]
      }
      
      data = %{email: "invalid-email"}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: false)
      
      assert result.valid == false
      assert hd(result.violations).type == :format_error
    end

    test "detect enum violations" do
      schema = %{
        category: [type: :enum, values: ["A", "B", "C"]]
      }
      
      data = %{category: "D"}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: false)
      
      assert result.valid == false
      assert hd(result.violations).type == :invalid_value
    end

    test "calculate quality score" do
      schema = %{
        field1: [type: :integer],
        field2: [type: :string],
        field3: [type: :float]
      }
      
      # 1 violation out of 3 fields
      data = %{field1: "not an int", field2: "valid", field3: 1.5}
      
      result = Zixir.Quality.validate(data, schema, auto_fix: false)
      
      assert result.quality_score == 2.0 / 3.0
    end

    test "detect outliers with z-score" do
      data = [1, 2, 3, 4, 5, 100]  # 100 is outlier
      
      result = Zixir.Quality.detect_anomalies(data, method: :z_score, threshold: 2.0)
      
      assert result.anomaly_count >= 1
      assert result.anomaly_rate > 0
    end

    test "detect outliers with IQR" do
      data = [1, 2, 3, 4, 5, 100]
      
      result = Zixir.Quality.detect_anomalies(data, method: :iqr)
      
      assert result.anomaly_count >= 1
      assert result.method == :iqr
    end

    test "profile dataset" do
      data = [
        %{age: 25, name: "John"},
        %{age: 30, name: "Jane"},
        %{age: nil, name: "Bob"}
      ]
      
      result = Zixir.Quality.profile(data)
      
      assert result.row_count == 3
      assert length(result.columns) == 2
      assert result.completeness < 1.0  # Has null
    end

    test "create and retrieve schema" do
      data = [
        %{age: 25, name: "John"},
        %{age: 30, name: "Jane"}
      ]
      
      {:ok, name, schema} = Zixir.Quality.create_schema(data, name: "test_schema")
      
      assert name == "test_schema"
      assert is_map(schema)
      assert Map.has_key?(schema, :age)
      assert Map.has_key?(schema, :name)
      
      # Retrieve
      {:ok, retrieved} = Zixir.Quality.get_schema("test_schema")
      assert retrieved == schema
    end

    test "quick check with inferred schema" do
      data = %{age: 25, name: "John", invalid: nil}
      
      result = Zixir.Quality.quick_check(data)
      
      assert is_map(result)
      assert Map.has_key?(result, :quality_score)
      assert Map.has_key?(result, :violations)
    end
  end

  describe "Integration - Autonomous AI Workflow" do
    test "full autonomous pipeline" do
      # 1. Validate data quality
      schema = %{
        age: [type: :integer, range: 0..120, null_rate: 0.1],
        income: [type: :float, outliers: :z_score_3]
      }
      
      raw_data = %{age: 25, income: 50000.0}
      
      quality_result = Zixir.Quality.validate(raw_data, schema, 
        auto_fix: true,
        alert_on_violation: true
      )
      
      assert quality_result.valid == true
      clean_data = quality_result.data
      
      # 2. Run prediction with A/B test
      experiment = Zixir.Experiment.new("model_test")
      |> Zixir.Experiment.add_variant("v1", fn -> 0.8 end, traffic: 0.5)
      |> Zixir.Experiment.add_variant("v2", fn -> 0.85 end, traffic: 0.5)
      |> Zixir.Experiment.set_metric(:accuracy, min_samples: 5)
      
      {:ok, _} = Zixir.Experiment.run(experiment, duration: 50)
      
      # Get variant and make prediction
      {:ok, variant} = Zixir.Experiment.get_variant("model_test", "user_123")
      prediction = 0.82  # Simulated
      
      Zixir.Experiment.record_outcome("model_test", variant, :accuracy, prediction)
      
      # 3. Check for drift
      baseline = Enum.to_list(1..100)
      current_predictions = [0.8, 0.82, 0.79, 0.81, 0.83]
      
      drift_result = Zixir.Drift.detect(current_predictions, baseline, 
        method: :ks_test,
        threshold: 0.05
      )
      
      # 4. Log everything
      Zixir.Observability.info("Autonomous AI pipeline completed",
        quality_score: quality_result.quality_score,
        variant: variant,
        prediction: prediction,
        drift_detected: drift_result.drift_detected
      )
      
      assert is_map(quality_result)
      assert is_map(drift_result)
    end
  end
end
