# Using Zixir Autonomous AI Features with AI Programs

## Overview

Zixir's autonomous AI features (Drift Detection, A/B Testing, Data Quality) integrate seamlessly with your AI/ML workflows to create self-monitoring, self-improving, and self-healing AI systems.

## 1. Real-Time Model Serving with Quality Checks

### Scenario: Fraud Detection API

```elixir
defmodule FraudDetectionAPI do
  @moduledoc """
  Real-time fraud detection with automatic quality checks and drift monitoring.
  """

  # Define validation schema for incoming transactions
  def transaction_schema do
    %{
      transaction_id: [type: :string, format: ~r/^[A-Z0-9]{10}$/],
      amount: [type: :float, range: 0.01..999999.99, outliers: :z_score_3],
      merchant_id: [type: :string],
      user_id: [type: :string],
      timestamp: [type: :string],
      country: [type: :enum, values: ["US", "CA", "UK", "DE", "FR"]],
      payment_method: [type: :enum, values: ["credit", "debit", "paypal"]],
      device_fingerprint: [type: :string]
    }
  end

  @doc """
  Main prediction endpoint with full autonomous checks.
  """
  def predict(transaction_data, user_id) do
    workflow fraud_check:
      # Step 1: Validate data quality
      checkpoint "validated"
      let quality_result = Zixir.Quality.validate(
        transaction_data, 
        transaction_schema(),
        auto_fix: true,
        alert_on_violation: true
      )
      
      if not quality_result.valid:
        Zixir.Observability.alert("Fraud API: Invalid transaction data",
          quality_score: quality_result.quality_score,
          violations: quality_result.violations
        )
        return {:error, :invalid_data, quality_result.violations}
      end
      
      let clean_data = quality_result.data
      
      # Step 2: Route to A/B test variant (model version)
      checkpoint "routed"
      let variant = Zixir.Experiment.get_variant("fraud_model_v2", user_id)
      
      # Step 3: Make prediction with resource limits
      checkpoint "predicted"
      let prediction = Zixir.Sandbox.with_timeout(5000, fn ->
        variant.model.predict(clean_data)
      end)
      
      case prediction do
        {:ok, result} ->
          # Step 4: Record outcome for A/B test analysis
          Zixir.Experiment.record_outcome(
            "fraud_model_v2",
            variant.name,
            :precision,
            result.confidence
          )
          
          # Step 5: Check for model drift
          checkpoint "drift_checked"
          let baseline = Zixir.Cache.get("fraud_baseline")
          let drift = Zixir.Drift.detect(
            [result.confidence],
            baseline,
            method: :ks_test,
            threshold: 0.05
          )
          
          if drift.drift_detected:
            Zixir.Observability.alert("Fraud model drift detected!",
              score: drift.score,
              severity: drift.severity
            )
            # Trigger automatic retraining
            Zixir.Workflow.trigger("retrain_fraud_model")
          end
          
          # Step 6: Log everything
          Zixir.Observability.info("Fraud prediction completed",
            transaction_id: clean_data.transaction_id,
            variant: variant.name,
            is_fraud: result.is_fraud,
            confidence: result.confidence,
            quality_score: quality_result.quality_score,
            drift_score: drift.score
          )
          
          {:ok, result}
        
        {:error, reason} ->
          Zixir.Observability.error("Fraud prediction failed",
            reason: reason,
            transaction_id: clean_data.transaction_id
          )
          {:error, :prediction_failed}
      end
    end
    
    Zixir.Workflow.execute(fraud_check, checkpoint: true)
  end
end
```

**What this does:**
- ✅ Validates every transaction for data quality
- ✅ A/B tests different fraud model versions
- ✅ Detects when model performance degrades
- ✅ Auto-triggers retraining on drift
- ✅ Full observability and logging
- ✅ Resource-limited execution (5 second timeout)

---

## 2. Training Pipeline with A/B Testing

### Scenario: Recommendation Engine Training

```elixir
defmodule RecommendationTraining do
  @moduledoc """
  Automated training pipeline with built-in A/B testing.
  """

  @doc """
  Full training workflow with automatic model selection.
  """
  def train_and_deploy do
    workflow training_pipeline:
      timeout: 3600_000  # 1 hour max
      retries: 2
      
      # Step 1: Validate training data
      checkpoint "data_validated"
      let raw_data = load_training_data()
      
      let data_quality = Zixir.Quality.validate(raw_data, %{
        user_id: [type: :string],
        item_id: [type: :string],
        rating: [type: :float, range: 1.0..5.0],
        timestamp: [type: :string]
      }, auto_fix: true)
      
      if data_quality.quality_score < 0.9:
        Zixir.Observability.alert("Training data quality low",
          score: data_quality.quality_score
        )
        return {:error, :poor_data_quality}
      end
      
      let clean_data = data_quality.data
      
      # Step 2: Train multiple model variants in parallel
      checkpoint "models_trained"
      let model_tasks = [
        Zixir.Stream.async(fn -> train_collaborative_filtering(clean_data) end),
        Zixir.Stream.async(fn -> train_neural_network(clean_data) end),
        Zixir.Stream.async(fn -> train_matrix_factorization(clean_data) end)
      ]
      
      let models = Zixir.Stream.await_many(model_tasks, 3000_000)
      
      # Step 3: Create A/B test experiment
      checkpoint "experiment_created"
      let experiment = Zixir.Experiment.new("recommendation_models")
      |> Zixir.Experiment.add_variant(
        "collaborative",
        Enum.at(models, 0),
        traffic: 0.33
      )
      |> Zixir.Experiment.add_variant(
        "neural",
        Enum.at(models, 1),
        traffic: 0.33
      )
      |> Zixir.Experiment.add_variant(
        "matrix_factorization",
        Enum.at(models, 2),
        traffic: 0.34
      )
      |> Zixir.Experiment.set_metric(:click_through_rate, min_samples: 5000)
      |> Zixir.Experiment.set_metric(:conversion_rate, min_samples: 5000)
      |> Zixir.Experiment.set_auto_promote(
        true,
        confidence: 0.95,
        min_duration: :days_7,
        min_improvement: 0.05
      )
      
      # Step 4: Deploy all variants for A/B testing
      checkpoint "deployed"
      deploy_models_for_ab_test(experiment)
      
      # Step 5: Start monitoring
      Zixir.Observability.info("Training pipeline completed",
        models_trained: 3,
        experiment: "recommendation_models",
        data_quality: data_quality.quality_score
      )
      
      {:ok, experiment}
    end
    
    Zixir.Workflow.execute(training_pipeline, checkpoint: true)
  end
  
  defp train_collaborative_filtering(data) do
    Zixir.Sandbox.with_timeout(1800_000, fn ->
      python "sklearn" "train_collaborative_filtering" (data)
    end)
  end
  
  defp train_neural_network(data) do
    Zixir.Sandbox.with_timeout(1800_000, [memory_limit: "4GB"], fn ->
      python "pytorch" "train_recommendation_nn" (data)
    end)
  end
  
  defp train_matrix_factorization(data) do
    Zixir.Sandbox.with_timeout(1800_000, fn ->
      python "surprise" "train_svd" (data)
    end)
  end
end
```

**What this does:**
- ✅ Validates training data quality
- ✅ Trains 3 model variants in parallel
- ✅ Automatically A/B tests them in production
- ✅ Auto-promotes winner after 7 days if significant
- ✅ Monitors click-through and conversion rates
- ✅ Full checkpointing for fault tolerance

---

## 3. Batch Processing with Drift Detection

### Scenario: Nightly Credit Scoring Batch

```elixir
defmodule CreditScoringBatch do
  @moduledoc """
  Nightly batch processing with drift monitoring.
  """

  @doc """
  Process all pending credit applications with quality checks.
  """
  def process_nightly_batch do
    workflow batch_process:
      timeout: 7200_000  # 2 hours max
      
      # Step 1: Load and validate batch data
      checkpoint "batch_loaded"
      let applications = load_pending_applications()
      
      # Detect anomalies in batch
      let anomaly_check = Zixir.Quality.detect_anomalies(
        Enum.map(applications, & &1.income),
        method: :z_score,
        threshold: 3.0
      )
      
      if anomaly_check.anomaly_rate > 0.1:
        Zixir.Observability.alert("High anomaly rate in credit batch",
          rate: anomaly_check.anomaly_rate
        )
      end
      
      # Step 2: Process in parallel batches
      checkpoint "processing"
      let results = Zixir.Stream.from_enum(applications)
      |> Zixir.Stream.batch(100)  # Process 100 at a time
      |> Zixir.Stream.parallel(4)  # 4 concurrent batches
      |> Zixir.Stream.map(fn batch ->
        process_batch(batch)
      end)
      |> Zixir.Stream.to_list()
      |> then(fn batches -> List.flatten(batches) end)
      
      # Step 3: Check for prediction drift
      checkpoint "drift_analysis"
      let predictions = Enum.map(results, & &1.score)
      let baseline = Zixir.Drift.get_baseline("credit_baseline")
      
      let drift = Zixir.Drift.detect(predictions, baseline.data,
        method: :psi,
        threshold: 0.1
      )
      
      if drift.drift_detected:
        Zixir.Observability.alert("Credit model drift in batch",
          score: drift.score,
          severity: drift.severity
        )
        
        # Create new baseline if drift is severe
        if drift.severity == :high:
          Zixir.Drift.create_baseline(predictions, name: "credit_baseline_v2")
          Zixir.Workflow.trigger("retrain_credit_model")
        end
      end
      
      # Step 4: Save results
      checkpoint "saved"
      save_results(results)
      
      # Step 5: Report metrics
      Zixir.Observability.info("Credit batch completed",
        applications_processed: length(applications),
        anomaly_rate: anomaly_check.anomaly_rate,
        drift_detected: drift.drift_detected,
        avg_score: Enum.sum(predictions) / length(predictions)
      )
      
      {:ok, length(results)}
    end
    
    Zixir.Workflow.execute(batch_process, checkpoint: true)
  end
  
  defp process_batch(batch) do
    Zixir.Sandbox.with_timeout(300_000, fn ->
      Enum.map(batch, fn app ->
        # Validate individual application
        validation = Zixir.Quality.validate(app, %{
          income: [type: :float, range: 0..1000000],
          credit_history: [type: :integer, range: 0..50],
          debt_ratio: [type: :float, range: 0.0..1.0]
        }, auto_fix: true)
        
        if validation.valid:
          score = predict_credit_score(validation.data)
          %{application_id: app.id, score: score, approved: score > 650}
        else
          %{application_id: app.id, score: 0, approved: false, 
            error: :validation_failed}
        end
      end)
    end)
  end
  
  defp predict_credit_score(data) do
    python "credit_model" "predict" (data)
  end
end
```

**What this does:**
- ✅ Processes thousands of applications nightly
- ✅ Detects anomalous data in batch
- ✅ Parallel processing for speed
- ✅ Monitors for model drift across batch
- ✅ Auto-creates new baseline if needed
- ✅ Full checkpointing for fault tolerance

---

## 4. Streaming AI with Real-Time Quality

### Scenario: Real-Time Sentiment Analysis

```elixir
defmodule SentimentStream do
  @moduledoc """
  Real-time sentiment analysis of customer feedback.
  """

  @doc """
  Start streaming sentiment analysis with quality monitoring.
  """
  def start_stream do
    # Define schema for incoming messages
    schema = %{
      message_id: [type: :string],
      text: [type: :string, format: ~r/.{10,500}/],  # 10-500 chars
      source: [type: :enum, values: ["twitter", "email", "chat", "review"]],
      timestamp: [type: :string],
      customer_id: [type: :string]
    }
    
    # Start monitoring stream
    Zixir.Quality.monitor_stream(self(), schema,
      alert_on_violation: true,
      max_null_rate: 0.05
    )
    
    # Process stream
    stream_messages()
    |> Zixir.Stream.map(fn msg ->
      analyze_sentiment(msg, schema)
    end)
    |> Zixir.Stream.each(fn result ->
      # Store result
      store_sentiment(result)
      
      # Alert on negative sentiment
      if result.sentiment == :negative and result.confidence > 0.8:
        Zixir.Observability.alert("High confidence negative sentiment",
          message_id: result.message_id,
          confidence: result.confidence
        )
      end
    end)
    |> Zixir.Stream.run()
  end
  
  defp analyze_sentiment(message, schema) do
    # Validate message
    validation = Zixir.Quality.validate(message, schema, auto_fix: true)
    
    if not validation.valid:
      Zixir.Observability.warning("Invalid message in sentiment stream",
        message_id: message.message_id,
        quality_score: validation.quality_score
      )
      return %{error: :invalid_message}
    end
    
    # Check for drift in message characteristics
    check_text_drift(validation.data.text)
    
    # Analyze sentiment
    result = Zixir.Sandbox.with_timeout(2000, fn ->
      python "transformers" "analyze_sentiment" (validation.data.text)
    end)
    
    case result do
      {:ok, sentiment} ->
        %{
          message_id: message.message_id,
          sentiment: sentiment.label,
          confidence: sentiment.confidence,
          text: validation.data.text,
          source: message.source
        }
      
      {:error, _} ->
        %{message_id: message.message_id, sentiment: :unknown, confidence: 0}
    end
  end
  
  defp check_text_drift(text) do
    # Monitor text characteristics for drift
    # (e.g., average length, vocabulary changes)
    current_features = [
      String.length(text),
      count_words(text)
    ]
    
    # Compare to baseline
    baseline = Zixir.Cache.get("text_baseline")
    
    if baseline do
      drift = Zixir.Drift.detect([current_features], baseline.data,
        method: :wasserstein,
        threshold: 0.1
      )
      
      if drift.drift_detected:
        Zixir.Observability.alert("Text characteristics drift",
          score: drift.score
        )
      end
    end
  end
  
  defp count_words(text) do
    text |> String.split() |> length()
  end
end
```

**What this does:**
- ✅ Real-time sentiment analysis
- ✅ Validates every message
- ✅ Monitors text characteristics for drift
- ✅ Alerts on high-confidence negative sentiment
- ✅ Auto-fixes minor validation issues

---

## 5. Complete Autonomous AI System

### Putting It All Together

```elixir
defmodule AutonomousAI do
  @moduledoc """
  Fully autonomous AI system that manages itself.
  """

  @doc """
  Initialize the autonomous AI system.
  """
  def init do
    # 1. Set up drift baselines
    Zixir.Drift.create_baseline([0.8, 0.82, 0.79, 0.81], name: "model_baseline")
    
    # 2. Create A/B test experiment
    experiment = Zixir.Experiment.new("production_model")
    |> Zixir.Experiment.add_variant("v1", load_model("v1"), traffic: 0.9)
    |> Zixir.Experiment.add_variant("v2_candidate", load_model("v2"), traffic: 0.1)
    |> Zixir.Experiment.set_metric(:accuracy, min_samples: 10000)
    |> Zixir.Experiment.set_auto_promote(true, confidence: 0.95)
    
    Zixir.Experiment.run(experiment, duration: :days_14)
    
    # 3. Start monitoring loops
    spawn(fn -> drift_monitor_loop() end)
    spawn(fn -> quality_monitor_loop() end)
    
    :ok
  end
  
  @doc """
  Main prediction endpoint - fully autonomous.
  """
  def predict(input, user_id) do
    workflow autonomous_prediction:
      # Quality check
      let quality = Zixir.Quality.quick_check(input)
      
      if quality.quality_score < 0.8:
        # Try to auto-fix
        let fixed = Zixir.Quality.validate(input, inferred_schema(), auto_fix: true)
        input = fixed.data
      end
      
      # Route to A/B test variant
      let variant = Zixir.Experiment.get_variant("production_model", user_id)
      
      # Make prediction
      let result = variant.model.predict(input)
      
      # Record for analysis
      Zixir.Experiment.record_outcome("production_model", variant.name, 
        :accuracy, result.confidence)
      
      # Check drift
      check_prediction_drift(result)
      
      result
    end
    
    Zixir.Workflow.execute(autonomous_prediction)
  end
  
  # Background monitoring
  defp drift_monitor_loop do
    Process.sleep(3600_000)  # Check every hour
    
    # Get recent predictions
    recent = get_recent_predictions(1000)
    baseline = Zixir.Drift.get_baseline("model_baseline")
    
    drift = Zixir.Drift.detect(recent, baseline.data, method: :ks_test)
    
    if drift.drift_detected:
      handle_drift(drift)
    end
    
    drift_monitor_loop()
  end
  
  defp quality_monitor_loop do
    Process.sleep(1800_000)  # Check every 30 minutes
    
    # Check data quality metrics
    stats = Zixir.Quality.stats()
    
    if stats.violation_rate > 0.1:
      Zixir.Observability.alert("High data violation rate",
        rate: stats.violation_rate
      )
    end
    
    quality_monitor_loop()
  end
  
  defp handle_drift(drift) do
    cond do
      drift.severity == :high ->
        # Immediate retraining
        Zixir.Observability.alert("Critical drift! Auto-retraining...",
          score: drift.score
        )
        Zixir.Workflow.trigger("emergency_retrain")
        
      drift.severity == :medium ->
        # Schedule retraining
        Zixir.Observability.warning("Moderate drift detected",
          score: drift.score
        )
        Zixir.Workflow.trigger("scheduled_retrain")
        
      true ->
        # Just log
        Zixir.Observability.info("Minor drift detected",
          score: drift.score
        )
    end
  end
end
```

---

## Key Integration Points

### **1. Data Quality → AI Input**
```elixir
# Always validate before prediction
validation = Zixir.Quality.validate(raw_input, schema, auto_fix: true)
if validation.valid:
  model.predict(validation.data)
```

### **2. A/B Testing → Model Selection**
```elixir
# Route to different model versions
variant = Zixir.Experiment.get_variant("model_test", user_id)
variant.model.predict(data)
```

### **3. Drift Detection → Model Health**
```elixir
# Monitor predictions for degradation
drift = Zixir.Drift.detect(current_predictions, baseline)
if drift.drift_detected:
  trigger_retraining()
```

### **4. Workflow → Orchestration**
```elixir
# Combine all features in fault-tolerant workflow
workflow ai_pipeline:
  validate → route → predict → check_drift → log
end
```

---

## Summary

**These features work together to create AI systems that:**

✅ **Self-validate** - Check data quality automatically  
✅ **Self-improve** - A/B test and promote better models  
✅ **Self-heal** - Detect drift and retrain automatically  
✅ **Self-monitor** - Full observability without manual setup  
✅ **Self-protect** - Resource limits prevent runaway processes  

**Result: AI systems that run 24/7 with minimal human intervention!** 🤖