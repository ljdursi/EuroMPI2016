# How Can MPI Fit Into Today's Big Computing?

This is the presentation and associated materials for [my talk](http://www.eurompi2016.ed.ac.uk/keynotes#dursi)
at EuroMPI 2016.

Included are the presentation materials (visible at http://ljdursi.github.io/EuroMPI2016), the [examples](./examples)
and [VMs](./vms) to run them for all code samples.

Covered are a broad selection of widely used tools in the current large-scale computing landscape:
* [Spark/GraphX](http://spark.apache.org)
* [Dask](http://dask.pydata.org)
* [TensorFlow](http://tensorflow.org)
* [Chapel](http://chapel.cray.com)

Which have some interesting commonalities underlying their very
diverse ways of providing high-performance but productive programing
environments for large-scale techincal computing.  One important
functionality they share is making possible computing on very
unstructured, irregular, dynamic domains, which is becoming
increasingly important even in normally more strutured HPC applications
as we go to larger and larger scales.  

To manage that complexity, they all implicitly or increasingly
explicitly express the data flow as an execution graph which can
then be optimized over before computation.  The benfits of this
sort of approach have [not been lost on the HPC
community](http://icl.cs.utk.edu/parsec/).

Most of the tools above &mdash; and certainly all big data tools
&mdash; have sprung into existance in the last 10 years, and it's
worth exploring what the underlying enabling technologies have
been at the &ldquo;data layer&rdquo; that have allowed such a diverse
range of programming models when MPI, it must be said, has not
enbaled such tools?

Thus we also cover
* [Akka](http://akka.io) which undergirds Spark and Flink amongst others
* [Data Plane Development Kit](http://dpdk.org) a C++ framework which powers [ScyllaDB](http://www.scylladb.com) an extremely fast and efficient distributed NoSQL database key-value store and it's programming framework, [Seastar](http://www.seastar-project.org)
* [Libfabric](https://ofiwg.github.io/libfabric/), [UCX](http://www.openucx.org) and [CCI](https://github.com/CCI/cci), which all have in common the aim of being low-level high-perforamance technology-agnostic commincations libraries &mdash; notionally (or in some cases literally) the network-agnostic layers from MPI implementations that could also then be used by other programming models, or parallel file systems, or..
* and the HPC standby [GASNET](https://gasnet.lbl.gov) 

Trying to distill these down it seems like their commonality is that they support active messages/RPC for managing highly irregular communication
patterns, and various approaches for high performance - often (but not always) RDMA which is particularly well suited for efficient management of
large amounts of mutable state.

After that review, I consider in what directions MPI could go to flourish. As a programming model, it faces assault from moderate scales from high-productivity
tools for data analysis (but not necessarily simulation yet) from tools like Spark, and on smaller scales from tools such as Dask and Tensorflow; if Chapel
starts to take off then the current redoubt of moderate-scale simulations might become lost.

As a data layer, its primary advantages come not from the API but the very high-performance and well-tuned implementation of network layers, 
but those implementations are already being stripped for parts by projects like CCI, UCX, and Libfabric - and yet it lacks active message support,
which those have.

MPI could yet flourish anew - I'd very much like to see a future where every scientist relies on MPI every day without ever writing MPI code
by the library adding active message support, stepping back from synchronous and in-order semantics, and becoming the underlying tool which
other models rely on.  But that window is closing, and time is running short.
