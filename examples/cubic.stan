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
  real<lower = 0.0> c11;
  real<lower = 0.0> a;
  real<lower = 0.0> c44;
  real<lower = 0.0> sigma;
}

transformed parameters {
  real c12;
  matrix[6, 6] C;
  real zero = 0.0;
  real c11_ = 0.797656;
  real c12_ = 0.586163;
  real c44_ = 0.258177;
  
  c12 = -(c44 * 2.0 / a - c11);

  for (i in 1:6)
    for (j in 1:6)
      C[i, j] = zero;
        
  C[1, 1] = c11;
  C[2, 2] = c11;
  C[3, 3] = c11;
  C[4, 4] = c44;
  C[5, 5] = c44;
  C[6, 6] = c44;
  C[1, 2] = c12;
  C[1, 3] = c12;
  C[2, 3] = c12;
  C[3, 2] = c12;
  C[2, 1] = c12;
  C[3, 1] = c12;
}

model {
  vector[N] freqs = mech_rus(N, lookup, C);

  sigma ~ normal(0, 0.2);

  c11 ~ normal(1.0, 2.0);
  a ~ normal(1.0, 2.0);
  c44 ~ normal(1.0, 2.0);
  
  y ~ normal(freqs, sigma);
}

generated quantities {
  vector[N] yhat;
  vector[N] errors;

  {
    vector[N] freqs = mech_rus(N, lookup, C);
    for(n in 1:N) {
      errors[n] = y[n] - freqs[n];
      yhat[n] = normal_rng(freqs[n], sigma);
    }
  }
}
