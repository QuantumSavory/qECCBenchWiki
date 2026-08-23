+++
title = "The Code Family `{{:codetypename}}`"
+++

# The Code Family `{{:codetypename}}`

{{{:description}}}

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

{{#:family_entries}}

~~~
<details>
<summary>
~~~
### {{:codetypename}}{{:family_str}}
~~~
</summary>
~~~

#### Parity Check Tableau

![the parity check tableau of the {{:instance_name}} instance of this code family](./{{{:instance_name}}}.png)

{{#:has_artifacts}}
#### Downloads

@@small
Parity-check matrices are binary over GF(2). The full matrix uses `(X|Z)` column order.
@@

{{#:artifact_downloads}}
- [{{:label}}]({{{:href}}}) - {{:description}}
{{/:artifact_downloads}}

{{/:has_artifacts}}

{{#:has_encoding}}
#### Encoding Circuit

@@small
can be generated with [`QuantumClifford.naive_encoding_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_encoding_circuit)
@@

![the encoding circuit of the {{:instance_name}} instance of this code family](./{{{:instance_name}}}_encoding.png)

<!-- TODO: Make QASM download for naive encoding circuit -->
{{/:has_encoding}}

{{#:has_naive_syndrome}}
#### Naive Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.naive_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.naive_syndrome_circuit)
@@

![the naive syndrome extraction circuit of the {{:instance_name}} instance of this code family](./{{{:instance_name}}}_naive_syndrome.png)

<!-- TODO: Make QASM download for naive syndrome circuit -->
{{/:has_naive_syndrome}}

{{#:has_shor_syndrome}}
#### Shor Syndrome Extraction Circuit

@@small
can be generated with [`QuantumClifford.shor_syndrome_circuit`](https://quantumsavory.github.io/QuantumClifford.jl/dev/ECC_API/#QuantumClifford.ECC.shor_syndrome_circuit)
@@

![the Shor syndrome extraction circuit of the {{:instance_name}} instance of this code family](./{{{:instance_name}}}_shor_syndrome.png)

<!-- TODO: Make QASM download for Shor syndrome circuit -->
{{/:has_shor_syndrome}}

~~~
</details>
~~~

{{/:family_entries}}


## Performance of Specific Decoders

TODO
