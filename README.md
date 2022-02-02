#  About

This app is an exploration of how to best use Core Data NSManagedObjects in high performance numerical code. I want to explore the performance of a NSManagedObject with a double attribute in a hot loop, as compared to using a struct with a double attribute.

In this test my "hot loop" is calculating the digits of Pi using the Gregory-Leibniz series. I'm running 5M iterations per calculation, and repeating each calculation 200 times per condition. The final value of pi for the 200th iteration is shown on screen.

<img src="./screenshot.png" width="400px"></img>

I find that using a NSManagedObject for the inner loop results in 25-30 fold slower performance compared to a struct. I'd be very interested in any ideas for ways to mitigate this performance impact.

**NOTE** You will probably need to compile with the Profile scheme (as a Release) to get acceptable performance.

A side note on the architecture of this test: in my other project, the simulation will take a set of initial conditions, pass those to a simulator object, and run many permuations of the initial conditions. Only the initial conditions will be persisted, and the transient values observed during the simulation will be discarded. For this reason, in this test app I create a background context for the calculatePi process, which allows the NSManagedObject to change during the simulation without affecting the UI, and without being persisted between the 200 runs. In this test app the initial value of the passed NSManagedObject is not used, but in my other project it will be, so here I am prototyping the flow of data.
