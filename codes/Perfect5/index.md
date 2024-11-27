+++
title = "The Code Family `Perfect5`"
+++

# The Code Family `Perfect5`

One of the earliest proof-of-concept error correcting codes. The smallest code that can protect against any single-qubit error. Not a CSS code.

![summary of all evaluations that have been executed for this code family](./totalsummary.png)

@@card
@@card-header
References
@@
@@card-body
[ECC Zoo entry](https://errorcorrectionzoo.org/c/stab_5_1_3)~~~<br>~~~
[QuantumClifford.jl docs](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.Perfect5)
@@
@@


## A Few Examples from this Family

@@small
Click on the &#9654; marker to expand
@@


~~~
<details>
<summary>
~~~
### Perfect5()
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Perfect5() instance of this code family](./Perfect5().png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Perfect5() instance of this code family](./Perfect5()_encoding.png)

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Perfect5() instance of this code family](./Perfect5()_encoding.png)

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

![the Shor syndrome extraction circuit of the Perfect5() instance of this code family](./Perfect5()_shor.png)

~~~
</details>
~~~



## Performance of Specific Decoders

TODO

