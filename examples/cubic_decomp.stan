functions {
  vector mech_init(int P, real X, real Y, real Z, real density);
  vector mech_rus(int N, vector lookup, matrix C);
}

data {
  int<lower = 1> P; // Maximum order polynomials to use in RR solution
  int<lower = 1> N; // Number of resonance modes

  real<lower = 0.0> X;
  real<lower = 0.0> Y;
  real<lower = 0.0> Z;

  real<lower = 0.0> density;
  
  vector[N] y;
}

transformed data {
  //vector[L * L * 3 * 3 + L * L + L * L * 3 * 3 * 21 + L * L * 3 * 3] lookup;
  int L = (P + 1) * (P + 2) * (P + 3) / 6;
  vector[L * L * 3 * 3 * 21] lookup;

  lookup = mech_init(P, X, Y, Z, density);
}

parameters {
  real<lower = 0.0> sigma;
  positive_ordered[6] v;
  matrix[6, 6] M;
}

transformed parameters {
  real c12;
  matrix[6, 6] Q = qr_Q(M);
  matrix[6, 6] C = Q * diag_matrix(v) * Q';
}

model {
  vector[N] freqs = mech_rus(N, lookup, C);

  v ~ normal(1.5, 0.75);
  to_vector(M) ~ normal(0.0, 1.0);

  sigma ~ normal(0, 0.1);
  
  y ~ normal(freqs, sigma);
}

generated quantities {
  vector[N] yhat;
  vector[N] freqs = mech_rus(N, lookup, C);
  vector[N] error;

  for(n in 1:N) {
    error[n] = freqs[n] - y[n];
    yhat[n] = normal_rng(freqs[n], sigma);
  }
}
