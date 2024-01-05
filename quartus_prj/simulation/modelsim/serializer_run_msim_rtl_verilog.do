transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+/home/vladimir/NTC/serialaizer/rtl {/home/vladimir/NTC/serialaizer/rtl/serializer.sv}

