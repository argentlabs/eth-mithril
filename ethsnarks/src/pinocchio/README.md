# Pinocchio Circuit Format

This directory includes support for the Pinocchio and Extended Pinocchio format circuits. The `pinocchio` executable handles the following tasks:

 * evaluating circuit file and its inputs
 * generating the proving and verification keys
 * creating a proof, with inputs

Usage:

 * `pinocchio <circuit.arith> <genkeys|prove|verify|eval|trace|test> ...`

Where, given a circuit definition file `<circuit.arith>`, the following operations can be performed:

 * `genkeys` - Generate a proving and verification key
 * `prove` - Create a proof
 * `verify` - Given the verification key and a proof, verify if it is correct
 * `eval` - Evaluate all instructions with the inputs, display the outputs
 * `trace` - Like `eval`, but show every instruction, its inputs and outputs, when evaluated
 * `test` - Like `eval` but generates a proving key then verifies it


# Opcodes

The `circuit.arith` file contains one opcode per line, each opcode can specify an input, a private input, an output or an instruction.

Example

```
total 15
input 0                  # The one-input wire.
const-mul-0 in 1 <0> out 1 <1>
input 2                  # Input a 0
input 3                  # Input a 1
input 4                  # Input a 2
input 5                  # Input b 0
input 6                  # Input b 1
input 7                  # Input b 2
mul in 2 <2 5> out 1 <8>                # Multiply elements # 0
add in 2 <1 8> out 1 <9>
mul in 2 <3 6> out 1 <10>               # Multiply elements # 1
add in 2 <9 10> out 1 <11>
mul in 2 <4 7> out 1 <12>               # Multiply elements # 2
add in 2 <11 12> out 1 <13>
mul in 2 <13 0> out 1 <14>              # output of dot product a, b
output 14                        # output of dot product a, b
```

## Input / Output

All public inputs and outputs for the circuit are used as public inputs for the circuit. For example, if the file contains 3 inputs and 2 outputs the resulting circuit will have 5 public inputs which need to be passed in upon verification.

### total

Specify the total number of wires

### input

User input wire, a value must be provided.

### output

Computed output wire, a value will be computed by the circuit as a result.

### nizkinput

Private input, not disclosed to any observers, but a value must be provided.

## Instructions

Each instruction specifies the number of input and output wires, in the format of:

```
opcode-name in n <W1 W2 Wn> out m <W1 W2 Wm>
```

For example, with 3 inputs and 2 outputs, the `example` opcode would be:

```
example in 3 <1 2 3> out 1 <4>
```

### add

Only accepts 2 inputs and 1 output

#### Pseudocode

```
input1 + input2 == output
```

#### Example:

```
add in 2 <2839 2840> out 1 <2841>
```

### mul

Only accepts 2 inputs and 1 output

#### Pseudocode

```
input1 * input2 == output
```

#### Example:

```
mul in 2 <2839 2840> out 1 <2841>
```

### xor

Only accepts 2 inputs and 1 output

```
input1 ^ input2 == output
```

#### Example:

```
xor in 2 <2839 2840> out 1 <2841>
```

### or

Only accepts 2 inputs and 1 output.

```
input1 | input2 == output
```

#### Example:

```
or in 2 <2839 2840> out 1 <2841>
```

### assert

Only accepts 2 inputs and 1 output, works similarly to the `mul` instruction, except that when evaluating the circuit the output isn't set to the result of the multiplication - it is an assertion that `A*B==C`.

#### Pseudocode

```
input1 * input2 == output
```

#### Example:

```
assert in 2 <2839 2840> out 1 <2841>
```

### zerop

Only accepts 2 inputs and 1 output

### split

Accepts one input and many outputs

### pack

Accepts many inputs and one output

### const-mul

Multiply the input wire by a constant, the constant is appended to the end of the instruction name in hexadecimal format, for example:

```
const-mul-ffff in 1 <3872> out 1 <3873>
```

Multiplies input wire by `0xFFFF` (65535) and sets output wire to the result.

### const-mul-neg

As with `const-mul`, but negates the constant.

```
const-mul-ffff in 1 <3872> out 1 <3873>
```

Multiplies input wire by `-0xFFFF` (-65535) and sets output wire to the result.

### table

The `table` instruction acts as a look-up table, or LUT, allowing arbitrary logic to be implemented without combinations of gates. Adding this instruction will make it very easy to translate Fairplay circuits into the 'Extended Pinocchio Format'. The values of the lookup table can be arbitrary field elements, or just zeros and ones.

```
table %d <%d ...> in <%d ...> out %d
```

For example

```
table 3 <0 1 0 1 0 1 0 1> in <3872 3873 3874> out <3875>
```

This maps the 3 input bits (3872, 3873 and 3874) from the table (`0 1 0 1 0 1 0 1`) to the output variable (3875). The inputs are taken in little-endian order. With (from the example above), `1 0 0` mapping to `0`, `0 1 0` mapping to `1` and `1 1 0` mapping to `0`.

The FairPlay compiler uses lookup tables for every operation, allowing lookup tables of length zero to length 4.

The syntax of this instruction is:

```
"table" nbits "<" value [value ...] ">" "in" "<" wire [wire ...] ">" "out" "<" wire ">"
```

#### Table of length 4

Currently unsupported

```
table 4 <0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1> in <3872 3873 3874 3875> out <3876>
```

#### Table of length 3

```
table 3 <0 1 0 1 0 1 0 1> in <3872 3873 3874> out <3875>
```

#### Table of length 2

```
table 2 <0 1 0 1> in <3872 3873> out <3874>
```

#### Table of length 1

The only real reason for a gate of table length 1 is to invert the input.

Currently unsupported

```
table 1 <1 0> in <3872> out <3873>
```

#### Table of length 0

Regardless of if the input value is 0 or 1, both values will be mapped to the same value. This is a constant, and shouldn't be necessary, but is used by the FairPlay v1 SFDL compiler.

Currently unsupported

```
table 0 <1> in <3872> out <3873>
```
