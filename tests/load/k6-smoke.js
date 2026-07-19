import http from 'k6/http';
import { check, fail, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const apiErrors = new Rate('api_errors');
const healthDuration = new Trend('health_duration', true);
const jobAcceptDuration = new Trend('job_accept_duration', true);
const baseUrl = (__ENV.MAKI_BASE_URL || 'http://127.0.0.1:8000').replace(/\/$/, '');
const token = __ENV.MAKI_TOKEN || '';
const payload = JSON.stringify({
  series: {
    points: Array.from({ length: 56 }, (_, day) => ({
      day,
      index: 1 + day / 100,
    })),
  },
  horizon: 7,
});

export const options = {
  vus: 20,
  duration: '5m',
  thresholds: {
    api_errors: ['rate<0.01'],
    health_duration: ['p(95)<100'],
    job_accept_duration: ['p(95)<300'],
  },
};

export function setup() {
  if (!token) {
    fail('MAKI_TOKEN yük testi için zorunludur.');
  }
}
export default function () {
  const health = http.get(`${baseUrl}/health/live`, {
    tags: { operation: 'canlilik' },
  });
  healthDuration.add(health.timings.duration);
  const healthOk = check(health, {
    'canlılık 200 döner': (response) => response.status === 200,
  });
  apiErrors.add(!healthOk);

  const idempotencyKey = `k6-${__VU}-${Math.floor(__ITER / 3)}`;
  const accepted = http.post(`${baseUrl}/api/v1/forecasts/jobs`, payload, {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      'Idempotency-Key': idempotencyKey,
    },
    tags: { operation: 'tahmin_kabul' },
  });
  jobAcceptDuration.add(accepted.timings.duration);
  const acceptedOk = check(accepted, {
    'iş kabulü 202 döner': (response) => response.status === 202,
  });
  apiErrors.add(!acceptedOk);
  sleep(0.25);
}
