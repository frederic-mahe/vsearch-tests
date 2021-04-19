#!/usr/bin/env bash -

## Print a header
SCRIPT_NAME="fuzzing"
LINE=$(printf -- "-%.0s" {1..76})
printf "# %s %s\n" "${LINE:${#SCRIPT_NAME}}" "${SCRIPT_NAME}"

## Declare a color code for test results
RED="\033[1;31m"
GREEN="\033[1;32m"
NO_COLOR="\033[0m"

failure () {
    printf "${RED}FAIL${NO_COLOR}: ${1}\n"
    # exit 1
}

success () {
    printf "${GREEN}PASS${NO_COLOR}: ${1}\n"
}

## use the first binary in $PATH by default, unless user wants
## to test another binary
VSEARCH=$(which vsearch 2> /dev/null)
[[ "${1}" ]] && VSEARCH="${1}"

DESCRIPTION="check if vsearch is executable"
[[ -x "${VSEARCH}" ]] && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"


#*****************************************************************************#
#                                                                             #
#   afl-fuzz (afl-2.47b) with vsearch v2.4.3 and the --fastq_chars command    #
#                                                                             #
#*****************************************************************************#

# crash cases discovered in late July 2017 by Frédéric Mahé and Dylan
# Meunier, minimized with afl-tmin

# crash file id:000001,sig:11,src:000096,op:flip1,pos:5
DESCRIPTION="crash test1: empty header, empty sequence, ascii > 127"
"${VSEARCH}" --fastq_chars <(printf "@\n\n+\n\253") &>/dev/null && \
    success "${DESCRIPTION}" || \
        failure "${DESCRIPTION}"
unset DESCRIPTION

# id:000002,sig:06,src:000096+000121,op:splice,rep:4 (octal 213)
# id:000003,sig:06,src:000100,op:flip2,pos:6 (octal 253)
# id:000007,sig:11,src:000112,op:flip4,pos:12 (octal 253)
# id:000008,sig:06,src:000112,op:havoc,rep:4 (octal 362)
# id:000010,sig:06,src:000122+000102,op:splice,rep:4 (octal 346)
# id:000011,sig:11,src:000124,op:flip1,pos:9 (octal 253)
# id:000012,sig:11,src:000127,op:flip1,pos:14 (octal 212)
# id:000013,sig:11,src:000127,op:flip2,pos:13 (octal 212)
# id:000014,sig:11,src:000127,op:flip4,pos:13 (octal 312)
# id:000015,sig:06,src:000127,op:havoc,rep:2 (octal 210)
# id:000016,sig:11,src:000129,op:flip1,pos:14 (octal 212)
# id:000017,sig:11,src:000129,op:flip2,pos:13 (octal 212)
# id:000019,sig:06,src:000145,op:havoc,rep:2 (octal 325)
# id:000020,sig:11,src:000145,op:havoc,rep:2 (octal 313)
# id:000024,sig:11,src:000166,op:flip1,pos:8 (octal 212)
# id:000025,sig:11,src:000166,op:flip2,pos:9 (octal 212)
# id:000026,sig:11,src:000166,op:havoc,rep:2 (octal 212)
# id:000028,sig:11,src:000167,op:havoc,rep:2 (octal 212)
# id:000029,sig:11,src:000172,op:flip1,pos:7 (octal 212)
# id:000030,sig:06,src:000175,op:havoc,rep:4 (octal 210)
# id:000031,sig:11,src:000179,op:flip1,pos:15 (octal 212)
# id:000032,sig:11,src:000179,op:flip2,pos:17 (octal 212)
# id:000033,sig:11,src:000179,op:flip2,pos:20 (octal 212)
# id:000034,sig:11,src:000179,op:flip4,pos:17 (octal 212)
# id:000035,sig:06,src:000179,op:arith16,pos:18,val:-24 (octal 362)
# id:000036,sig:06,src:000179,op:havoc,rep:4 (octal 356)
# id:000037,sig:11,src:000184,op:flip1,pos:14 (octal 212)
# id:000038,sig:11,src:000185,op:flip1,pos:14 (octal 212)
# id:000040,sig:11,src:000188,op:flip1,pos:14 (octal 212)
# id:000041,sig:11,src:000200,op:flip1,pos:20 (octal 212)
# id:000042,sig:11,src:000201,op:flip1,pos:15 (octal 212)
# id:000044,sig:11,src:000204,op:flip1,pos:14 (octal 212)
# id:000045,sig:11,src:000211,op:flip1,pos:20 (octal 212)
# id:000046,sig:11,src:000173,op:flip32,pos:24 (octal 212)
# id:000047,sig:06,src:000224,op:arith8,pos:53,val:-32 (octal 366)
# id:000048,sig:11,src:000224,op:havoc,rep:8 (octal 246)
# id:000050,sig:06,src:000244,op:arith8,pos:8276,val:-6 (octal 213)
# id:000052,sig:06,src:000262,op:arith8,pos:4259,val:-9 (octal 366)
# id:000053,sig:06,src:000097+000068,op:splice,rep:32 (octal 212)
# id:000057,sig:06,src:000392+000343,op:splice,rep:64 (octal 350)
# id:000059,sig:06,src:000401+000329,op:splice,rep:4 (octal 356)
# id:000060,sig:06,src:000407+000338,op:splice,rep:8 (octal 366)
# id:000061,sig:06,src:000390+000347,op:splice,rep:64 (octal 350)
# id:000063,sig:06,src:000396+000330,op:splice,rep:16 (octal 350)

## No crash
# id:000000,sig:11,src:000093+000100,op:splice,rep:4
# id:000004,sig:06,src:000100,op:arith8,pos:6,val:-6
# id:000005,sig:06,src:000100,op:havoc,rep:2
# id:000006,sig:11,src:000103,op:havoc,rep:2
# id:000009,sig:11,src:000118,op:flip32,pos:9
# id:000018,sig:11,src:000129+000124,op:splice,rep:2
# id:000021,sig:11,src:000145,op:havoc,rep:2
# id:000022,sig:06,src:000158,op:havoc,rep:2
# id:000023,sig:11,src:000160,op:havoc,rep:2
# id:000027,sig:11,src:000167,op:havoc,rep:2
# id:000039,sig:06,src:000185+000138,op:splice,rep:2
# id:000043,sig:11,src:000201,op:havoc,rep:2
# id:000049,sig:06,src:000241,op:arith8,pos:8209,val:-6
# id:000051,sig:06,src:000246,op:arith8,pos:16965,val:-6
# id:000054,sig:11,src:000194,op:havoc,rep:2
# id:000055,sig:06,src:000292,op:havoc,rep:2
# id:000056,sig:06,src:000346,op:arith8,pos:34655,val:-3
# id:000058,sig:06,src:000157+000293,op:splice,rep:8
# id:000062,sig:06,src:000398+000333,op:splice,rep:16

exit 0
