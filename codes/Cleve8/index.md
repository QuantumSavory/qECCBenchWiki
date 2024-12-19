+++
title = "The Code Family `Cleve8`"
+++

# The Code Family `Cleve8`

The `[[8,3,3]]` code from Cleve and Gottesman (1997), a convenient pedagogical example when studying how to construct encoding circuits, as it is one of the smallest codes with more than one logical qubit.

![summary of all evaluations that have been executed for this code family](./totalsummary.png)

@@card
@@card-header
References
@@
@@card-body
[ECC Zoo entry]()~~~<br>~~~
[QuantumClifford.jl docs](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.Cleve8)
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
### Cleve8()
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Cleve8() instance of this code family](./Cleve8().png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Cleve8() instance of this code family](./Cleve8()_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Cleve8() instance of this code family](./Cleve8()_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Cleve8() instance of this code family](./Cleve8()_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~



## Performance of Specific Decoders

TODO