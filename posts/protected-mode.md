<!--
.. title: 0x0A Protected mode
.. slug: protected-mode
.. date: 2019-06-10 00:00:00 UTC
.. tags: asm, os
.. category: os
.. link: 
.. description: Bootloader which switch to protected mode. 
.. type: text
-->

When our bootloader takes control it runs 16-bit *Real mode*. In this mode a
program has access to 1MB of RAM. So honest operating system should switch to 
*Protected mode* to make use of 32-bit addressing space. In bonus we get memory
features such as *Segmented* or *Paged memory*.

<!-- TEASER_END -->

*Segmented memory* vs *Paged memory* -> 31 bit in CR0 register.
Right after setting where our 16-bit code is placed in memory (ORG) we should
disable interrupts ```cli```. 
We need to fill a GDT structure for memory. GDT structure is described in
Intel'a manual.
