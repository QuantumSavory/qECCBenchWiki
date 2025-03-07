+++
title = "The Code Family `Surface`"
+++

# The Code Family `Surface`

An open-boundary version of the famous toric code, the first topological code. Terrible rate, ok-ish distance, awesome locality -- a tradeoff that will turn out to be fundamental to codes with only 2D connectivity.

![summary of all evaluations that have been executed for this code family](./totalsummary.png)

@@card
@@card-header
References
@@
@@card-body
[ECC Zoo entry](https://errorcorrectionzoo.org/c/surface)~~~<br>~~~
[QuantumClifford.jl docs](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.Surface)
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
### Surface(3, 3)
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Surface(3, 3) instance of this code family](./Surface(3, 3).png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Surface(3, 3) instance of this code family](./Surface(3, 3)_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Surface(3, 3) instance of this code family](./Surface(3, 3)_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Surface(3, 3) instance of this code family](./Surface(3, 3)_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~


~~~
<details>
<summary>
~~~
### Surface(4, 4)
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Surface(4, 4) instance of this code family](./Surface(4, 4).png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Surface(4, 4) instance of this code family](./Surface(4, 4)_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Surface(4, 4) instance of this code family](./Surface(4, 4)_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Surface(4, 4) instance of this code family](./Surface(4, 4)_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~


~~~
<details>
<summary>
~~~
### Surface(6, 6)
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Surface(6, 6) instance of this code family](./Surface(6, 6).png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Surface(6, 6) instance of this code family](./Surface(6, 6)_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Surface(6, 6) instance of this code family](./Surface(6, 6)_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Surface(6, 6) instance of this code family](./Surface(6, 6)_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~


~~~
<details>
<summary>
~~~
### Surface(8, 8)
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Surface(8, 8) instance of this code family](./Surface(8, 8).png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Surface(8, 8) instance of this code family](./Surface(8, 8)_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Surface(8, 8) instance of this code family](./Surface(8, 8)_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Surface(8, 8) instance of this code family](./Surface(8, 8)_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~


~~~
<details>
<summary>
~~~
### Surface(10, 10)
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Surface(10, 10) instance of this code family](./Surface(10, 10).png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Surface(10, 10) instance of this code family](./Surface(10, 10)_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Surface(10, 10) instance of this code family](./Surface(10, 10)_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Surface(10, 10) instance of this code family](./Surface(10, 10)_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~


~~~
<details>
<summary>
~~~
### Surface(12, 12)
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the Surface(12, 12) instance of this code family](./Surface(12, 12).png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the Surface(12, 12) instance of this code family](./Surface(12, 12)_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the Surface(12, 12) instance of this code family](./Surface(12, 12)_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

<!-- ![the Shor syndrome extraction circuit of the Surface(12, 12) instance of this code family](./Surface(12, 12)_shor_syndrome.png) -->
<!-- TODO: make the above work reliably and uncomment it -->

<!-- TODO: Make QASM download for Shor syndrome circuit -->

~~~
</details>
~~~



## Performance of Specific Decoders

TODO