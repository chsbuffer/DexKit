@file:Suppress("MemberVisibilityCanBePrivate", "unused")

package org.luckypray.dexkit.result

import org.luckypray.dexkit.DexKitBridge
import org.luckypray.dexkit.InnerInstructionMeta
import org.luckypray.dexkit.InnerOperandType

/**
 * Represents a single bytecode instruction.
 *
 * For instructions with meaningful operands, exactly one of the operand
 * fields will be non-null:
 * - INVOKE_* → [methodRef]
 * - IGET/IPUT/SGET/SPUT_* → [fieldRef]
 * - NEW_INSTANCE, CHECK_CAST, INSTANCE_OF, CONST_CLASS, NEW_ARRAY → [classRef]
 * - CONST_STRING* → [string]
 * - CONST* (numeric) → [literal]
 *
 * For other instructions (NOP, MOVE, GOTO, IF_*, RETURN, etc.)
 * all operand fields are null.
 * ----------------
 * 表示一条字节码指令。
 *
 * 对于有意义操作数的指令，恰好有一个操作数字段非 null：
 * - INVOKE_* → [methodRef]
 * - IGET/IPUT/SGET/SPUT_* → [fieldRef]
 * - NEW_INSTANCE、CHECK_CAST、INSTANCE_OF、CONST_CLASS、NEW_ARRAY → [classRef]
 * - CONST_STRING* → [string]
 * - CONST*（数字常量）→ [literal]
 *
 * 对于其他指令（NOP、MOVE、GOTO、IF_*、RETURN 等），所有操作数字段均为 null。
 */
data class InstructionData(
    /** Instruction index in the method bytecode. */
    val index: Int,
    /** Dalvik opcode (0-255). */
    val opcode: Int,
    /** For INVOKE_* instructions. */
    val methodRef: MethodData? = null,
    /** For IGET/IPUT/SGET/SPUT_* instructions. */
    val fieldRef: FieldData? = null,
    /** For NEW_INSTANCE, CHECK_CAST, INSTANCE_OF, CONST_CLASS, NEW_ARRAY instructions. */
    val classRef: ClassData? = null,
    /** For CONST_STRING* instructions. */
    val string: String? = null,
    /** For CONST* numeric instructions (raw bits; float/double encoded as raw Long). */
    val literal: Long? = null,
) {
    internal companion object `-Companion` {
        fun from(bridge: DexKitBridge, meta: InnerInstructionMeta): InstructionData {
            val opType = meta.operandType
            return InstructionData(
                index = meta.index.toInt(),
                opcode = meta.opcode,
                methodRef = if (opType == InnerOperandType.MethodRef) meta.methodRef?.let { MethodData.from(bridge, it) } else null,
                fieldRef = if (opType == InnerOperandType.FieldRef) meta.fieldRef?.let { FieldData.from(bridge, it) } else null,
                classRef = if (opType == InnerOperandType.ClassRef) meta.classRef?.let { ClassData.from(bridge, it) } else null,
                string = if (opType == InnerOperandType.String) meta.stringValue else null,
                literal = if (opType == InnerOperandType.Literal) meta.literalValue else null,
            )
        }
    }
}
