# Health Check Controller for Rails
#
# Three levels of health checks:
# - /health/live   -> Is the process running? (Kubernetes liveness)
# - /health/ready  -> Ready to receive traffic? (Kubernetes readiness)
# - /health/full   -> All dependencies working? (debugging)
#
# CRITICAL: Never put external dependency checks in liveness probe.
# If your /health/live checks the database and the DB gets slow:
# 1. Liveness fails
# 2. Kubernetes kills the pod
# 3. Kubernetes starts new pod
# 4. New pod tries to connect to (already overloaded) database
# 5. Liveness fails again
# 6. Infinite restart loop
#
# Rule: /health/live should be DUMB - returns 200 if binary is running. Period.
#       /health/ready checks dependencies to REMOVE TRAFFIC, without killing the process.

class HealthController < ApplicationController
  # Skip authentication for health checks
  skip_before_action :authenticate_user!, if: -> { respond_to?(:authenticate_user!) }

  # GET /health/live
  def live
    render json: { status: 'alive' }, status: :ok
  end

  # GET /health/ready
  def ready
    checks = {
      database: check_database,
      redis: check_redis,
      sidekiq: check_sidekiq
    }

    all_healthy = checks.values.all? { |c| c[:status] == 'healthy' }

    render json: {
      status: all_healthy ? 'healthy' : 'unhealthy',
      timestamp: Time.current.utc.iso8601,
      checks: checks
    }, status: all_healthy ? :ok : :service_unavailable
  end

  private

  def check_database
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # SELECT 1 tests connectivity, not data integrity
    # For data validation, use specific queries in readiness check
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'healthy', duration_ms: elapsed_ms(start) }
  rescue StandardError => e
    { status: 'unhealthy', duration_ms: elapsed_ms(start), error: e.message }
  end

  def check_redis
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Redis.current.ping
    { status: 'healthy', duration_ms: elapsed_ms(start) }
  rescue StandardError => e
    { status: 'unhealthy', duration_ms: elapsed_ms(start), error: e.message }
  end

  def check_sidekiq
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    Sidekiq.redis(&:ping)
    { status: 'healthy', duration_ms: elapsed_ms(start) }
  rescue StandardError => e
    { status: 'unhealthy', duration_ms: elapsed_ms(start), error: e.message }
  end

  def elapsed_ms(start)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)
  end
end
