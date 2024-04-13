+++
title = "The Code Family `{{:codetypename}}`"
+++

# The Code Family `{{:codetypename}}`

{{:description}}

![summary of all evaluations that have been executed for this code family](./totalsummary.png)

@@card
@@card-header
References
@@
@@card-body
[ECC Zoo entry]({{{:ecczoo}}})~~~<br>~~~
[QuantumClifford.jl docs](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.{{{:codetypename}}})
@@
@@


## A Few Examples from this Family

@@small
Click on the &#9654; marker to expand
@@

{{#:family_strs}}

~~~
<details>
<summary>
~~~
### {{:codetypename}}{{.}}
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the {{:codetypename}}{{.}} instance of this code family](./{{:codetypename}}{{.}}.png)

#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the {{:codetypename}}{{.}} instance of this code family](./{{{:codetypename}}}{{{.}}}_encoding.png)

#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the {{:codetypename}}{{.}} instance of this code family](./{{{:codetypename}}}{{{.}}}_encoding.png)

#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

![the Shor syndrome extraction circuit of the {{:codetypename}}{{.}} instance of this code family](./{{{:codetypename}}}{{{.}}}_shor.png)

~~~
</details>
~~~

{{/:family_strs}}


## Performance of Specific Decoders

TODO

