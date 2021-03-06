// These are some externally defined functions that do the RUS forward model.
//   That is, they take in elastic constants and produce resonance modes
functions {
  vector mech_init(int P, real X, real Y, real Z, real density);
  matrix mech_rotate(matrix C, vector q);
  vector mech_rus(int N, vector lookup, matrix C);
  vector cu2qu(vector cu);
}

// Input data
data {
  int<lower = 1> P; // Order of polynomials for Rayleigh-Ritz approx
  int<lower = 1> N; // Number of resonance modes

  // Sample known quantities
  real<lower = 0.0> X;
  real<lower = 0.0> Y;
  real<lower = 0.0> Z;

  real<lower = 0.0> density;

  // Resonance modes
  vector[N] y;
}

transformed data {
  int L = (P + 1) * (P + 2) * (P + 3) / 6;
  vector[L * L * 3 * 3 * 21] lookup;

  lookup = mech_init(P, X, Y, Z, density);
}

// Parameters to estimate
parameters {
  real<lower = 0.0> c11;
  real<lower = 1.0> a;
  real<lower = 0.0> c44;
  real<lower = 0.0> sigma; // we'll estimate measurement noise
  vector<lower = -1.0725146985555127, upper = 1.0725146985555127>[3] cu; // rotation between sample & xtal axes
}

// Build a 6x6 stiffness matrix and rotate it
transformed parameters {
  real c12;
  matrix[6, 6] C;
  vector[4] q;
  real zero = 0.0;
  
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

  q = cu2qu(cu);
  
  C = mech_rotate(C, q);
}

// This is the probabilistic model
model {
  // Specify a prior on noise level. Units are khz, we expect ~100-300hz in a good fit
  sigma ~ normal(0, 0.2);

  // Specify soft priors on the elastic constants
  c11 ~ normal(1.0, 2.0);
  a ~ normal(1.0, 2.0);
  c44 ~ normal(1.0, 2.0);

  // Resonance modes are normally distributed around what you'd expect from an RUS calculation
  y ~ normal(mech_rus(N, lookup, C), sigma);
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
