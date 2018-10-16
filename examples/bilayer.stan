functions {
  int bilayer_lookup_size(int IN, int JN, int KN);
  vector bilayer_init(int IN, int JN, int layer_index, real X, real Y, vector Zs, real bulk_density, real layer_density);
  vector bilayer_rus(int N, vector lookup, matrix C1, matrix C2);
}

data {
  int<lower = 1> IN;
  int<lower = 1> JN;
  int<lower = 1> KN;
  int<lower = 1> N; // Number of resonance modes

  real<lower = 0.0> X;
  real<lower = 0.0> Y;
  real<lower = 0.0> Z;
  real<lower = 0.0, upper = Z> B;

  real<lower = 0.0> bulk_density;
  real<lower = 0.0> layer_density;
  
  vector[N] y;
}

transformed data {
  vector[bilayer_lookup_size(IN, JN, KN + 1)] lookup;
  int layer_index;

  {
    vector[KN + 1] zs;
    for(i in 1:KN) {
      zs[i + 1] = Z * (i - 1.0) / (KN - 1.0);
    }

    for(i in 1:KN) {
      if(zs[i + 1] < B) {
        zs[i] = zs[i + 1];
      } else {
        layer_index = i;
        zs[i] = B;
        break;
      }
    }

    lookup = bilayer_init(IN, JN, layer_index, X, Y, zs, bulk_density, layer_density);
  }
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
  sigma ~ normal(0, 2.0);

  c11 ~ normal(1.0, 2.0);
  a ~ normal(1.0, 2.0);
  c44 ~ normal(1.0, 2.0);

  y ~ normal(bilayer_rus(N, lookup, C, C), sigma);
}

generated quantities {
  vector[N] yhat;

  {
    vector[N] freqs = bilayer_rus(N, lookup, C, C);
    for(n in 1:N) {
      yhat[n] = normal_rng(freqs[n], sigma);
    }
  }
}
