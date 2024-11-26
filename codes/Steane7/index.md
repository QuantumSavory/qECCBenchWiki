+++
title = "The Code Family `Steane7`"
+++

# The Code Family `Steane7`

One of the earliest proof-of-concept error correcting codes.

![summary of all evaluations that have been executed for this code family](./totalsummary.png)

@@card
@@card-header
References
@@
@@card-body
[ECC Zoo entry](https://errorcorrectionzoo.org/c/steane)~~~<br>~~~
[QuantumClifford.jl docs](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.Steane7)
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
### Steane7()
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Steane7() instance of this code family](./Steane7().png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Steane7() instance of this code family](./Steane7()_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Steane7() instance of this code family](./Steane7()_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

<!-- #### Shor Syndrome Extraction Circuit -->

<!-- @@small -->
<!-- can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit) -->
<!-- @@ -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~



## Performance of Specific Decoders

TODO
