
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	d7478793          	addi	a5,a5,-652 # 80005dd0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e2678793          	addi	a5,a5,-474 # 80000ecc <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000e0:	57fd                	li	a5,-1
    800000e2:	83a9                	srli	a5,a5,0xa
    800000e4:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e8:	47fd                	li	a5,31
    800000ea:	3a079073          	csrw	pmpcfg0,a5
  asm volatile("mret");
    800000ee:	30200073          	mret
}
    800000f2:	60a2                	ld	ra,8(sp)
    800000f4:	6402                	ld	s0,0(sp)
    800000f6:	0141                	addi	sp,sp,16
    800000f8:	8082                	ret

00000000800000fa <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000fa:	715d                	addi	sp,sp,-80
    800000fc:	e486                	sd	ra,72(sp)
    800000fe:	e0a2                	sd	s0,64(sp)
    80000100:	fc26                	sd	s1,56(sp)
    80000102:	f84a                	sd	s2,48(sp)
    80000104:	f44e                	sd	s3,40(sp)
    80000106:	f052                	sd	s4,32(sp)
    80000108:	ec56                	sd	s5,24(sp)
    8000010a:	0880                	addi	s0,sp,80
    8000010c:	8a2a                	mv	s4,a0
    8000010e:	84ae                	mv	s1,a1
    80000110:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000112:	00011517          	auipc	a0,0x11
    80000116:	71e50513          	addi	a0,a0,1822 # 80011830 <cons>
    8000011a:	00001097          	auipc	ra,0x1
    8000011e:	b04080e7          	jalr	-1276(ra) # 80000c1e <acquire>
  for(i = 0; i < n; i++){
    80000122:	05305b63          	blez	s3,80000178 <consolewrite+0x7e>
    80000126:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000128:	5afd                	li	s5,-1
    8000012a:	4685                	li	a3,1
    8000012c:	8626                	mv	a2,s1
    8000012e:	85d2                	mv	a1,s4
    80000130:	fbf40513          	addi	a0,s0,-65
    80000134:	00002097          	auipc	ra,0x2
    80000138:	55a080e7          	jalr	1370(ra) # 8000268e <either_copyin>
    8000013c:	01550c63          	beq	a0,s5,80000154 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000140:	fbf44503          	lbu	a0,-65(s0)
    80000144:	00000097          	auipc	ra,0x0
    80000148:	7aa080e7          	jalr	1962(ra) # 800008ee <uartputc>
  for(i = 0; i < n; i++){
    8000014c:	2905                	addiw	s2,s2,1
    8000014e:	0485                	addi	s1,s1,1
    80000150:	fd299de3          	bne	s3,s2,8000012a <consolewrite+0x30>
  }
  release(&cons.lock);
    80000154:	00011517          	auipc	a0,0x11
    80000158:	6dc50513          	addi	a0,a0,1756 # 80011830 <cons>
    8000015c:	00001097          	auipc	ra,0x1
    80000160:	b76080e7          	jalr	-1162(ra) # 80000cd2 <release>

  return i;
}
    80000164:	854a                	mv	a0,s2
    80000166:	60a6                	ld	ra,72(sp)
    80000168:	6406                	ld	s0,64(sp)
    8000016a:	74e2                	ld	s1,56(sp)
    8000016c:	7942                	ld	s2,48(sp)
    8000016e:	79a2                	ld	s3,40(sp)
    80000170:	7a02                	ld	s4,32(sp)
    80000172:	6ae2                	ld	s5,24(sp)
    80000174:	6161                	addi	sp,sp,80
    80000176:	8082                	ret
  for(i = 0; i < n; i++){
    80000178:	4901                	li	s2,0
    8000017a:	bfe9                	j	80000154 <consolewrite+0x5a>

000000008000017c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000017c:	7119                	addi	sp,sp,-128
    8000017e:	fc86                	sd	ra,120(sp)
    80000180:	f8a2                	sd	s0,112(sp)
    80000182:	f4a6                	sd	s1,104(sp)
    80000184:	f0ca                	sd	s2,96(sp)
    80000186:	ecce                	sd	s3,88(sp)
    80000188:	e8d2                	sd	s4,80(sp)
    8000018a:	e4d6                	sd	s5,72(sp)
    8000018c:	e0da                	sd	s6,64(sp)
    8000018e:	fc5e                	sd	s7,56(sp)
    80000190:	f862                	sd	s8,48(sp)
    80000192:	f466                	sd	s9,40(sp)
    80000194:	f06a                	sd	s10,32(sp)
    80000196:	ec6e                	sd	s11,24(sp)
    80000198:	0100                	addi	s0,sp,128
    8000019a:	8b2a                	mv	s6,a0
    8000019c:	8aae                	mv	s5,a1
    8000019e:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    800001a0:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    800001a4:	00011517          	auipc	a0,0x11
    800001a8:	68c50513          	addi	a0,a0,1676 # 80011830 <cons>
    800001ac:	00001097          	auipc	ra,0x1
    800001b0:	a72080e7          	jalr	-1422(ra) # 80000c1e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001b4:	00011497          	auipc	s1,0x11
    800001b8:	67c48493          	addi	s1,s1,1660 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001bc:	89a6                	mv	s3,s1
    800001be:	00011917          	auipc	s2,0x11
    800001c2:	70a90913          	addi	s2,s2,1802 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c6:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c8:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ca:	4da9                	li	s11,10
  while(n > 0){
    800001cc:	07405863          	blez	s4,8000023c <consoleread+0xc0>
    while(cons.r == cons.w){
    800001d0:	0984a783          	lw	a5,152(s1)
    800001d4:	09c4a703          	lw	a4,156(s1)
    800001d8:	02f71463          	bne	a4,a5,80000200 <consoleread+0x84>
      if(myproc()->killed){
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	9ea080e7          	jalr	-1558(ra) # 80001bc6 <myproc>
    800001e4:	591c                	lw	a5,48(a0)
    800001e6:	e7b5                	bnez	a5,80000252 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e8:	85ce                	mv	a1,s3
    800001ea:	854a                	mv	a0,s2
    800001ec:	00002097          	auipc	ra,0x2
    800001f0:	1ea080e7          	jalr	490(ra) # 800023d6 <sleep>
    while(cons.r == cons.w){
    800001f4:	0984a783          	lw	a5,152(s1)
    800001f8:	09c4a703          	lw	a4,156(s1)
    800001fc:	fef700e3          	beq	a4,a5,800001dc <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    80000200:	0017871b          	addiw	a4,a5,1
    80000204:	08e4ac23          	sw	a4,152(s1)
    80000208:	07f7f713          	andi	a4,a5,127
    8000020c:	9726                	add	a4,a4,s1
    8000020e:	01874703          	lbu	a4,24(a4)
    80000212:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000216:	079c0663          	beq	s8,s9,80000282 <consoleread+0x106>
    cbuf = c;
    8000021a:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000021e:	4685                	li	a3,1
    80000220:	f8f40613          	addi	a2,s0,-113
    80000224:	85d6                	mv	a1,s5
    80000226:	855a                	mv	a0,s6
    80000228:	00002097          	auipc	ra,0x2
    8000022c:	410080e7          	jalr	1040(ra) # 80002638 <either_copyout>
    80000230:	01a50663          	beq	a0,s10,8000023c <consoleread+0xc0>
    dst++;
    80000234:	0a85                	addi	s5,s5,1
    --n;
    80000236:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000238:	f9bc1ae3          	bne	s8,s11,800001cc <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	5f450513          	addi	a0,a0,1524 # 80011830 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a8e080e7          	jalr	-1394(ra) # 80000cd2 <release>

  return target - n;
    8000024c:	414b853b          	subw	a0,s7,s4
    80000250:	a811                	j	80000264 <consoleread+0xe8>
        release(&cons.lock);
    80000252:	00011517          	auipc	a0,0x11
    80000256:	5de50513          	addi	a0,a0,1502 # 80011830 <cons>
    8000025a:	00001097          	auipc	ra,0x1
    8000025e:	a78080e7          	jalr	-1416(ra) # 80000cd2 <release>
        return -1;
    80000262:	557d                	li	a0,-1
}
    80000264:	70e6                	ld	ra,120(sp)
    80000266:	7446                	ld	s0,112(sp)
    80000268:	74a6                	ld	s1,104(sp)
    8000026a:	7906                	ld	s2,96(sp)
    8000026c:	69e6                	ld	s3,88(sp)
    8000026e:	6a46                	ld	s4,80(sp)
    80000270:	6aa6                	ld	s5,72(sp)
    80000272:	6b06                	ld	s6,64(sp)
    80000274:	7be2                	ld	s7,56(sp)
    80000276:	7c42                	ld	s8,48(sp)
    80000278:	7ca2                	ld	s9,40(sp)
    8000027a:	7d02                	ld	s10,32(sp)
    8000027c:	6de2                	ld	s11,24(sp)
    8000027e:	6109                	addi	sp,sp,128
    80000280:	8082                	ret
      if(n < target){
    80000282:	000a071b          	sext.w	a4,s4
    80000286:	fb777be3          	bgeu	a4,s7,8000023c <consoleread+0xc0>
        cons.r--;
    8000028a:	00011717          	auipc	a4,0x11
    8000028e:	62f72f23          	sw	a5,1598(a4) # 800118c8 <cons+0x98>
    80000292:	b76d                	j	8000023c <consoleread+0xc0>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	564080e7          	jalr	1380(ra) # 80000808 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	552080e7          	jalr	1362(ra) # 80000808 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	546080e7          	jalr	1350(ra) # 80000808 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	53c080e7          	jalr	1340(ra) # 80000808 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	e04a                	sd	s2,0(sp)
    800002e0:	1000                	addi	s0,sp,32
    800002e2:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e4:	00011517          	auipc	a0,0x11
    800002e8:	54c50513          	addi	a0,a0,1356 # 80011830 <cons>
    800002ec:	00001097          	auipc	ra,0x1
    800002f0:	932080e7          	jalr	-1742(ra) # 80000c1e <acquire>

  switch(c){
    800002f4:	47d5                	li	a5,21
    800002f6:	0af48663          	beq	s1,a5,800003a2 <consoleintr+0xcc>
    800002fa:	0297ca63          	blt	a5,s1,8000032e <consoleintr+0x58>
    800002fe:	47a1                	li	a5,8
    80000300:	0ef48763          	beq	s1,a5,800003ee <consoleintr+0x118>
    80000304:	47c1                	li	a5,16
    80000306:	10f49a63          	bne	s1,a5,8000041a <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    8000030a:	00002097          	auipc	ra,0x2
    8000030e:	3da080e7          	jalr	986(ra) # 800026e4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000312:	00011517          	auipc	a0,0x11
    80000316:	51e50513          	addi	a0,a0,1310 # 80011830 <cons>
    8000031a:	00001097          	auipc	ra,0x1
    8000031e:	9b8080e7          	jalr	-1608(ra) # 80000cd2 <release>
}
    80000322:	60e2                	ld	ra,24(sp)
    80000324:	6442                	ld	s0,16(sp)
    80000326:	64a2                	ld	s1,8(sp)
    80000328:	6902                	ld	s2,0(sp)
    8000032a:	6105                	addi	sp,sp,32
    8000032c:	8082                	ret
  switch(c){
    8000032e:	07f00793          	li	a5,127
    80000332:	0af48e63          	beq	s1,a5,800003ee <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000336:	00011717          	auipc	a4,0x11
    8000033a:	4fa70713          	addi	a4,a4,1274 # 80011830 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09872703          	lw	a4,152(a4)
    80000346:	9f99                	subw	a5,a5,a4
    80000348:	07f00713          	li	a4,127
    8000034c:	fcf763e3          	bltu	a4,a5,80000312 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000350:	47b5                	li	a5,13
    80000352:	0cf48763          	beq	s1,a5,80000420 <consoleintr+0x14a>
      consputc(c);
    80000356:	8526                	mv	a0,s1
    80000358:	00000097          	auipc	ra,0x0
    8000035c:	f3c080e7          	jalr	-196(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000360:	00011797          	auipc	a5,0x11
    80000364:	4d078793          	addi	a5,a5,1232 # 80011830 <cons>
    80000368:	0a07a703          	lw	a4,160(a5)
    8000036c:	0017069b          	addiw	a3,a4,1
    80000370:	0006861b          	sext.w	a2,a3
    80000374:	0ad7a023          	sw	a3,160(a5)
    80000378:	07f77713          	andi	a4,a4,127
    8000037c:	97ba                	add	a5,a5,a4
    8000037e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000382:	47a9                	li	a5,10
    80000384:	0cf48563          	beq	s1,a5,8000044e <consoleintr+0x178>
    80000388:	4791                	li	a5,4
    8000038a:	0cf48263          	beq	s1,a5,8000044e <consoleintr+0x178>
    8000038e:	00011797          	auipc	a5,0x11
    80000392:	53a7a783          	lw	a5,1338(a5) # 800118c8 <cons+0x98>
    80000396:	0807879b          	addiw	a5,a5,128
    8000039a:	f6f61ce3          	bne	a2,a5,80000312 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000039e:	863e                	mv	a2,a5
    800003a0:	a07d                	j	8000044e <consoleintr+0x178>
    while(cons.e != cons.w &&
    800003a2:	00011717          	auipc	a4,0x11
    800003a6:	48e70713          	addi	a4,a4,1166 # 80011830 <cons>
    800003aa:	0a072783          	lw	a5,160(a4)
    800003ae:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	00011497          	auipc	s1,0x11
    800003b6:	47e48493          	addi	s1,s1,1150 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ba:	4929                	li	s2,10
    800003bc:	f4f70be3          	beq	a4,a5,80000312 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003c0:	37fd                	addiw	a5,a5,-1
    800003c2:	07f7f713          	andi	a4,a5,127
    800003c6:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c8:	01874703          	lbu	a4,24(a4)
    800003cc:	f52703e3          	beq	a4,s2,80000312 <consoleintr+0x3c>
      cons.e--;
    800003d0:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	00000097          	auipc	ra,0x0
    800003dc:	ebc080e7          	jalr	-324(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003e0:	0a04a783          	lw	a5,160(s1)
    800003e4:	09c4a703          	lw	a4,156(s1)
    800003e8:	fcf71ce3          	bne	a4,a5,800003c0 <consoleintr+0xea>
    800003ec:	b71d                	j	80000312 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	44270713          	addi	a4,a4,1090 # 80011830 <cons>
    800003f6:	0a072783          	lw	a5,160(a4)
    800003fa:	09c72703          	lw	a4,156(a4)
    800003fe:	f0f70ae3          	beq	a4,a5,80000312 <consoleintr+0x3c>
      cons.e--;
    80000402:	37fd                	addiw	a5,a5,-1
    80000404:	00011717          	auipc	a4,0x11
    80000408:	4cf72623          	sw	a5,1228(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    8000040c:	10000513          	li	a0,256
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e84080e7          	jalr	-380(ra) # 80000294 <consputc>
    80000418:	bded                	j	80000312 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000041a:	ee048ce3          	beqz	s1,80000312 <consoleintr+0x3c>
    8000041e:	bf21                	j	80000336 <consoleintr+0x60>
      consputc(c);
    80000420:	4529                	li	a0,10
    80000422:	00000097          	auipc	ra,0x0
    80000426:	e72080e7          	jalr	-398(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000042a:	00011797          	auipc	a5,0x11
    8000042e:	40678793          	addi	a5,a5,1030 # 80011830 <cons>
    80000432:	0a07a703          	lw	a4,160(a5)
    80000436:	0017069b          	addiw	a3,a4,1
    8000043a:	0006861b          	sext.w	a2,a3
    8000043e:	0ad7a023          	sw	a3,160(a5)
    80000442:	07f77713          	andi	a4,a4,127
    80000446:	97ba                	add	a5,a5,a4
    80000448:	4729                	li	a4,10
    8000044a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000044e:	00011797          	auipc	a5,0x11
    80000452:	46c7af23          	sw	a2,1150(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000456:	00011517          	auipc	a0,0x11
    8000045a:	47250513          	addi	a0,a0,1138 # 800118c8 <cons+0x98>
    8000045e:	00002097          	auipc	ra,0x2
    80000462:	0fe080e7          	jalr	254(ra) # 8000255c <wakeup>
    80000466:	b575                	j	80000312 <consoleintr+0x3c>

0000000080000468 <consoleinit>:

void
consoleinit(void)
{
    80000468:	1141                	addi	sp,sp,-16
    8000046a:	e406                	sd	ra,8(sp)
    8000046c:	e022                	sd	s0,0(sp)
    8000046e:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000470:	00008597          	auipc	a1,0x8
    80000474:	ba058593          	addi	a1,a1,-1120 # 80008010 <etext+0x10>
    80000478:	00011517          	auipc	a0,0x11
    8000047c:	3b850513          	addi	a0,a0,952 # 80011830 <cons>
    80000480:	00000097          	auipc	ra,0x0
    80000484:	70e080e7          	jalr	1806(ra) # 80000b8e <initlock>

  uartinit();
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	330080e7          	jalr	816(ra) # 800007b8 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000490:	00021797          	auipc	a5,0x21
    80000494:	52078793          	addi	a5,a5,1312 # 800219b0 <devsw>
    80000498:	00000717          	auipc	a4,0x0
    8000049c:	ce470713          	addi	a4,a4,-796 # 8000017c <consoleread>
    800004a0:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004a2:	00000717          	auipc	a4,0x0
    800004a6:	c5870713          	addi	a4,a4,-936 # 800000fa <consolewrite>
    800004aa:	ef98                	sd	a4,24(a5)
}
    800004ac:	60a2                	ld	ra,8(sp)
    800004ae:	6402                	ld	s0,0(sp)
    800004b0:	0141                	addi	sp,sp,16
    800004b2:	8082                	ret

00000000800004b4 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004b4:	7179                	addi	sp,sp,-48
    800004b6:	f406                	sd	ra,40(sp)
    800004b8:	f022                	sd	s0,32(sp)
    800004ba:	ec26                	sd	s1,24(sp)
    800004bc:	e84a                	sd	s2,16(sp)
    800004be:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c0:	c219                	beqz	a2,800004c6 <printint+0x12>
    800004c2:	08054663          	bltz	a0,8000054e <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c6:	2501                	sext.w	a0,a0
    800004c8:	4881                	li	a7,0
    800004ca:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ce:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d0:	2581                	sext.w	a1,a1
    800004d2:	00008617          	auipc	a2,0x8
    800004d6:	b6e60613          	addi	a2,a2,-1170 # 80008040 <digits>
    800004da:	883a                	mv	a6,a4
    800004dc:	2705                	addiw	a4,a4,1
    800004de:	02b577bb          	remuw	a5,a0,a1
    800004e2:	1782                	slli	a5,a5,0x20
    800004e4:	9381                	srli	a5,a5,0x20
    800004e6:	97b2                	add	a5,a5,a2
    800004e8:	0007c783          	lbu	a5,0(a5)
    800004ec:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f0:	0005079b          	sext.w	a5,a0
    800004f4:	02b5553b          	divuw	a0,a0,a1
    800004f8:	0685                	addi	a3,a3,1
    800004fa:	feb7f0e3          	bgeu	a5,a1,800004da <printint+0x26>

  if(sign)
    800004fe:	00088b63          	beqz	a7,80000514 <printint+0x60>
    buf[i++] = '-';
    80000502:	fe040793          	addi	a5,s0,-32
    80000506:	973e                	add	a4,a4,a5
    80000508:	02d00793          	li	a5,45
    8000050c:	fef70823          	sb	a5,-16(a4)
    80000510:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000514:	02e05763          	blez	a4,80000542 <printint+0x8e>
    80000518:	fd040793          	addi	a5,s0,-48
    8000051c:	00e784b3          	add	s1,a5,a4
    80000520:	fff78913          	addi	s2,a5,-1
    80000524:	993a                	add	s2,s2,a4
    80000526:	377d                	addiw	a4,a4,-1
    80000528:	1702                	slli	a4,a4,0x20
    8000052a:	9301                	srli	a4,a4,0x20
    8000052c:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000530:	fff4c503          	lbu	a0,-1(s1)
    80000534:	00000097          	auipc	ra,0x0
    80000538:	d60080e7          	jalr	-672(ra) # 80000294 <consputc>
  while(--i >= 0)
    8000053c:	14fd                	addi	s1,s1,-1
    8000053e:	ff2499e3          	bne	s1,s2,80000530 <printint+0x7c>
}
    80000542:	70a2                	ld	ra,40(sp)
    80000544:	7402                	ld	s0,32(sp)
    80000546:	64e2                	ld	s1,24(sp)
    80000548:	6942                	ld	s2,16(sp)
    8000054a:	6145                	addi	sp,sp,48
    8000054c:	8082                	ret
    x = -xx;
    8000054e:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000552:	4885                	li	a7,1
    x = -xx;
    80000554:	bf9d                	j	800004ca <printint+0x16>

0000000080000556 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000556:	1101                	addi	sp,sp,-32
    80000558:	ec06                	sd	ra,24(sp)
    8000055a:	e822                	sd	s0,16(sp)
    8000055c:	e426                	sd	s1,8(sp)
    8000055e:	1000                	addi	s0,sp,32
    80000560:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000562:	00011797          	auipc	a5,0x11
    80000566:	3807a723          	sw	zero,910(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	aae50513          	addi	a0,a0,-1362 # 80008018 <etext+0x18>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	02e080e7          	jalr	46(ra) # 800005a0 <printf>
  printf(s);
    8000057a:	8526                	mv	a0,s1
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	024080e7          	jalr	36(ra) # 800005a0 <printf>
  printf("\n");
    80000584:	00008517          	auipc	a0,0x8
    80000588:	b4450513          	addi	a0,a0,-1212 # 800080c8 <digits+0x88>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	014080e7          	jalr	20(ra) # 800005a0 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000594:	4785                	li	a5,1
    80000596:	00009717          	auipc	a4,0x9
    8000059a:	a6f72523          	sw	a5,-1430(a4) # 80009000 <panicked>
  for(;;)
    8000059e:	a001                	j	8000059e <panic+0x48>

00000000800005a0 <printf>:
{
    800005a0:	7131                	addi	sp,sp,-192
    800005a2:	fc86                	sd	ra,120(sp)
    800005a4:	f8a2                	sd	s0,112(sp)
    800005a6:	f4a6                	sd	s1,104(sp)
    800005a8:	f0ca                	sd	s2,96(sp)
    800005aa:	ecce                	sd	s3,88(sp)
    800005ac:	e8d2                	sd	s4,80(sp)
    800005ae:	e4d6                	sd	s5,72(sp)
    800005b0:	e0da                	sd	s6,64(sp)
    800005b2:	fc5e                	sd	s7,56(sp)
    800005b4:	f862                	sd	s8,48(sp)
    800005b6:	f466                	sd	s9,40(sp)
    800005b8:	f06a                	sd	s10,32(sp)
    800005ba:	ec6e                	sd	s11,24(sp)
    800005bc:	0100                	addi	s0,sp,128
    800005be:	8a2a                	mv	s4,a0
    800005c0:	e40c                	sd	a1,8(s0)
    800005c2:	e810                	sd	a2,16(s0)
    800005c4:	ec14                	sd	a3,24(s0)
    800005c6:	f018                	sd	a4,32(s0)
    800005c8:	f41c                	sd	a5,40(s0)
    800005ca:	03043823          	sd	a6,48(s0)
    800005ce:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005d2:	00011d97          	auipc	s11,0x11
    800005d6:	31edad83          	lw	s11,798(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005da:	020d9b63          	bnez	s11,80000610 <printf+0x70>
  if (fmt == 0)
    800005de:	040a0263          	beqz	s4,80000622 <printf+0x82>
  va_start(ap, fmt);
    800005e2:	00840793          	addi	a5,s0,8
    800005e6:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ea:	000a4503          	lbu	a0,0(s4)
    800005ee:	16050263          	beqz	a0,80000752 <printf+0x1b2>
    800005f2:	4481                	li	s1,0
    if(c != '%'){
    800005f4:	02500a93          	li	s5,37
    switch(c){
    800005f8:	07000b13          	li	s6,112
  consputc('x');
    800005fc:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fe:	00008b97          	auipc	s7,0x8
    80000602:	a42b8b93          	addi	s7,s7,-1470 # 80008040 <digits>
    switch(c){
    80000606:	07300c93          	li	s9,115
    8000060a:	06400c13          	li	s8,100
    8000060e:	a82d                	j	80000648 <printf+0xa8>
    acquire(&pr.lock);
    80000610:	00011517          	auipc	a0,0x11
    80000614:	2c850513          	addi	a0,a0,712 # 800118d8 <pr>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	606080e7          	jalr	1542(ra) # 80000c1e <acquire>
    80000620:	bf7d                	j	800005de <printf+0x3e>
    panic("null fmt");
    80000622:	00008517          	auipc	a0,0x8
    80000626:	a0650513          	addi	a0,a0,-1530 # 80008028 <etext+0x28>
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	f2c080e7          	jalr	-212(ra) # 80000556 <panic>
      consputc(c);
    80000632:	00000097          	auipc	ra,0x0
    80000636:	c62080e7          	jalr	-926(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c503          	lbu	a0,0(a5)
    80000644:	10050763          	beqz	a0,80000752 <printf+0x1b2>
    if(c != '%'){
    80000648:	ff5515e3          	bne	a0,s5,80000632 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000064c:	2485                	addiw	s1,s1,1
    8000064e:	009a07b3          	add	a5,s4,s1
    80000652:	0007c783          	lbu	a5,0(a5)
    80000656:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000065a:	cfe5                	beqz	a5,80000752 <printf+0x1b2>
    switch(c){
    8000065c:	05678a63          	beq	a5,s6,800006b0 <printf+0x110>
    80000660:	02fb7663          	bgeu	s6,a5,8000068c <printf+0xec>
    80000664:	09978963          	beq	a5,s9,800006f6 <printf+0x156>
    80000668:	07800713          	li	a4,120
    8000066c:	0ce79863          	bne	a5,a4,8000073c <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000670:	f8843783          	ld	a5,-120(s0)
    80000674:	00878713          	addi	a4,a5,8
    80000678:	f8e43423          	sd	a4,-120(s0)
    8000067c:	4605                	li	a2,1
    8000067e:	85ea                	mv	a1,s10
    80000680:	4388                	lw	a0,0(a5)
    80000682:	00000097          	auipc	ra,0x0
    80000686:	e32080e7          	jalr	-462(ra) # 800004b4 <printint>
      break;
    8000068a:	bf45                	j	8000063a <printf+0x9a>
    switch(c){
    8000068c:	0b578263          	beq	a5,s5,80000730 <printf+0x190>
    80000690:	0b879663          	bne	a5,s8,8000073c <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	4605                	li	a2,1
    800006a2:	45a9                	li	a1,10
    800006a4:	4388                	lw	a0,0(a5)
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	e0e080e7          	jalr	-498(ra) # 800004b4 <printint>
      break;
    800006ae:	b771                	j	8000063a <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006b0:	f8843783          	ld	a5,-120(s0)
    800006b4:	00878713          	addi	a4,a5,8
    800006b8:	f8e43423          	sd	a4,-120(s0)
    800006bc:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006c0:	03000513          	li	a0,48
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bd0080e7          	jalr	-1072(ra) # 80000294 <consputc>
  consputc('x');
    800006cc:	07800513          	li	a0,120
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bc4080e7          	jalr	-1084(ra) # 80000294 <consputc>
    800006d8:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006da:	03c9d793          	srli	a5,s3,0x3c
    800006de:	97de                	add	a5,a5,s7
    800006e0:	0007c503          	lbu	a0,0(a5)
    800006e4:	00000097          	auipc	ra,0x0
    800006e8:	bb0080e7          	jalr	-1104(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ec:	0992                	slli	s3,s3,0x4
    800006ee:	397d                	addiw	s2,s2,-1
    800006f0:	fe0915e3          	bnez	s2,800006da <printf+0x13a>
    800006f4:	b799                	j	8000063a <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f6:	f8843783          	ld	a5,-120(s0)
    800006fa:	00878713          	addi	a4,a5,8
    800006fe:	f8e43423          	sd	a4,-120(s0)
    80000702:	0007b903          	ld	s2,0(a5)
    80000706:	00090e63          	beqz	s2,80000722 <printf+0x182>
      for(; *s; s++)
    8000070a:	00094503          	lbu	a0,0(s2)
    8000070e:	d515                	beqz	a0,8000063a <printf+0x9a>
        consputc(*s);
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b84080e7          	jalr	-1148(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000718:	0905                	addi	s2,s2,1
    8000071a:	00094503          	lbu	a0,0(s2)
    8000071e:	f96d                	bnez	a0,80000710 <printf+0x170>
    80000720:	bf29                	j	8000063a <printf+0x9a>
        s = "(null)";
    80000722:	00008917          	auipc	s2,0x8
    80000726:	8fe90913          	addi	s2,s2,-1794 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000072a:	02800513          	li	a0,40
    8000072e:	b7cd                	j	80000710 <printf+0x170>
      consputc('%');
    80000730:	8556                	mv	a0,s5
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b62080e7          	jalr	-1182(ra) # 80000294 <consputc>
      break;
    8000073a:	b701                	j	8000063a <printf+0x9a>
      consputc('%');
    8000073c:	8556                	mv	a0,s5
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b56080e7          	jalr	-1194(ra) # 80000294 <consputc>
      consputc(c);
    80000746:	854a                	mv	a0,s2
    80000748:	00000097          	auipc	ra,0x0
    8000074c:	b4c080e7          	jalr	-1204(ra) # 80000294 <consputc>
      break;
    80000750:	b5ed                	j	8000063a <printf+0x9a>
  if(locking)
    80000752:	020d9163          	bnez	s11,80000774 <printf+0x1d4>
}
    80000756:	70e6                	ld	ra,120(sp)
    80000758:	7446                	ld	s0,112(sp)
    8000075a:	74a6                	ld	s1,104(sp)
    8000075c:	7906                	ld	s2,96(sp)
    8000075e:	69e6                	ld	s3,88(sp)
    80000760:	6a46                	ld	s4,80(sp)
    80000762:	6aa6                	ld	s5,72(sp)
    80000764:	6b06                	ld	s6,64(sp)
    80000766:	7be2                	ld	s7,56(sp)
    80000768:	7c42                	ld	s8,48(sp)
    8000076a:	7ca2                	ld	s9,40(sp)
    8000076c:	7d02                	ld	s10,32(sp)
    8000076e:	6de2                	ld	s11,24(sp)
    80000770:	6129                	addi	sp,sp,192
    80000772:	8082                	ret
    release(&pr.lock);
    80000774:	00011517          	auipc	a0,0x11
    80000778:	16450513          	addi	a0,a0,356 # 800118d8 <pr>
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	556080e7          	jalr	1366(ra) # 80000cd2 <release>
}
    80000784:	bfc9                	j	80000756 <printf+0x1b6>

0000000080000786 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000786:	1101                	addi	sp,sp,-32
    80000788:	ec06                	sd	ra,24(sp)
    8000078a:	e822                	sd	s0,16(sp)
    8000078c:	e426                	sd	s1,8(sp)
    8000078e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000790:	00011497          	auipc	s1,0x11
    80000794:	14848493          	addi	s1,s1,328 # 800118d8 <pr>
    80000798:	00008597          	auipc	a1,0x8
    8000079c:	8a058593          	addi	a1,a1,-1888 # 80008038 <etext+0x38>
    800007a0:	8526                	mv	a0,s1
    800007a2:	00000097          	auipc	ra,0x0
    800007a6:	3ec080e7          	jalr	1004(ra) # 80000b8e <initlock>
  pr.locking = 1;
    800007aa:	4785                	li	a5,1
    800007ac:	cc9c                	sw	a5,24(s1)
}
    800007ae:	60e2                	ld	ra,24(sp)
    800007b0:	6442                	ld	s0,16(sp)
    800007b2:	64a2                	ld	s1,8(sp)
    800007b4:	6105                	addi	sp,sp,32
    800007b6:	8082                	ret

00000000800007b8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b8:	1141                	addi	sp,sp,-16
    800007ba:	e406                	sd	ra,8(sp)
    800007bc:	e022                	sd	s0,0(sp)
    800007be:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007c0:	100007b7          	lui	a5,0x10000
    800007c4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c8:	f8000713          	li	a4,-128
    800007cc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007d0:	470d                	li	a4,3
    800007d2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007da:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007de:	469d                	li	a3,7
    800007e0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007e4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e8:	00008597          	auipc	a1,0x8
    800007ec:	87058593          	addi	a1,a1,-1936 # 80008058 <digits+0x18>
    800007f0:	00011517          	auipc	a0,0x11
    800007f4:	10850513          	addi	a0,a0,264 # 800118f8 <uart_tx_lock>
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	396080e7          	jalr	918(ra) # 80000b8e <initlock>
}
    80000800:	60a2                	ld	ra,8(sp)
    80000802:	6402                	ld	s0,0(sp)
    80000804:	0141                	addi	sp,sp,16
    80000806:	8082                	ret

0000000080000808 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000808:	1101                	addi	sp,sp,-32
    8000080a:	ec06                	sd	ra,24(sp)
    8000080c:	e822                	sd	s0,16(sp)
    8000080e:	e426                	sd	s1,8(sp)
    80000810:	1000                	addi	s0,sp,32
    80000812:	84aa                	mv	s1,a0
  push_off();
    80000814:	00000097          	auipc	ra,0x0
    80000818:	3be080e7          	jalr	958(ra) # 80000bd2 <push_off>

  if(panicked){
    8000081c:	00008797          	auipc	a5,0x8
    80000820:	7e47a783          	lw	a5,2020(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000824:	10000737          	lui	a4,0x10000
  if(panicked){
    80000828:	c391                	beqz	a5,8000082c <uartputc_sync+0x24>
    for(;;)
    8000082a:	a001                	j	8000082a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000082c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000830:	0ff7f793          	andi	a5,a5,255
    80000834:	0207f793          	andi	a5,a5,32
    80000838:	dbf5                	beqz	a5,8000082c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000083a:	0ff4f793          	andi	a5,s1,255
    8000083e:	10000737          	lui	a4,0x10000
    80000842:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	42c080e7          	jalr	1068(ra) # 80000c72 <pop_off>
}
    8000084e:	60e2                	ld	ra,24(sp)
    80000850:	6442                	ld	s0,16(sp)
    80000852:	64a2                	ld	s1,8(sp)
    80000854:	6105                	addi	sp,sp,32
    80000856:	8082                	ret

0000000080000858 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000858:	00008797          	auipc	a5,0x8
    8000085c:	7ac7a783          	lw	a5,1964(a5) # 80009004 <uart_tx_r>
    80000860:	00008717          	auipc	a4,0x8
    80000864:	7a872703          	lw	a4,1960(a4) # 80009008 <uart_tx_w>
    80000868:	08f70263          	beq	a4,a5,800008ec <uartstart+0x94>
{
    8000086c:	7139                	addi	sp,sp,-64
    8000086e:	fc06                	sd	ra,56(sp)
    80000870:	f822                	sd	s0,48(sp)
    80000872:	f426                	sd	s1,40(sp)
    80000874:	f04a                	sd	s2,32(sp)
    80000876:	ec4e                	sd	s3,24(sp)
    80000878:	e852                	sd	s4,16(sp)
    8000087a:	e456                	sd	s5,8(sp)
    8000087c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000882:	00011a17          	auipc	s4,0x11
    80000886:	076a0a13          	addi	s4,s4,118 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088a:	00008497          	auipc	s1,0x8
    8000088e:	77a48493          	addi	s1,s1,1914 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000892:	00008997          	auipc	s3,0x8
    80000896:	77698993          	addi	s3,s3,1910 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000089a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000089e:	0ff77713          	andi	a4,a4,255
    800008a2:	02077713          	andi	a4,a4,32
    800008a6:	cb15                	beqz	a4,800008da <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a8:	00fa0733          	add	a4,s4,a5
    800008ac:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008b0:	2785                	addiw	a5,a5,1
    800008b2:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b6:	01b7571b          	srliw	a4,a4,0x1b
    800008ba:	9fb9                	addw	a5,a5,a4
    800008bc:	8bfd                	andi	a5,a5,31
    800008be:	9f99                	subw	a5,a5,a4
    800008c0:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008c2:	8526                	mv	a0,s1
    800008c4:	00002097          	auipc	ra,0x2
    800008c8:	c98080e7          	jalr	-872(ra) # 8000255c <wakeup>
    
    WriteReg(THR, c);
    800008cc:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008d0:	409c                	lw	a5,0(s1)
    800008d2:	0009a703          	lw	a4,0(s3)
    800008d6:	fcf712e3          	bne	a4,a5,8000089a <uartstart+0x42>
  }
}
    800008da:	70e2                	ld	ra,56(sp)
    800008dc:	7442                	ld	s0,48(sp)
    800008de:	74a2                	ld	s1,40(sp)
    800008e0:	7902                	ld	s2,32(sp)
    800008e2:	69e2                	ld	s3,24(sp)
    800008e4:	6a42                	ld	s4,16(sp)
    800008e6:	6aa2                	ld	s5,8(sp)
    800008e8:	6121                	addi	sp,sp,64
    800008ea:	8082                	ret
    800008ec:	8082                	ret

00000000800008ee <uartputc>:
{
    800008ee:	7179                	addi	sp,sp,-48
    800008f0:	f406                	sd	ra,40(sp)
    800008f2:	f022                	sd	s0,32(sp)
    800008f4:	ec26                	sd	s1,24(sp)
    800008f6:	e84a                	sd	s2,16(sp)
    800008f8:	e44e                	sd	s3,8(sp)
    800008fa:	e052                	sd	s4,0(sp)
    800008fc:	1800                	addi	s0,sp,48
    800008fe:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000900:	00011517          	auipc	a0,0x11
    80000904:	ff850513          	addi	a0,a0,-8 # 800118f8 <uart_tx_lock>
    80000908:	00000097          	auipc	ra,0x0
    8000090c:	316080e7          	jalr	790(ra) # 80000c1e <acquire>
  if(panicked){
    80000910:	00008797          	auipc	a5,0x8
    80000914:	6f07a783          	lw	a5,1776(a5) # 80009000 <panicked>
    80000918:	c391                	beqz	a5,8000091c <uartputc+0x2e>
    for(;;)
    8000091a:	a001                	j	8000091a <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000091c:	00008717          	auipc	a4,0x8
    80000920:	6ec72703          	lw	a4,1772(a4) # 80009008 <uart_tx_w>
    80000924:	0017079b          	addiw	a5,a4,1
    80000928:	41f7d69b          	sraiw	a3,a5,0x1f
    8000092c:	01b6d69b          	srliw	a3,a3,0x1b
    80000930:	9fb5                	addw	a5,a5,a3
    80000932:	8bfd                	andi	a5,a5,31
    80000934:	9f95                	subw	a5,a5,a3
    80000936:	00008697          	auipc	a3,0x8
    8000093a:	6ce6a683          	lw	a3,1742(a3) # 80009004 <uart_tx_r>
    8000093e:	04f69263          	bne	a3,a5,80000982 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000942:	00011a17          	auipc	s4,0x11
    80000946:	fb6a0a13          	addi	s4,s4,-74 # 800118f8 <uart_tx_lock>
    8000094a:	00008497          	auipc	s1,0x8
    8000094e:	6ba48493          	addi	s1,s1,1722 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000952:	00008917          	auipc	s2,0x8
    80000956:	6b690913          	addi	s2,s2,1718 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000095a:	85d2                	mv	a1,s4
    8000095c:	8526                	mv	a0,s1
    8000095e:	00002097          	auipc	ra,0x2
    80000962:	a78080e7          	jalr	-1416(ra) # 800023d6 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000966:	00092703          	lw	a4,0(s2)
    8000096a:	0017079b          	addiw	a5,a4,1
    8000096e:	41f7d69b          	sraiw	a3,a5,0x1f
    80000972:	01b6d69b          	srliw	a3,a3,0x1b
    80000976:	9fb5                	addw	a5,a5,a3
    80000978:	8bfd                	andi	a5,a5,31
    8000097a:	9f95                	subw	a5,a5,a3
    8000097c:	4094                	lw	a3,0(s1)
    8000097e:	fcf68ee3          	beq	a3,a5,8000095a <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000982:	00011497          	auipc	s1,0x11
    80000986:	f7648493          	addi	s1,s1,-138 # 800118f8 <uart_tx_lock>
    8000098a:	9726                	add	a4,a4,s1
    8000098c:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000990:	00008717          	auipc	a4,0x8
    80000994:	66f72c23          	sw	a5,1656(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000998:	00000097          	auipc	ra,0x0
    8000099c:	ec0080e7          	jalr	-320(ra) # 80000858 <uartstart>
      release(&uart_tx_lock);
    800009a0:	8526                	mv	a0,s1
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	330080e7          	jalr	816(ra) # 80000cd2 <release>
}
    800009aa:	70a2                	ld	ra,40(sp)
    800009ac:	7402                	ld	s0,32(sp)
    800009ae:	64e2                	ld	s1,24(sp)
    800009b0:	6942                	ld	s2,16(sp)
    800009b2:	69a2                	ld	s3,8(sp)
    800009b4:	6a02                	ld	s4,0(sp)
    800009b6:	6145                	addi	sp,sp,48
    800009b8:	8082                	ret

00000000800009ba <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ba:	1141                	addi	sp,sp,-16
    800009bc:	e422                	sd	s0,8(sp)
    800009be:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009c0:	100007b7          	lui	a5,0x10000
    800009c4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c8:	8b85                	andi	a5,a5,1
    800009ca:	cb91                	beqz	a5,800009de <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009cc:	100007b7          	lui	a5,0x10000
    800009d0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009d4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d8:	6422                	ld	s0,8(sp)
    800009da:	0141                	addi	sp,sp,16
    800009dc:	8082                	ret
    return -1;
    800009de:	557d                	li	a0,-1
    800009e0:	bfe5                	j	800009d8 <uartgetc+0x1e>

00000000800009e2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	fcc080e7          	jalr	-52(ra) # 800009ba <uartgetc>
    if(c == -1)
    800009f6:	00950763          	beq	a0,s1,80000a04 <uartintr+0x22>
      break;
    consoleintr(c);
    800009fa:	00000097          	auipc	ra,0x0
    800009fe:	8dc080e7          	jalr	-1828(ra) # 800002d6 <consoleintr>
  while(1){
    80000a02:	b7f5                	j	800009ee <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a04:	00011497          	auipc	s1,0x11
    80000a08:	ef448493          	addi	s1,s1,-268 # 800118f8 <uart_tx_lock>
    80000a0c:	8526                	mv	a0,s1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	210080e7          	jalr	528(ra) # 80000c1e <acquire>
  uartstart();
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	e42080e7          	jalr	-446(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    80000a1e:	8526                	mv	a0,s1
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	2b2080e7          	jalr	690(ra) # 80000cd2 <release>
}
    80000a28:	60e2                	ld	ra,24(sp)
    80000a2a:	6442                	ld	s0,16(sp)
    80000a2c:	64a2                	ld	s1,8(sp)
    80000a2e:	6105                	addi	sp,sp,32
    80000a30:	8082                	ret

0000000080000a32 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a32:	1101                	addi	sp,sp,-32
    80000a34:	ec06                	sd	ra,24(sp)
    80000a36:	e822                	sd	s0,16(sp)
    80000a38:	e426                	sd	s1,8(sp)
    80000a3a:	e04a                	sd	s2,0(sp)
    80000a3c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	ebb9                	bnez	a5,80000a98 <kfree+0x66>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	00025797          	auipc	a5,0x25
    80000a4a:	5ba78793          	addi	a5,a5,1466 # 80026000 <end>
    80000a4e:	04f56563          	bltu	a0,a5,80000a98 <kfree+0x66>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	04f57163          	bgeu	a0,a5,80000a98 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	2bc080e7          	jalr	700(ra) # 80000d1a <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a66:	00011917          	auipc	s2,0x11
    80000a6a:	eca90913          	addi	s2,s2,-310 # 80011930 <kmem>
    80000a6e:	854a                	mv	a0,s2
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	1ae080e7          	jalr	430(ra) # 80000c1e <acquire>
  r->next = kmem.freelist;
    80000a78:	01893783          	ld	a5,24(s2)
    80000a7c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a7e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a82:	854a                	mv	a0,s2
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	24e080e7          	jalr	590(ra) # 80000cd2 <release>
}
    80000a8c:	60e2                	ld	ra,24(sp)
    80000a8e:	6442                	ld	s0,16(sp)
    80000a90:	64a2                	ld	s1,8(sp)
    80000a92:	6902                	ld	s2,0(sp)
    80000a94:	6105                	addi	sp,sp,32
    80000a96:	8082                	ret
    panic("kfree");
    80000a98:	00007517          	auipc	a0,0x7
    80000a9c:	5c850513          	addi	a0,a0,1480 # 80008060 <digits+0x20>
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	ab6080e7          	jalr	-1354(ra) # 80000556 <panic>

0000000080000aa8 <freerange>:
{
    80000aa8:	7179                	addi	sp,sp,-48
    80000aaa:	f406                	sd	ra,40(sp)
    80000aac:	f022                	sd	s0,32(sp)
    80000aae:	ec26                	sd	s1,24(sp)
    80000ab0:	e84a                	sd	s2,16(sp)
    80000ab2:	e44e                	sd	s3,8(sp)
    80000ab4:	e052                	sd	s4,0(sp)
    80000ab6:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ab8:	6785                	lui	a5,0x1
    80000aba:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000abe:	94aa                	add	s1,s1,a0
    80000ac0:	757d                	lui	a0,0xfffff
    80000ac2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac4:	94be                	add	s1,s1,a5
    80000ac6:	0095ee63          	bltu	a1,s1,80000ae2 <freerange+0x3a>
    80000aca:	892e                	mv	s2,a1
    kfree(p);
    80000acc:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	6985                	lui	s3,0x1
    kfree(p);
    80000ad0:	01448533          	add	a0,s1,s4
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	f5e080e7          	jalr	-162(ra) # 80000a32 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000adc:	94ce                	add	s1,s1,s3
    80000ade:	fe9979e3          	bgeu	s2,s1,80000ad0 <freerange+0x28>
}
    80000ae2:	70a2                	ld	ra,40(sp)
    80000ae4:	7402                	ld	s0,32(sp)
    80000ae6:	64e2                	ld	s1,24(sp)
    80000ae8:	6942                	ld	s2,16(sp)
    80000aea:	69a2                	ld	s3,8(sp)
    80000aec:	6a02                	ld	s4,0(sp)
    80000aee:	6145                	addi	sp,sp,48
    80000af0:	8082                	ret

0000000080000af2 <kinit>:
{
    80000af2:	1141                	addi	sp,sp,-16
    80000af4:	e406                	sd	ra,8(sp)
    80000af6:	e022                	sd	s0,0(sp)
    80000af8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000afa:	00007597          	auipc	a1,0x7
    80000afe:	56e58593          	addi	a1,a1,1390 # 80008068 <digits+0x28>
    80000b02:	00011517          	auipc	a0,0x11
    80000b06:	e2e50513          	addi	a0,a0,-466 # 80011930 <kmem>
    80000b0a:	00000097          	auipc	ra,0x0
    80000b0e:	084080e7          	jalr	132(ra) # 80000b8e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b12:	45c5                	li	a1,17
    80000b14:	05ee                	slli	a1,a1,0x1b
    80000b16:	00025517          	auipc	a0,0x25
    80000b1a:	4ea50513          	addi	a0,a0,1258 # 80026000 <end>
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	f8a080e7          	jalr	-118(ra) # 80000aa8 <freerange>
}
    80000b26:	60a2                	ld	ra,8(sp)
    80000b28:	6402                	ld	s0,0(sp)
    80000b2a:	0141                	addi	sp,sp,16
    80000b2c:	8082                	ret

0000000080000b2e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b2e:	1101                	addi	sp,sp,-32
    80000b30:	ec06                	sd	ra,24(sp)
    80000b32:	e822                	sd	s0,16(sp)
    80000b34:	e426                	sd	s1,8(sp)
    80000b36:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b38:	00011497          	auipc	s1,0x11
    80000b3c:	df848493          	addi	s1,s1,-520 # 80011930 <kmem>
    80000b40:	8526                	mv	a0,s1
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	0dc080e7          	jalr	220(ra) # 80000c1e <acquire>
  r = kmem.freelist;
    80000b4a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b4c:	c885                	beqz	s1,80000b7c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b4e:	609c                	ld	a5,0(s1)
    80000b50:	00011517          	auipc	a0,0x11
    80000b54:	de050513          	addi	a0,a0,-544 # 80011930 <kmem>
    80000b58:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	178080e7          	jalr	376(ra) # 80000cd2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b62:	6605                	lui	a2,0x1
    80000b64:	4595                	li	a1,5
    80000b66:	8526                	mv	a0,s1
    80000b68:	00000097          	auipc	ra,0x0
    80000b6c:	1b2080e7          	jalr	434(ra) # 80000d1a <memset>
  return (void*)r;
}
    80000b70:	8526                	mv	a0,s1
    80000b72:	60e2                	ld	ra,24(sp)
    80000b74:	6442                	ld	s0,16(sp)
    80000b76:	64a2                	ld	s1,8(sp)
    80000b78:	6105                	addi	sp,sp,32
    80000b7a:	8082                	ret
  release(&kmem.lock);
    80000b7c:	00011517          	auipc	a0,0x11
    80000b80:	db450513          	addi	a0,a0,-588 # 80011930 <kmem>
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	14e080e7          	jalr	334(ra) # 80000cd2 <release>
  if(r)
    80000b8c:	b7d5                	j	80000b70 <kalloc+0x42>

0000000080000b8e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b8e:	1141                	addi	sp,sp,-16
    80000b90:	e422                	sd	s0,8(sp)
    80000b92:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b94:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b96:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9a:	00053823          	sd	zero,16(a0)
}
    80000b9e:	6422                	ld	s0,8(sp)
    80000ba0:	0141                	addi	sp,sp,16
    80000ba2:	8082                	ret

0000000080000ba4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba4:	411c                	lw	a5,0(a0)
    80000ba6:	e399                	bnez	a5,80000bac <holding+0x8>
    80000ba8:	4501                	li	a0,0
  return r;
}
    80000baa:	8082                	ret
{
    80000bac:	1101                	addi	sp,sp,-32
    80000bae:	ec06                	sd	ra,24(sp)
    80000bb0:	e822                	sd	s0,16(sp)
    80000bb2:	e426                	sd	s1,8(sp)
    80000bb4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb6:	6904                	ld	s1,16(a0)
    80000bb8:	00001097          	auipc	ra,0x1
    80000bbc:	ff2080e7          	jalr	-14(ra) # 80001baa <mycpu>
    80000bc0:	40a48533          	sub	a0,s1,a0
    80000bc4:	00153513          	seqz	a0,a0
}
    80000bc8:	60e2                	ld	ra,24(sp)
    80000bca:	6442                	ld	s0,16(sp)
    80000bcc:	64a2                	ld	s1,8(sp)
    80000bce:	6105                	addi	sp,sp,32
    80000bd0:	8082                	ret

0000000080000bd2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bdc:	100024f3          	csrr	s1,sstatus
    80000be0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bea:	00001097          	auipc	ra,0x1
    80000bee:	fc0080e7          	jalr	-64(ra) # 80001baa <mycpu>
    80000bf2:	5d3c                	lw	a5,120(a0)
    80000bf4:	cf89                	beqz	a5,80000c0e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf6:	00001097          	auipc	ra,0x1
    80000bfa:	fb4080e7          	jalr	-76(ra) # 80001baa <mycpu>
    80000bfe:	5d3c                	lw	a5,120(a0)
    80000c00:	2785                	addiw	a5,a5,1
    80000c02:	dd3c                	sw	a5,120(a0)
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret
    mycpu()->intena = old;
    80000c0e:	00001097          	auipc	ra,0x1
    80000c12:	f9c080e7          	jalr	-100(ra) # 80001baa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c16:	8085                	srli	s1,s1,0x1
    80000c18:	8885                	andi	s1,s1,1
    80000c1a:	dd64                	sw	s1,124(a0)
    80000c1c:	bfe9                	j	80000bf6 <push_off+0x24>

0000000080000c1e <acquire>:
{
    80000c1e:	1101                	addi	sp,sp,-32
    80000c20:	ec06                	sd	ra,24(sp)
    80000c22:	e822                	sd	s0,16(sp)
    80000c24:	e426                	sd	s1,8(sp)
    80000c26:	1000                	addi	s0,sp,32
    80000c28:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	fa8080e7          	jalr	-88(ra) # 80000bd2 <push_off>
  if(holding(lk))
    80000c32:	8526                	mv	a0,s1
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	f70080e7          	jalr	-144(ra) # 80000ba4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3c:	4705                	li	a4,1
  if(holding(lk))
    80000c3e:	e115                	bnez	a0,80000c62 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c40:	87ba                	mv	a5,a4
    80000c42:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c46:	2781                	sext.w	a5,a5
    80000c48:	ffe5                	bnez	a5,80000c40 <acquire+0x22>
  __sync_synchronize();
    80000c4a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c4e:	00001097          	auipc	ra,0x1
    80000c52:	f5c080e7          	jalr	-164(ra) # 80001baa <mycpu>
    80000c56:	e888                	sd	a0,16(s1)
}
    80000c58:	60e2                	ld	ra,24(sp)
    80000c5a:	6442                	ld	s0,16(sp)
    80000c5c:	64a2                	ld	s1,8(sp)
    80000c5e:	6105                	addi	sp,sp,32
    80000c60:	8082                	ret
    panic("acquire");
    80000c62:	00007517          	auipc	a0,0x7
    80000c66:	40e50513          	addi	a0,a0,1038 # 80008070 <digits+0x30>
    80000c6a:	00000097          	auipc	ra,0x0
    80000c6e:	8ec080e7          	jalr	-1812(ra) # 80000556 <panic>

0000000080000c72 <pop_off>:

void
pop_off(void)
{
    80000c72:	1141                	addi	sp,sp,-16
    80000c74:	e406                	sd	ra,8(sp)
    80000c76:	e022                	sd	s0,0(sp)
    80000c78:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7a:	00001097          	auipc	ra,0x1
    80000c7e:	f30080e7          	jalr	-208(ra) # 80001baa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c82:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c86:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c88:	e78d                	bnez	a5,80000cb2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8a:	5d3c                	lw	a5,120(a0)
    80000c8c:	02f05b63          	blez	a5,80000cc2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c90:	37fd                	addiw	a5,a5,-1
    80000c92:	0007871b          	sext.w	a4,a5
    80000c96:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c98:	eb09                	bnez	a4,80000caa <pop_off+0x38>
    80000c9a:	5d7c                	lw	a5,124(a0)
    80000c9c:	c799                	beqz	a5,80000caa <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000caa:	60a2                	ld	ra,8(sp)
    80000cac:	6402                	ld	s0,0(sp)
    80000cae:	0141                	addi	sp,sp,16
    80000cb0:	8082                	ret
    panic("pop_off - interruptible");
    80000cb2:	00007517          	auipc	a0,0x7
    80000cb6:	3c650513          	addi	a0,a0,966 # 80008078 <digits+0x38>
    80000cba:	00000097          	auipc	ra,0x0
    80000cbe:	89c080e7          	jalr	-1892(ra) # 80000556 <panic>
    panic("pop_off");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3ce50513          	addi	a0,a0,974 # 80008090 <digits+0x50>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	88c080e7          	jalr	-1908(ra) # 80000556 <panic>

0000000080000cd2 <release>:
{
    80000cd2:	1101                	addi	sp,sp,-32
    80000cd4:	ec06                	sd	ra,24(sp)
    80000cd6:	e822                	sd	s0,16(sp)
    80000cd8:	e426                	sd	s1,8(sp)
    80000cda:	1000                	addi	s0,sp,32
    80000cdc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	ec6080e7          	jalr	-314(ra) # 80000ba4 <holding>
    80000ce6:	c115                	beqz	a0,80000d0a <release+0x38>
  lk->cpu = 0;
    80000ce8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cec:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf0:	0f50000f          	fence	iorw,ow
    80000cf4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	f7a080e7          	jalr	-134(ra) # 80000c72 <pop_off>
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret
    panic("release");
    80000d0a:	00007517          	auipc	a0,0x7
    80000d0e:	38e50513          	addi	a0,a0,910 # 80008098 <digits+0x58>
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	844080e7          	jalr	-1980(ra) # 80000556 <panic>

0000000080000d1a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d20:	ce09                	beqz	a2,80000d3a <memset+0x20>
    80000d22:	87aa                	mv	a5,a0
    80000d24:	fff6071b          	addiw	a4,a2,-1
    80000d28:	1702                	slli	a4,a4,0x20
    80000d2a:	9301                	srli	a4,a4,0x20
    80000d2c:	0705                	addi	a4,a4,1
    80000d2e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d30:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d34:	0785                	addi	a5,a5,1
    80000d36:	fee79de3          	bne	a5,a4,80000d30 <memset+0x16>
  }
  return dst;
}
    80000d3a:	6422                	ld	s0,8(sp)
    80000d3c:	0141                	addi	sp,sp,16
    80000d3e:	8082                	ret

0000000080000d40 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d46:	ca05                	beqz	a2,80000d76 <memcmp+0x36>
    80000d48:	fff6069b          	addiw	a3,a2,-1
    80000d4c:	1682                	slli	a3,a3,0x20
    80000d4e:	9281                	srli	a3,a3,0x20
    80000d50:	0685                	addi	a3,a3,1
    80000d52:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d54:	00054783          	lbu	a5,0(a0)
    80000d58:	0005c703          	lbu	a4,0(a1)
    80000d5c:	00e79863          	bne	a5,a4,80000d6c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d60:	0505                	addi	a0,a0,1
    80000d62:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d64:	fed518e3          	bne	a0,a3,80000d54 <memcmp+0x14>
  }

  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	a019                	j	80000d70 <memcmp+0x30>
      return *s1 - *s2;
    80000d6c:	40e7853b          	subw	a0,a5,a4
}
    80000d70:	6422                	ld	s0,8(sp)
    80000d72:	0141                	addi	sp,sp,16
    80000d74:	8082                	ret
  return 0;
    80000d76:	4501                	li	a0,0
    80000d78:	bfe5                	j	80000d70 <memcmp+0x30>

0000000080000d7a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d7a:	1141                	addi	sp,sp,-16
    80000d7c:	e422                	sd	s0,8(sp)
    80000d7e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d80:	00a5f963          	bgeu	a1,a0,80000d92 <memmove+0x18>
    80000d84:	02061713          	slli	a4,a2,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	02f56563          	bltu	a0,a5,80000db8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d92:	fff6069b          	addiw	a3,a2,-1
    80000d96:	ce11                	beqz	a2,80000db2 <memmove+0x38>
    80000d98:	1682                	slli	a3,a3,0x20
    80000d9a:	9281                	srli	a3,a3,0x20
    80000d9c:	0685                	addi	a3,a3,1
    80000d9e:	96ae                	add	a3,a3,a1
    80000da0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000da2:	0585                	addi	a1,a1,1
    80000da4:	0785                	addi	a5,a5,1
    80000da6:	fff5c703          	lbu	a4,-1(a1)
    80000daa:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dae:	fed59ae3          	bne	a1,a3,80000da2 <memmove+0x28>

  return dst;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret
    d += n;
    80000db8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dba:	fff6069b          	addiw	a3,a2,-1
    80000dbe:	da75                	beqz	a2,80000db2 <memmove+0x38>
    80000dc0:	02069613          	slli	a2,a3,0x20
    80000dc4:	9201                	srli	a2,a2,0x20
    80000dc6:	fff64613          	not	a2,a2
    80000dca:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dcc:	17fd                	addi	a5,a5,-1
    80000dce:	177d                	addi	a4,a4,-1
    80000dd0:	0007c683          	lbu	a3,0(a5)
    80000dd4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dd8:	fec79ae3          	bne	a5,a2,80000dcc <memmove+0x52>
    80000ddc:	bfd9                	j	80000db2 <memmove+0x38>

0000000080000dde <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e406                	sd	ra,8(sp)
    80000de2:	e022                	sd	s0,0(sp)
    80000de4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	f94080e7          	jalr	-108(ra) # 80000d7a <memmove>
}
    80000dee:	60a2                	ld	ra,8(sp)
    80000df0:	6402                	ld	s0,0(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret

0000000080000df6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dfc:	ce11                	beqz	a2,80000e18 <strncmp+0x22>
    80000dfe:	00054783          	lbu	a5,0(a0)
    80000e02:	cf89                	beqz	a5,80000e1c <strncmp+0x26>
    80000e04:	0005c703          	lbu	a4,0(a1)
    80000e08:	00f71a63          	bne	a4,a5,80000e1c <strncmp+0x26>
    n--, p++, q++;
    80000e0c:	367d                	addiw	a2,a2,-1
    80000e0e:	0505                	addi	a0,a0,1
    80000e10:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e12:	f675                	bnez	a2,80000dfe <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e14:	4501                	li	a0,0
    80000e16:	a809                	j	80000e28 <strncmp+0x32>
    80000e18:	4501                	li	a0,0
    80000e1a:	a039                	j	80000e28 <strncmp+0x32>
  if(n == 0)
    80000e1c:	ca09                	beqz	a2,80000e2e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e1e:	00054503          	lbu	a0,0(a0)
    80000e22:	0005c783          	lbu	a5,0(a1)
    80000e26:	9d1d                	subw	a0,a0,a5
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret
    return 0;
    80000e2e:	4501                	li	a0,0
    80000e30:	bfe5                	j	80000e28 <strncmp+0x32>

0000000080000e32 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e38:	872a                	mv	a4,a0
    80000e3a:	8832                	mv	a6,a2
    80000e3c:	367d                	addiw	a2,a2,-1
    80000e3e:	01005963          	blez	a6,80000e50 <strncpy+0x1e>
    80000e42:	0705                	addi	a4,a4,1
    80000e44:	0005c783          	lbu	a5,0(a1)
    80000e48:	fef70fa3          	sb	a5,-1(a4)
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	f7f5                	bnez	a5,80000e3a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e50:	00c05d63          	blez	a2,80000e6a <strncpy+0x38>
    80000e54:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e56:	0685                	addi	a3,a3,1
    80000e58:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e5c:	fff6c793          	not	a5,a3
    80000e60:	9fb9                	addw	a5,a5,a4
    80000e62:	010787bb          	addw	a5,a5,a6
    80000e66:	fef048e3          	bgtz	a5,80000e56 <strncpy+0x24>
  return os;
}
    80000e6a:	6422                	ld	s0,8(sp)
    80000e6c:	0141                	addi	sp,sp,16
    80000e6e:	8082                	ret

0000000080000e70 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e70:	1141                	addi	sp,sp,-16
    80000e72:	e422                	sd	s0,8(sp)
    80000e74:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e76:	02c05363          	blez	a2,80000e9c <safestrcpy+0x2c>
    80000e7a:	fff6069b          	addiw	a3,a2,-1
    80000e7e:	1682                	slli	a3,a3,0x20
    80000e80:	9281                	srli	a3,a3,0x20
    80000e82:	96ae                	add	a3,a3,a1
    80000e84:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e86:	00d58963          	beq	a1,a3,80000e98 <safestrcpy+0x28>
    80000e8a:	0585                	addi	a1,a1,1
    80000e8c:	0785                	addi	a5,a5,1
    80000e8e:	fff5c703          	lbu	a4,-1(a1)
    80000e92:	fee78fa3          	sb	a4,-1(a5)
    80000e96:	fb65                	bnez	a4,80000e86 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e98:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret

0000000080000ea2 <strlen>:

int
strlen(const char *s)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e422                	sd	s0,8(sp)
    80000ea6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ea8:	00054783          	lbu	a5,0(a0)
    80000eac:	cf91                	beqz	a5,80000ec8 <strlen+0x26>
    80000eae:	0505                	addi	a0,a0,1
    80000eb0:	87aa                	mv	a5,a0
    80000eb2:	4685                	li	a3,1
    80000eb4:	9e89                	subw	a3,a3,a0
    80000eb6:	00f6853b          	addw	a0,a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	fb7d                	bnez	a4,80000eb6 <strlen+0x14>
    ;
  return n;
}
    80000ec2:	6422                	ld	s0,8(sp)
    80000ec4:	0141                	addi	sp,sp,16
    80000ec6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ec8:	4501                	li	a0,0
    80000eca:	bfe5                	j	80000ec2 <strlen+0x20>

0000000080000ecc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ecc:	1141                	addi	sp,sp,-16
    80000ece:	e406                	sd	ra,8(sp)
    80000ed0:	e022                	sd	s0,0(sp)
    80000ed2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	cc6080e7          	jalr	-826(ra) # 80001b9a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000edc:	00008717          	auipc	a4,0x8
    80000ee0:	13070713          	addi	a4,a4,304 # 8000900c <started>
  if(cpuid() == 0){
    80000ee4:	c139                	beqz	a0,80000f2a <main+0x5e>
    while(started == 0)
    80000ee6:	431c                	lw	a5,0(a4)
    80000ee8:	2781                	sext.w	a5,a5
    80000eea:	dff5                	beqz	a5,80000ee6 <main+0x1a>
      ;
    __sync_synchronize();
    80000eec:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	caa080e7          	jalr	-854(ra) # 80001b9a <cpuid>
    80000ef8:	85aa                	mv	a1,a0
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1be50513          	addi	a0,a0,446 # 800080b8 <digits+0x78>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	69e080e7          	jalr	1694(ra) # 800005a0 <printf>
    kvminithart();    // turn on paging
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	0d8080e7          	jalr	216(ra) # 80000fe2 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f12:	00002097          	auipc	ra,0x2
    80000f16:	912080e7          	jalr	-1774(ra) # 80002824 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f1a:	00005097          	auipc	ra,0x5
    80000f1e:	f12080e7          	jalr	-238(ra) # 80005e2c <plicinithart>
  }

  scheduler();        
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	1d4080e7          	jalr	468(ra) # 800020f6 <scheduler>
    consoleinit();
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	53e080e7          	jalr	1342(ra) # 80000468 <consoleinit>
    printfinit();
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	854080e7          	jalr	-1964(ra) # 80000786 <printfinit>
    printf("\n");
    80000f3a:	00007517          	auipc	a0,0x7
    80000f3e:	18e50513          	addi	a0,a0,398 # 800080c8 <digits+0x88>
    80000f42:	fffff097          	auipc	ra,0xfffff
    80000f46:	65e080e7          	jalr	1630(ra) # 800005a0 <printf>
    printf("xv6 kernel is booting\n");
    80000f4a:	00007517          	auipc	a0,0x7
    80000f4e:	15650513          	addi	a0,a0,342 # 800080a0 <digits+0x60>
    80000f52:	fffff097          	auipc	ra,0xfffff
    80000f56:	64e080e7          	jalr	1614(ra) # 800005a0 <printf>
    printf("\n");
    80000f5a:	00007517          	auipc	a0,0x7
    80000f5e:	16e50513          	addi	a0,a0,366 # 800080c8 <digits+0x88>
    80000f62:	fffff097          	auipc	ra,0xfffff
    80000f66:	63e080e7          	jalr	1598(ra) # 800005a0 <printf>
    kinit();         // physical page allocator
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	b88080e7          	jalr	-1144(ra) # 80000af2 <kinit>
    kvminit();       // create kernel page table
    80000f72:	00000097          	auipc	ra,0x0
    80000f76:	2a0080e7          	jalr	672(ra) # 80001212 <kvminit>
    kvminithart();   // turn on paging
    80000f7a:	00000097          	auipc	ra,0x0
    80000f7e:	068080e7          	jalr	104(ra) # 80000fe2 <kvminithart>
    procinit();      // process table
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	b48080e7          	jalr	-1208(ra) # 80001aca <procinit>
    trapinit();      // trap vectors
    80000f8a:	00002097          	auipc	ra,0x2
    80000f8e:	872080e7          	jalr	-1934(ra) # 800027fc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f92:	00002097          	auipc	ra,0x2
    80000f96:	892080e7          	jalr	-1902(ra) # 80002824 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f9a:	00005097          	auipc	ra,0x5
    80000f9e:	e7c080e7          	jalr	-388(ra) # 80005e16 <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa2:	00005097          	auipc	ra,0x5
    80000fa6:	e8a080e7          	jalr	-374(ra) # 80005e2c <plicinithart>
    binit();         // buffer cache
    80000faa:	00002097          	auipc	ra,0x2
    80000fae:	006080e7          	jalr	6(ra) # 80002fb0 <binit>
    iinit();         // inode cache
    80000fb2:	00002097          	auipc	ra,0x2
    80000fb6:	696080e7          	jalr	1686(ra) # 80003648 <iinit>
    fileinit();      // file table
    80000fba:	00003097          	auipc	ra,0x3
    80000fbe:	634080e7          	jalr	1588(ra) # 800045ee <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc2:	00005097          	auipc	ra,0x5
    80000fc6:	f72080e7          	jalr	-142(ra) # 80005f34 <virtio_disk_init>
    userinit();      // first user process
    80000fca:	00001097          	auipc	ra,0x1
    80000fce:	ec6080e7          	jalr	-314(ra) # 80001e90 <userinit>
    __sync_synchronize();
    80000fd2:	0ff0000f          	fence
    started = 1;
    80000fd6:	4785                	li	a5,1
    80000fd8:	00008717          	auipc	a4,0x8
    80000fdc:	02f72a23          	sw	a5,52(a4) # 8000900c <started>
    80000fe0:	b789                	j	80000f22 <main+0x56>

0000000080000fe2 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe2:	1141                	addi	sp,sp,-16
    80000fe4:	e422                	sd	s0,8(sp)
    80000fe6:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe8:	00008797          	auipc	a5,0x8
    80000fec:	0287b783          	ld	a5,40(a5) # 80009010 <kernel_pagetable>
    80000ff0:	83b1                	srli	a5,a5,0xc
    80000ff2:	577d                	li	a4,-1
    80000ff4:	177e                	slli	a4,a4,0x3f
    80000ff6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ffc:	12000073          	sfence.vma
  sfence_vma();
}
    80001000:	6422                	ld	s0,8(sp)
    80001002:	0141                	addi	sp,sp,16
    80001004:	8082                	ret

0000000080001006 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001006:	7139                	addi	sp,sp,-64
    80001008:	fc06                	sd	ra,56(sp)
    8000100a:	f822                	sd	s0,48(sp)
    8000100c:	f426                	sd	s1,40(sp)
    8000100e:	f04a                	sd	s2,32(sp)
    80001010:	ec4e                	sd	s3,24(sp)
    80001012:	e852                	sd	s4,16(sp)
    80001014:	e456                	sd	s5,8(sp)
    80001016:	e05a                	sd	s6,0(sp)
    80001018:	0080                	addi	s0,sp,64
    8000101a:	84aa                	mv	s1,a0
    8000101c:	89ae                	mv	s3,a1
    8000101e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001020:	57fd                	li	a5,-1
    80001022:	83e9                	srli	a5,a5,0x1a
    80001024:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001026:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001028:	04b7f263          	bgeu	a5,a1,8000106c <walk+0x66>
    panic("walk");
    8000102c:	00007517          	auipc	a0,0x7
    80001030:	0a450513          	addi	a0,a0,164 # 800080d0 <digits+0x90>
    80001034:	fffff097          	auipc	ra,0xfffff
    80001038:	522080e7          	jalr	1314(ra) # 80000556 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000103c:	060a8663          	beqz	s5,800010a8 <walk+0xa2>
    80001040:	00000097          	auipc	ra,0x0
    80001044:	aee080e7          	jalr	-1298(ra) # 80000b2e <kalloc>
    80001048:	84aa                	mv	s1,a0
    8000104a:	c529                	beqz	a0,80001094 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000104c:	6605                	lui	a2,0x1
    8000104e:	4581                	li	a1,0
    80001050:	00000097          	auipc	ra,0x0
    80001054:	cca080e7          	jalr	-822(ra) # 80000d1a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001058:	00c4d793          	srli	a5,s1,0xc
    8000105c:	07aa                	slli	a5,a5,0xa
    8000105e:	0017e793          	ori	a5,a5,1
    80001062:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001066:	3a5d                	addiw	s4,s4,-9
    80001068:	036a0063          	beq	s4,s6,80001088 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000106c:	0149d933          	srl	s2,s3,s4
    80001070:	1ff97913          	andi	s2,s2,511
    80001074:	090e                	slli	s2,s2,0x3
    80001076:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001078:	00093483          	ld	s1,0(s2)
    8000107c:	0014f793          	andi	a5,s1,1
    80001080:	dfd5                	beqz	a5,8000103c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001082:	80a9                	srli	s1,s1,0xa
    80001084:	04b2                	slli	s1,s1,0xc
    80001086:	b7c5                	j	80001066 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001088:	00c9d513          	srli	a0,s3,0xc
    8000108c:	1ff57513          	andi	a0,a0,511
    80001090:	050e                	slli	a0,a0,0x3
    80001092:	9526                	add	a0,a0,s1
}
    80001094:	70e2                	ld	ra,56(sp)
    80001096:	7442                	ld	s0,48(sp)
    80001098:	74a2                	ld	s1,40(sp)
    8000109a:	7902                	ld	s2,32(sp)
    8000109c:	69e2                	ld	s3,24(sp)
    8000109e:	6a42                	ld	s4,16(sp)
    800010a0:	6aa2                	ld	s5,8(sp)
    800010a2:	6b02                	ld	s6,0(sp)
    800010a4:	6121                	addi	sp,sp,64
    800010a6:	8082                	ret
        return 0;
    800010a8:	4501                	li	a0,0
    800010aa:	b7ed                	j	80001094 <walk+0x8e>

00000000800010ac <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010ac:	57fd                	li	a5,-1
    800010ae:	83e9                	srli	a5,a5,0x1a
    800010b0:	00b7f463          	bgeu	a5,a1,800010b8 <walkaddr+0xc>
    return 0;
    800010b4:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b6:	8082                	ret
{
    800010b8:	1141                	addi	sp,sp,-16
    800010ba:	e406                	sd	ra,8(sp)
    800010bc:	e022                	sd	s0,0(sp)
    800010be:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010c0:	4601                	li	a2,0
    800010c2:	00000097          	auipc	ra,0x0
    800010c6:	f44080e7          	jalr	-188(ra) # 80001006 <walk>
  if(pte == 0)
    800010ca:	c105                	beqz	a0,800010ea <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010cc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010ce:	0117f693          	andi	a3,a5,17
    800010d2:	4745                	li	a4,17
    return 0;
    800010d4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d6:	00e68663          	beq	a3,a4,800010e2 <walkaddr+0x36>
}
    800010da:	60a2                	ld	ra,8(sp)
    800010dc:	6402                	ld	s0,0(sp)
    800010de:	0141                	addi	sp,sp,16
    800010e0:	8082                	ret
  pa = PTE2PA(*pte);
    800010e2:	00a7d513          	srli	a0,a5,0xa
    800010e6:	0532                	slli	a0,a0,0xc
  return pa;
    800010e8:	bfcd                	j	800010da <walkaddr+0x2e>
    return 0;
    800010ea:	4501                	li	a0,0
    800010ec:	b7fd                	j	800010da <walkaddr+0x2e>

00000000800010ee <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010ee:	1101                	addi	sp,sp,-32
    800010f0:	ec06                	sd	ra,24(sp)
    800010f2:	e822                	sd	s0,16(sp)
    800010f4:	e426                	sd	s1,8(sp)
    800010f6:	1000                	addi	s0,sp,32
    800010f8:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010fa:	1552                	slli	a0,a0,0x34
    800010fc:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001100:	4601                	li	a2,0
    80001102:	00008517          	auipc	a0,0x8
    80001106:	f0e53503          	ld	a0,-242(a0) # 80009010 <kernel_pagetable>
    8000110a:	00000097          	auipc	ra,0x0
    8000110e:	efc080e7          	jalr	-260(ra) # 80001006 <walk>
  if(pte == 0)
    80001112:	cd09                	beqz	a0,8000112c <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001114:	6108                	ld	a0,0(a0)
    80001116:	00157793          	andi	a5,a0,1
    8000111a:	c38d                	beqz	a5,8000113c <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111c:	8129                	srli	a0,a0,0xa
    8000111e:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001120:	9526                	add	a0,a0,s1
    80001122:	60e2                	ld	ra,24(sp)
    80001124:	6442                	ld	s0,16(sp)
    80001126:	64a2                	ld	s1,8(sp)
    80001128:	6105                	addi	sp,sp,32
    8000112a:	8082                	ret
    panic("kvmpa");
    8000112c:	00007517          	auipc	a0,0x7
    80001130:	fac50513          	addi	a0,a0,-84 # 800080d8 <digits+0x98>
    80001134:	fffff097          	auipc	ra,0xfffff
    80001138:	422080e7          	jalr	1058(ra) # 80000556 <panic>
    panic("kvmpa");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	f9c50513          	addi	a0,a0,-100 # 800080d8 <digits+0x98>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	412080e7          	jalr	1042(ra) # 80000556 <panic>

000000008000114c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000114c:	715d                	addi	sp,sp,-80
    8000114e:	e486                	sd	ra,72(sp)
    80001150:	e0a2                	sd	s0,64(sp)
    80001152:	fc26                	sd	s1,56(sp)
    80001154:	f84a                	sd	s2,48(sp)
    80001156:	f44e                	sd	s3,40(sp)
    80001158:	f052                	sd	s4,32(sp)
    8000115a:	ec56                	sd	s5,24(sp)
    8000115c:	e85a                	sd	s6,16(sp)
    8000115e:	e45e                	sd	s7,8(sp)
    80001160:	0880                	addi	s0,sp,80
    80001162:	8aaa                	mv	s5,a0
    80001164:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001166:	777d                	lui	a4,0xfffff
    80001168:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000116c:	167d                	addi	a2,a2,-1
    8000116e:	00b609b3          	add	s3,a2,a1
    80001172:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001176:	893e                	mv	s2,a5
    80001178:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000117c:	6b85                	lui	s7,0x1
    8000117e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001182:	4605                	li	a2,1
    80001184:	85ca                	mv	a1,s2
    80001186:	8556                	mv	a0,s5
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	e7e080e7          	jalr	-386(ra) # 80001006 <walk>
    80001190:	c51d                	beqz	a0,800011be <mappages+0x72>
    if(*pte & PTE_V)
    80001192:	611c                	ld	a5,0(a0)
    80001194:	8b85                	andi	a5,a5,1
    80001196:	ef81                	bnez	a5,800011ae <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001198:	80b1                	srli	s1,s1,0xc
    8000119a:	04aa                	slli	s1,s1,0xa
    8000119c:	0164e4b3          	or	s1,s1,s6
    800011a0:	0014e493          	ori	s1,s1,1
    800011a4:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a6:	03390863          	beq	s2,s3,800011d6 <mappages+0x8a>
    a += PGSIZE;
    800011aa:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ac:	bfc9                	j	8000117e <mappages+0x32>
      panic("remap");
    800011ae:	00007517          	auipc	a0,0x7
    800011b2:	f3250513          	addi	a0,a0,-206 # 800080e0 <digits+0xa0>
    800011b6:	fffff097          	auipc	ra,0xfffff
    800011ba:	3a0080e7          	jalr	928(ra) # 80000556 <panic>
      return -1;
    800011be:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c0:	60a6                	ld	ra,72(sp)
    800011c2:	6406                	ld	s0,64(sp)
    800011c4:	74e2                	ld	s1,56(sp)
    800011c6:	7942                	ld	s2,48(sp)
    800011c8:	79a2                	ld	s3,40(sp)
    800011ca:	7a02                	ld	s4,32(sp)
    800011cc:	6ae2                	ld	s5,24(sp)
    800011ce:	6b42                	ld	s6,16(sp)
    800011d0:	6ba2                	ld	s7,8(sp)
    800011d2:	6161                	addi	sp,sp,80
    800011d4:	8082                	ret
  return 0;
    800011d6:	4501                	li	a0,0
    800011d8:	b7e5                	j	800011c0 <mappages+0x74>

00000000800011da <kvmmap>:
{
    800011da:	1141                	addi	sp,sp,-16
    800011dc:	e406                	sd	ra,8(sp)
    800011de:	e022                	sd	s0,0(sp)
    800011e0:	0800                	addi	s0,sp,16
    800011e2:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e4:	86ae                	mv	a3,a1
    800011e6:	85aa                	mv	a1,a0
    800011e8:	00008517          	auipc	a0,0x8
    800011ec:	e2853503          	ld	a0,-472(a0) # 80009010 <kernel_pagetable>
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	f5c080e7          	jalr	-164(ra) # 8000114c <mappages>
    800011f8:	e509                	bnez	a0,80001202 <kvmmap+0x28>
}
    800011fa:	60a2                	ld	ra,8(sp)
    800011fc:	6402                	ld	s0,0(sp)
    800011fe:	0141                	addi	sp,sp,16
    80001200:	8082                	ret
    panic("kvmmap");
    80001202:	00007517          	auipc	a0,0x7
    80001206:	ee650513          	addi	a0,a0,-282 # 800080e8 <digits+0xa8>
    8000120a:	fffff097          	auipc	ra,0xfffff
    8000120e:	34c080e7          	jalr	844(ra) # 80000556 <panic>

0000000080001212 <kvminit>:
{
    80001212:	1101                	addi	sp,sp,-32
    80001214:	ec06                	sd	ra,24(sp)
    80001216:	e822                	sd	s0,16(sp)
    80001218:	e426                	sd	s1,8(sp)
    8000121a:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	912080e7          	jalr	-1774(ra) # 80000b2e <kalloc>
    80001224:	00008797          	auipc	a5,0x8
    80001228:	dea7b623          	sd	a0,-532(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000122c:	6605                	lui	a2,0x1
    8000122e:	4581                	li	a1,0
    80001230:	00000097          	auipc	ra,0x0
    80001234:	aea080e7          	jalr	-1302(ra) # 80000d1a <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001238:	4699                	li	a3,6
    8000123a:	6605                	lui	a2,0x1
    8000123c:	100005b7          	lui	a1,0x10000
    80001240:	10000537          	lui	a0,0x10000
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f96080e7          	jalr	-106(ra) # 800011da <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000124c:	4699                	li	a3,6
    8000124e:	6605                	lui	a2,0x1
    80001250:	100015b7          	lui	a1,0x10001
    80001254:	10001537          	lui	a0,0x10001
    80001258:	00000097          	auipc	ra,0x0
    8000125c:	f82080e7          	jalr	-126(ra) # 800011da <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001260:	4699                	li	a3,6
    80001262:	6641                	lui	a2,0x10
    80001264:	020005b7          	lui	a1,0x2000
    80001268:	02000537          	lui	a0,0x2000
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f6e080e7          	jalr	-146(ra) # 800011da <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	00400637          	lui	a2,0x400
    8000127a:	0c0005b7          	lui	a1,0xc000
    8000127e:	0c000537          	lui	a0,0xc000
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f58080e7          	jalr	-168(ra) # 800011da <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128a:	00007497          	auipc	s1,0x7
    8000128e:	d7648493          	addi	s1,s1,-650 # 80008000 <etext>
    80001292:	46a9                	li	a3,10
    80001294:	80007617          	auipc	a2,0x80007
    80001298:	d6c60613          	addi	a2,a2,-660 # 8000 <_entry-0x7fff8000>
    8000129c:	4585                	li	a1,1
    8000129e:	05fe                	slli	a1,a1,0x1f
    800012a0:	852e                	mv	a0,a1
    800012a2:	00000097          	auipc	ra,0x0
    800012a6:	f38080e7          	jalr	-200(ra) # 800011da <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012aa:	4699                	li	a3,6
    800012ac:	4645                	li	a2,17
    800012ae:	066e                	slli	a2,a2,0x1b
    800012b0:	8e05                	sub	a2,a2,s1
    800012b2:	85a6                	mv	a1,s1
    800012b4:	8526                	mv	a0,s1
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	f24080e7          	jalr	-220(ra) # 800011da <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012be:	46a9                	li	a3,10
    800012c0:	6605                	lui	a2,0x1
    800012c2:	00006597          	auipc	a1,0x6
    800012c6:	d3e58593          	addi	a1,a1,-706 # 80007000 <_trampoline>
    800012ca:	04000537          	lui	a0,0x4000
    800012ce:	157d                	addi	a0,a0,-1
    800012d0:	0532                	slli	a0,a0,0xc
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f08080e7          	jalr	-248(ra) # 800011da <kvmmap>
}
    800012da:	60e2                	ld	ra,24(sp)
    800012dc:	6442                	ld	s0,16(sp)
    800012de:	64a2                	ld	s1,8(sp)
    800012e0:	6105                	addi	sp,sp,32
    800012e2:	8082                	ret

00000000800012e4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e4:	715d                	addi	sp,sp,-80
    800012e6:	e486                	sd	ra,72(sp)
    800012e8:	e0a2                	sd	s0,64(sp)
    800012ea:	fc26                	sd	s1,56(sp)
    800012ec:	f84a                	sd	s2,48(sp)
    800012ee:	f44e                	sd	s3,40(sp)
    800012f0:	f052                	sd	s4,32(sp)
    800012f2:	ec56                	sd	s5,24(sp)
    800012f4:	e85a                	sd	s6,16(sp)
    800012f6:	e45e                	sd	s7,8(sp)
    800012f8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fa:	03459793          	slli	a5,a1,0x34
    800012fe:	e795                	bnez	a5,8000132a <uvmunmap+0x46>
    80001300:	8a2a                	mv	s4,a0
    80001302:	892e                	mv	s2,a1
    80001304:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	0632                	slli	a2,a2,0xc
    80001308:	00b609b3          	add	s3,a2,a1
      continue; // do nothing if not mapped (lazy allocation)
    }
    if((*pte & PTE_V) == 0){
      continue; // do nothing if not mapped (lazy allocation)
    }
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	6a85                	lui	s5,0x1
    80001310:	0535e963          	bltu	a1,s3,80001362 <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001314:	60a6                	ld	ra,72(sp)
    80001316:	6406                	ld	s0,64(sp)
    80001318:	74e2                	ld	s1,56(sp)
    8000131a:	7942                	ld	s2,48(sp)
    8000131c:	79a2                	ld	s3,40(sp)
    8000131e:	7a02                	ld	s4,32(sp)
    80001320:	6ae2                	ld	s5,24(sp)
    80001322:	6b42                	ld	s6,16(sp)
    80001324:	6ba2                	ld	s7,8(sp)
    80001326:	6161                	addi	sp,sp,80
    80001328:	8082                	ret
    panic("uvmunmap: not aligned");
    8000132a:	00007517          	auipc	a0,0x7
    8000132e:	dc650513          	addi	a0,a0,-570 # 800080f0 <digits+0xb0>
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	224080e7          	jalr	548(ra) # 80000556 <panic>
      panic("uvmunmap: not a leaf");
    8000133a:	00007517          	auipc	a0,0x7
    8000133e:	dce50513          	addi	a0,a0,-562 # 80008108 <digits+0xc8>
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	214080e7          	jalr	532(ra) # 80000556 <panic>
      uint64 pa = PTE2PA(*pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	6e2080e7          	jalr	1762(ra) # 80000a32 <kfree>
    *pte = 0;
    80001358:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135c:	9956                	add	s2,s2,s5
    8000135e:	fb397be3          	bgeu	s2,s3,80001314 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0) {
    80001362:	4601                	li	a2,0
    80001364:	85ca                	mv	a1,s2
    80001366:	8552                	mv	a0,s4
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	c9e080e7          	jalr	-866(ra) # 80001006 <walk>
    80001370:	84aa                	mv	s1,a0
    80001372:	d56d                	beqz	a0,8000135c <uvmunmap+0x78>
    if((*pte & PTE_V) == 0){
    80001374:	611c                	ld	a5,0(a0)
    80001376:	0017f713          	andi	a4,a5,1
    8000137a:	d36d                	beqz	a4,8000135c <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000137c:	3ff7f713          	andi	a4,a5,1023
    80001380:	fb770de3          	beq	a4,s7,8000133a <uvmunmap+0x56>
    if(do_free){
    80001384:	fc0b0ae3          	beqz	s6,80001358 <uvmunmap+0x74>
    80001388:	b7c9                	j	8000134a <uvmunmap+0x66>

000000008000138a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000138a:	1101                	addi	sp,sp,-32
    8000138c:	ec06                	sd	ra,24(sp)
    8000138e:	e822                	sd	s0,16(sp)
    80001390:	e426                	sd	s1,8(sp)
    80001392:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	79a080e7          	jalr	1946(ra) # 80000b2e <kalloc>
    8000139c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000139e:	c519                	beqz	a0,800013ac <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a0:	6605                	lui	a2,0x1
    800013a2:	4581                	li	a1,0
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	976080e7          	jalr	-1674(ra) # 80000d1a <memset>
  return pagetable;
}
    800013ac:	8526                	mv	a0,s1
    800013ae:	60e2                	ld	ra,24(sp)
    800013b0:	6442                	ld	s0,16(sp)
    800013b2:	64a2                	ld	s1,8(sp)
    800013b4:	6105                	addi	sp,sp,32
    800013b6:	8082                	ret

00000000800013b8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013b8:	7179                	addi	sp,sp,-48
    800013ba:	f406                	sd	ra,40(sp)
    800013bc:	f022                	sd	s0,32(sp)
    800013be:	ec26                	sd	s1,24(sp)
    800013c0:	e84a                	sd	s2,16(sp)
    800013c2:	e44e                	sd	s3,8(sp)
    800013c4:	e052                	sd	s4,0(sp)
    800013c6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013c8:	6785                	lui	a5,0x1
    800013ca:	04f67863          	bgeu	a2,a5,8000141a <uvminit+0x62>
    800013ce:	8a2a                	mv	s4,a0
    800013d0:	89ae                	mv	s3,a1
    800013d2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	75a080e7          	jalr	1882(ra) # 80000b2e <kalloc>
    800013dc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013de:	6605                	lui	a2,0x1
    800013e0:	4581                	li	a1,0
    800013e2:	00000097          	auipc	ra,0x0
    800013e6:	938080e7          	jalr	-1736(ra) # 80000d1a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ea:	4779                	li	a4,30
    800013ec:	86ca                	mv	a3,s2
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	8552                	mv	a0,s4
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	d58080e7          	jalr	-680(ra) # 8000114c <mappages>
  memmove(mem, src, sz);
    800013fc:	8626                	mv	a2,s1
    800013fe:	85ce                	mv	a1,s3
    80001400:	854a                	mv	a0,s2
    80001402:	00000097          	auipc	ra,0x0
    80001406:	978080e7          	jalr	-1672(ra) # 80000d7a <memmove>
}
    8000140a:	70a2                	ld	ra,40(sp)
    8000140c:	7402                	ld	s0,32(sp)
    8000140e:	64e2                	ld	s1,24(sp)
    80001410:	6942                	ld	s2,16(sp)
    80001412:	69a2                	ld	s3,8(sp)
    80001414:	6a02                	ld	s4,0(sp)
    80001416:	6145                	addi	sp,sp,48
    80001418:	8082                	ret
    panic("inituvm: more than a page");
    8000141a:	00007517          	auipc	a0,0x7
    8000141e:	d0650513          	addi	a0,a0,-762 # 80008120 <digits+0xe0>
    80001422:	fffff097          	auipc	ra,0xfffff
    80001426:	134080e7          	jalr	308(ra) # 80000556 <panic>

000000008000142a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000142a:	1101                	addi	sp,sp,-32
    8000142c:	ec06                	sd	ra,24(sp)
    8000142e:	e822                	sd	s0,16(sp)
    80001430:	e426                	sd	s1,8(sp)
    80001432:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001434:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001436:	00b67d63          	bgeu	a2,a1,80001450 <uvmdealloc+0x26>
    8000143a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000143c:	6785                	lui	a5,0x1
    8000143e:	17fd                	addi	a5,a5,-1
    80001440:	00f60733          	add	a4,a2,a5
    80001444:	767d                	lui	a2,0xfffff
    80001446:	8f71                	and	a4,a4,a2
    80001448:	97ae                	add	a5,a5,a1
    8000144a:	8ff1                	and	a5,a5,a2
    8000144c:	00f76863          	bltu	a4,a5,8000145c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001450:	8526                	mv	a0,s1
    80001452:	60e2                	ld	ra,24(sp)
    80001454:	6442                	ld	s0,16(sp)
    80001456:	64a2                	ld	s1,8(sp)
    80001458:	6105                	addi	sp,sp,32
    8000145a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000145c:	8f99                	sub	a5,a5,a4
    8000145e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001460:	4685                	li	a3,1
    80001462:	0007861b          	sext.w	a2,a5
    80001466:	85ba                	mv	a1,a4
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	e7c080e7          	jalr	-388(ra) # 800012e4 <uvmunmap>
    80001470:	b7c5                	j	80001450 <uvmdealloc+0x26>

0000000080001472 <uvmalloc>:
  if(newsz < oldsz)
    80001472:	0ab66163          	bltu	a2,a1,80001514 <uvmalloc+0xa2>
{
    80001476:	7139                	addi	sp,sp,-64
    80001478:	fc06                	sd	ra,56(sp)
    8000147a:	f822                	sd	s0,48(sp)
    8000147c:	f426                	sd	s1,40(sp)
    8000147e:	f04a                	sd	s2,32(sp)
    80001480:	ec4e                	sd	s3,24(sp)
    80001482:	e852                	sd	s4,16(sp)
    80001484:	e456                	sd	s5,8(sp)
    80001486:	0080                	addi	s0,sp,64
    80001488:	8aaa                	mv	s5,a0
    8000148a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000148c:	6985                	lui	s3,0x1
    8000148e:	19fd                	addi	s3,s3,-1
    80001490:	95ce                	add	a1,a1,s3
    80001492:	79fd                	lui	s3,0xfffff
    80001494:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001498:	08c9f063          	bgeu	s3,a2,80001518 <uvmalloc+0xa6>
    8000149c:	894e                	mv	s2,s3
    mem = kalloc();
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	690080e7          	jalr	1680(ra) # 80000b2e <kalloc>
    800014a6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014a8:	c51d                	beqz	a0,800014d6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014aa:	6605                	lui	a2,0x1
    800014ac:	4581                	li	a1,0
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	86c080e7          	jalr	-1940(ra) # 80000d1a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014b6:	4779                	li	a4,30
    800014b8:	86a6                	mv	a3,s1
    800014ba:	6605                	lui	a2,0x1
    800014bc:	85ca                	mv	a1,s2
    800014be:	8556                	mv	a0,s5
    800014c0:	00000097          	auipc	ra,0x0
    800014c4:	c8c080e7          	jalr	-884(ra) # 8000114c <mappages>
    800014c8:	e905                	bnez	a0,800014f8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ca:	6785                	lui	a5,0x1
    800014cc:	993e                	add	s2,s2,a5
    800014ce:	fd4968e3          	bltu	s2,s4,8000149e <uvmalloc+0x2c>
  return newsz;
    800014d2:	8552                	mv	a0,s4
    800014d4:	a809                	j	800014e6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014d6:	864e                	mv	a2,s3
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	f4e080e7          	jalr	-178(ra) # 8000142a <uvmdealloc>
      return 0;
    800014e4:	4501                	li	a0,0
}
    800014e6:	70e2                	ld	ra,56(sp)
    800014e8:	7442                	ld	s0,48(sp)
    800014ea:	74a2                	ld	s1,40(sp)
    800014ec:	7902                	ld	s2,32(sp)
    800014ee:	69e2                	ld	s3,24(sp)
    800014f0:	6a42                	ld	s4,16(sp)
    800014f2:	6aa2                	ld	s5,8(sp)
    800014f4:	6121                	addi	sp,sp,64
    800014f6:	8082                	ret
      kfree(mem);
    800014f8:	8526                	mv	a0,s1
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	538080e7          	jalr	1336(ra) # 80000a32 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001502:	864e                	mv	a2,s3
    80001504:	85ca                	mv	a1,s2
    80001506:	8556                	mv	a0,s5
    80001508:	00000097          	auipc	ra,0x0
    8000150c:	f22080e7          	jalr	-222(ra) # 8000142a <uvmdealloc>
      return 0;
    80001510:	4501                	li	a0,0
    80001512:	bfd1                	j	800014e6 <uvmalloc+0x74>
    return oldsz;
    80001514:	852e                	mv	a0,a1
}
    80001516:	8082                	ret
  return newsz;
    80001518:	8532                	mv	a0,a2
    8000151a:	b7f1                	j	800014e6 <uvmalloc+0x74>

000000008000151c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000151c:	7179                	addi	sp,sp,-48
    8000151e:	f406                	sd	ra,40(sp)
    80001520:	f022                	sd	s0,32(sp)
    80001522:	ec26                	sd	s1,24(sp)
    80001524:	e84a                	sd	s2,16(sp)
    80001526:	e44e                	sd	s3,8(sp)
    80001528:	e052                	sd	s4,0(sp)
    8000152a:	1800                	addi	s0,sp,48
    8000152c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000152e:	84aa                	mv	s1,a0
    80001530:	6905                	lui	s2,0x1
    80001532:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001534:	4985                	li	s3,1
    80001536:	a821                	j	8000154e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001538:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000153a:	0532                	slli	a0,a0,0xc
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	fe0080e7          	jalr	-32(ra) # 8000151c <freewalk>
      pagetable[i] = 0;
    80001544:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001548:	04a1                	addi	s1,s1,8
    8000154a:	03248163          	beq	s1,s2,8000156c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000154e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001550:	00f57793          	andi	a5,a0,15
    80001554:	ff3782e3          	beq	a5,s3,80001538 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001558:	8905                	andi	a0,a0,1
    8000155a:	d57d                	beqz	a0,80001548 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000155c:	00007517          	auipc	a0,0x7
    80001560:	be450513          	addi	a0,a0,-1052 # 80008140 <digits+0x100>
    80001564:	fffff097          	auipc	ra,0xfffff
    80001568:	ff2080e7          	jalr	-14(ra) # 80000556 <panic>
    }
  }
  kfree((void*)pagetable);
    8000156c:	8552                	mv	a0,s4
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	4c4080e7          	jalr	1220(ra) # 80000a32 <kfree>
}
    80001576:	70a2                	ld	ra,40(sp)
    80001578:	7402                	ld	s0,32(sp)
    8000157a:	64e2                	ld	s1,24(sp)
    8000157c:	6942                	ld	s2,16(sp)
    8000157e:	69a2                	ld	s3,8(sp)
    80001580:	6a02                	ld	s4,0(sp)
    80001582:	6145                	addi	sp,sp,48
    80001584:	8082                	ret

0000000080001586 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001586:	1101                	addi	sp,sp,-32
    80001588:	ec06                	sd	ra,24(sp)
    8000158a:	e822                	sd	s0,16(sp)
    8000158c:	e426                	sd	s1,8(sp)
    8000158e:	1000                	addi	s0,sp,32
    80001590:	84aa                	mv	s1,a0
  if(sz > 0)
    80001592:	e999                	bnez	a1,800015a8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001594:	8526                	mv	a0,s1
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	f86080e7          	jalr	-122(ra) # 8000151c <freewalk>
}
    8000159e:	60e2                	ld	ra,24(sp)
    800015a0:	6442                	ld	s0,16(sp)
    800015a2:	64a2                	ld	s1,8(sp)
    800015a4:	6105                	addi	sp,sp,32
    800015a6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015a8:	6605                	lui	a2,0x1
    800015aa:	167d                	addi	a2,a2,-1
    800015ac:	962e                	add	a2,a2,a1
    800015ae:	4685                	li	a3,1
    800015b0:	8231                	srli	a2,a2,0xc
    800015b2:	4581                	li	a1,0
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	d30080e7          	jalr	-720(ra) # 800012e4 <uvmunmap>
    800015bc:	bfe1                	j	80001594 <uvmfree+0xe>

00000000800015be <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015be:	ca4d                	beqz	a2,80001670 <uvmcopy+0xb2>
{
    800015c0:	715d                	addi	sp,sp,-80
    800015c2:	e486                	sd	ra,72(sp)
    800015c4:	e0a2                	sd	s0,64(sp)
    800015c6:	fc26                	sd	s1,56(sp)
    800015c8:	f84a                	sd	s2,48(sp)
    800015ca:	f44e                	sd	s3,40(sp)
    800015cc:	f052                	sd	s4,32(sp)
    800015ce:	ec56                	sd	s5,24(sp)
    800015d0:	e85a                	sd	s6,16(sp)
    800015d2:	e45e                	sd	s7,8(sp)
    800015d4:	0880                	addi	s0,sp,80
    800015d6:	8aaa                	mv	s5,a0
    800015d8:	8b2e                	mv	s6,a1
    800015da:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	4481                	li	s1,0
    800015de:	a029                	j	800015e8 <uvmcopy+0x2a>
    800015e0:	6785                	lui	a5,0x1
    800015e2:	94be                	add	s1,s1,a5
    800015e4:	0744fa63          	bgeu	s1,s4,80001658 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800015e8:	4601                	li	a2,0
    800015ea:	85a6                	mv	a1,s1
    800015ec:	8556                	mv	a0,s5
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	a18080e7          	jalr	-1512(ra) # 80001006 <walk>
    800015f6:	d56d                	beqz	a0,800015e0 <uvmcopy+0x22>
      continue; // page not present, assumed to be a lazy-allocated page
    if((*pte & PTE_V) == 0)
    800015f8:	6118                	ld	a4,0(a0)
    800015fa:	00177793          	andi	a5,a4,1
    800015fe:	d3ed                	beqz	a5,800015e0 <uvmcopy+0x22>
      continue; // page not present, assumed to be a lazy-allocated page
    pa = PTE2PA(*pte);
    80001600:	00a75593          	srli	a1,a4,0xa
    80001604:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001608:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	522080e7          	jalr	1314(ra) # 80000b2e <kalloc>
    80001614:	89aa                	mv	s3,a0
    80001616:	c515                	beqz	a0,80001642 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001618:	6605                	lui	a2,0x1
    8000161a:	85de                	mv	a1,s7
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	75e080e7          	jalr	1886(ra) # 80000d7a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001624:	874a                	mv	a4,s2
    80001626:	86ce                	mv	a3,s3
    80001628:	6605                	lui	a2,0x1
    8000162a:	85a6                	mv	a1,s1
    8000162c:	855a                	mv	a0,s6
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	b1e080e7          	jalr	-1250(ra) # 8000114c <mappages>
    80001636:	d54d                	beqz	a0,800015e0 <uvmcopy+0x22>
      kfree(mem);
    80001638:	854e                	mv	a0,s3
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	3f8080e7          	jalr	1016(ra) # 80000a32 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001642:	4685                	li	a3,1
    80001644:	00c4d613          	srli	a2,s1,0xc
    80001648:	4581                	li	a1,0
    8000164a:	855a                	mv	a0,s6
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	c98080e7          	jalr	-872(ra) # 800012e4 <uvmunmap>
  return -1;
    80001654:	557d                	li	a0,-1
    80001656:	a011                	j	8000165a <uvmcopy+0x9c>
  return 0;
    80001658:	4501                	li	a0,0
}
    8000165a:	60a6                	ld	ra,72(sp)
    8000165c:	6406                	ld	s0,64(sp)
    8000165e:	74e2                	ld	s1,56(sp)
    80001660:	7942                	ld	s2,48(sp)
    80001662:	79a2                	ld	s3,40(sp)
    80001664:	7a02                	ld	s4,32(sp)
    80001666:	6ae2                	ld	s5,24(sp)
    80001668:	6b42                	ld	s6,16(sp)
    8000166a:	6ba2                	ld	s7,8(sp)
    8000166c:	6161                	addi	sp,sp,80
    8000166e:	8082                	ret
  return 0;
    80001670:	4501                	li	a0,0
}
    80001672:	8082                	ret

0000000080001674 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001674:	1141                	addi	sp,sp,-16
    80001676:	e406                	sd	ra,8(sp)
    80001678:	e022                	sd	s0,0(sp)
    8000167a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000167c:	4601                	li	a2,0
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	988080e7          	jalr	-1656(ra) # 80001006 <walk>
  if(pte == 0)
    80001686:	c901                	beqz	a0,80001696 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001688:	611c                	ld	a5,0(a0)
    8000168a:	9bbd                	andi	a5,a5,-17
    8000168c:	e11c                	sd	a5,0(a0)
}
    8000168e:	60a2                	ld	ra,8(sp)
    80001690:	6402                	ld	s0,0(sp)
    80001692:	0141                	addi	sp,sp,16
    80001694:	8082                	ret
    panic("uvmclear");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	aba50513          	addi	a0,a0,-1350 # 80008150 <digits+0x110>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	eb8080e7          	jalr	-328(ra) # 80000556 <panic>

00000000800016a6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800016a6:	c6c5                	beqz	a3,8000174e <copyinstr+0xa8>
{
    800016a8:	715d                	addi	sp,sp,-80
    800016aa:	e486                	sd	ra,72(sp)
    800016ac:	e0a2                	sd	s0,64(sp)
    800016ae:	fc26                	sd	s1,56(sp)
    800016b0:	f84a                	sd	s2,48(sp)
    800016b2:	f44e                	sd	s3,40(sp)
    800016b4:	f052                	sd	s4,32(sp)
    800016b6:	ec56                	sd	s5,24(sp)
    800016b8:	e85a                	sd	s6,16(sp)
    800016ba:	e45e                	sd	s7,8(sp)
    800016bc:	0880                	addi	s0,sp,80
    800016be:	8a2a                	mv	s4,a0
    800016c0:	8b2e                	mv	s6,a1
    800016c2:	8bb2                	mv	s7,a2
    800016c4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800016c6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016c8:	6985                	lui	s3,0x1
    800016ca:	a035                	j	800016f6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800016cc:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800016d0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800016d2:	0017b793          	seqz	a5,a5
    800016d6:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800016da:	60a6                	ld	ra,72(sp)
    800016dc:	6406                	ld	s0,64(sp)
    800016de:	74e2                	ld	s1,56(sp)
    800016e0:	7942                	ld	s2,48(sp)
    800016e2:	79a2                	ld	s3,40(sp)
    800016e4:	7a02                	ld	s4,32(sp)
    800016e6:	6ae2                	ld	s5,24(sp)
    800016e8:	6b42                	ld	s6,16(sp)
    800016ea:	6ba2                	ld	s7,8(sp)
    800016ec:	6161                	addi	sp,sp,80
    800016ee:	8082                	ret
    srcva = va0 + PGSIZE;
    800016f0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800016f4:	c8a9                	beqz	s1,80001746 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800016f6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800016fa:	85ca                	mv	a1,s2
    800016fc:	8552                	mv	a0,s4
    800016fe:	00000097          	auipc	ra,0x0
    80001702:	9ae080e7          	jalr	-1618(ra) # 800010ac <walkaddr>
    if(pa0 == 0)
    80001706:	c131                	beqz	a0,8000174a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001708:	41790833          	sub	a6,s2,s7
    8000170c:	984e                	add	a6,a6,s3
    if(n > max)
    8000170e:	0104f363          	bgeu	s1,a6,80001714 <copyinstr+0x6e>
    80001712:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001714:	955e                	add	a0,a0,s7
    80001716:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000171a:	fc080be3          	beqz	a6,800016f0 <copyinstr+0x4a>
    8000171e:	985a                	add	a6,a6,s6
    80001720:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001722:	41650633          	sub	a2,a0,s6
    80001726:	14fd                	addi	s1,s1,-1
    80001728:	9b26                	add	s6,s6,s1
    8000172a:	00f60733          	add	a4,a2,a5
    8000172e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001732:	df49                	beqz	a4,800016cc <copyinstr+0x26>
        *dst = *p;
    80001734:	00e78023          	sb	a4,0(a5)
      --max;
    80001738:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000173c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000173e:	ff0796e3          	bne	a5,a6,8000172a <copyinstr+0x84>
      dst++;
    80001742:	8b42                	mv	s6,a6
    80001744:	b775                	j	800016f0 <copyinstr+0x4a>
    80001746:	4781                	li	a5,0
    80001748:	b769                	j	800016d2 <copyinstr+0x2c>
      return -1;
    8000174a:	557d                	li	a0,-1
    8000174c:	b779                	j	800016da <copyinstr+0x34>
  int got_null = 0;
    8000174e:	4781                	li	a5,0
  if(got_null){
    80001750:	0017b793          	seqz	a5,a5
    80001754:	40f00533          	neg	a0,a5
}
    80001758:	8082                	ret

000000008000175a <pgtblprint>:

int pgtblprint(pagetable_t pagetable, int depth) {
    8000175a:	7159                	addi	sp,sp,-112
    8000175c:	f486                	sd	ra,104(sp)
    8000175e:	f0a2                	sd	s0,96(sp)
    80001760:	eca6                	sd	s1,88(sp)
    80001762:	e8ca                	sd	s2,80(sp)
    80001764:	e4ce                	sd	s3,72(sp)
    80001766:	e0d2                	sd	s4,64(sp)
    80001768:	fc56                	sd	s5,56(sp)
    8000176a:	f85a                	sd	s6,48(sp)
    8000176c:	f45e                	sd	s7,40(sp)
    8000176e:	f062                	sd	s8,32(sp)
    80001770:	ec66                	sd	s9,24(sp)
    80001772:	e86a                	sd	s10,16(sp)
    80001774:	e46e                	sd	s11,8(sp)
    80001776:	1880                	addi	s0,sp,112
    80001778:	8aae                	mv	s5,a1
    // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000177a:	89aa                	mv	s3,a0
    8000177c:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) {
      // print
      printf("..");
    8000177e:	00007c97          	auipc	s9,0x7
    80001782:	9e2c8c93          	addi	s9,s9,-1566 # 80008160 <digits+0x120>
      for(int j=0;j<depth;j++) {
        printf(" ..");
      }
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001786:	00007c17          	auipc	s8,0x7
    8000178a:	9eac0c13          	addi	s8,s8,-1558 # 80008170 <digits+0x130>

      // if not a leaf page table, recursively print out the child table
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
        // this PTE points to a lower-level page table.
        uint64 child = PTE2PA(pte);
        pgtblprint((pagetable_t)child,depth+1);
    8000178e:	00158d9b          	addiw	s11,a1,1
      for(int j=0;j<depth;j++) {
    80001792:	4d01                	li	s10,0
        printf(" ..");
    80001794:	00007b17          	auipc	s6,0x7
    80001798:	9d4b0b13          	addi	s6,s6,-1580 # 80008168 <digits+0x128>
  for(int i = 0; i < 512; i++){
    8000179c:	20000b93          	li	s7,512
    800017a0:	a029                	j	800017aa <pgtblprint+0x50>
    800017a2:	2905                	addiw	s2,s2,1
    800017a4:	09a1                	addi	s3,s3,8
    800017a6:	05790d63          	beq	s2,s7,80001800 <pgtblprint+0xa6>
    pte_t pte = pagetable[i];
    800017aa:	0009ba03          	ld	s4,0(s3) # 1000 <_entry-0x7ffff000>
    if(pte & PTE_V) {
    800017ae:	001a7793          	andi	a5,s4,1
    800017b2:	dbe5                	beqz	a5,800017a2 <pgtblprint+0x48>
      printf("..");
    800017b4:	8566                	mv	a0,s9
    800017b6:	fffff097          	auipc	ra,0xfffff
    800017ba:	dea080e7          	jalr	-534(ra) # 800005a0 <printf>
      for(int j=0;j<depth;j++) {
    800017be:	01505b63          	blez	s5,800017d4 <pgtblprint+0x7a>
    800017c2:	84ea                	mv	s1,s10
        printf(" ..");
    800017c4:	855a                	mv	a0,s6
    800017c6:	fffff097          	auipc	ra,0xfffff
    800017ca:	dda080e7          	jalr	-550(ra) # 800005a0 <printf>
      for(int j=0;j<depth;j++) {
    800017ce:	2485                	addiw	s1,s1,1
    800017d0:	fe9a9ae3          	bne	s5,s1,800017c4 <pgtblprint+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    800017d4:	00aa5493          	srli	s1,s4,0xa
    800017d8:	04b2                	slli	s1,s1,0xc
    800017da:	86a6                	mv	a3,s1
    800017dc:	8652                	mv	a2,s4
    800017de:	85ca                	mv	a1,s2
    800017e0:	8562                	mv	a0,s8
    800017e2:	fffff097          	auipc	ra,0xfffff
    800017e6:	dbe080e7          	jalr	-578(ra) # 800005a0 <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800017ea:	00ea7a13          	andi	s4,s4,14
    800017ee:	fa0a1ae3          	bnez	s4,800017a2 <pgtblprint+0x48>
        pgtblprint((pagetable_t)child,depth+1);
    800017f2:	85ee                	mv	a1,s11
    800017f4:	8526                	mv	a0,s1
    800017f6:	00000097          	auipc	ra,0x0
    800017fa:	f64080e7          	jalr	-156(ra) # 8000175a <pgtblprint>
    800017fe:	b755                	j	800017a2 <pgtblprint+0x48>
      }
    }
  }
  return 0;
}
    80001800:	4501                	li	a0,0
    80001802:	70a6                	ld	ra,104(sp)
    80001804:	7406                	ld	s0,96(sp)
    80001806:	64e6                	ld	s1,88(sp)
    80001808:	6946                	ld	s2,80(sp)
    8000180a:	69a6                	ld	s3,72(sp)
    8000180c:	6a06                	ld	s4,64(sp)
    8000180e:	7ae2                	ld	s5,56(sp)
    80001810:	7b42                	ld	s6,48(sp)
    80001812:	7ba2                	ld	s7,40(sp)
    80001814:	7c02                	ld	s8,32(sp)
    80001816:	6ce2                	ld	s9,24(sp)
    80001818:	6d42                	ld	s10,16(sp)
    8000181a:	6da2                	ld	s11,8(sp)
    8000181c:	6165                	addi	sp,sp,112
    8000181e:	8082                	ret

0000000080001820 <vmprint>:

int vmprint(pagetable_t pagetable) {
    80001820:	1101                	addi	sp,sp,-32
    80001822:	ec06                	sd	ra,24(sp)
    80001824:	e822                	sd	s0,16(sp)
    80001826:	e426                	sd	s1,8(sp)
    80001828:	1000                	addi	s0,sp,32
    8000182a:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    8000182c:	85aa                	mv	a1,a0
    8000182e:	00007517          	auipc	a0,0x7
    80001832:	95a50513          	addi	a0,a0,-1702 # 80008188 <digits+0x148>
    80001836:	fffff097          	auipc	ra,0xfffff
    8000183a:	d6a080e7          	jalr	-662(ra) # 800005a0 <printf>
  return pgtblprint(pagetable, 0);
    8000183e:	4581                	li	a1,0
    80001840:	8526                	mv	a0,s1
    80001842:	00000097          	auipc	ra,0x0
    80001846:	f18080e7          	jalr	-232(ra) # 8000175a <pgtblprint>
}
    8000184a:	60e2                	ld	ra,24(sp)
    8000184c:	6442                	ld	s0,16(sp)
    8000184e:	64a2                	ld	s1,8(sp)
    80001850:	6105                	addi	sp,sp,32
    80001852:	8082                	ret

0000000080001854 <uvmlazytouch>:

// touch a lazy-allocated page so it's mapped to an actual physical page.
void uvmlazytouch(uint64 va) {
    80001854:	7179                	addi	sp,sp,-48
    80001856:	f406                	sd	ra,40(sp)
    80001858:	f022                	sd	s0,32(sp)
    8000185a:	ec26                	sd	s1,24(sp)
    8000185c:	e84a                	sd	s2,16(sp)
    8000185e:	e44e                	sd	s3,8(sp)
    80001860:	1800                	addi	s0,sp,48
    80001862:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80001864:	00000097          	auipc	ra,0x0
    80001868:	362080e7          	jalr	866(ra) # 80001bc6 <myproc>
    8000186c:	892a                	mv	s2,a0
  char *mem = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	2c0080e7          	jalr	704(ra) # 80000b2e <kalloc>
  if(mem == 0) {
    80001876:	cd05                	beqz	a0,800018ae <uvmlazytouch+0x5a>
    80001878:	84aa                	mv	s1,a0
    // failed to allocate physical memory
    printf("lazy alloc: out of memory\n");
    p->killed = 1;
  } else {
    memset(mem, 0, PGSIZE);
    8000187a:	6605                	lui	a2,0x1
    8000187c:	4581                	li	a1,0
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	49c080e7          	jalr	1180(ra) # 80000d1a <memset>
    if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001886:	4779                	li	a4,30
    80001888:	86a6                	mv	a3,s1
    8000188a:	6605                	lui	a2,0x1
    8000188c:	75fd                	lui	a1,0xfffff
    8000188e:	00b9f5b3          	and	a1,s3,a1
    80001892:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    80001896:	00000097          	auipc	ra,0x0
    8000189a:	8b6080e7          	jalr	-1866(ra) # 8000114c <mappages>
    8000189e:	e505                	bnez	a0,800018c6 <uvmlazytouch+0x72>
      kfree(mem);
      p->killed = 1;
    }
  }
  // printf("lazy alloc: %p, p->sz: %p\n", PGROUNDDOWN(va), p->sz);
}
    800018a0:	70a2                	ld	ra,40(sp)
    800018a2:	7402                	ld	s0,32(sp)
    800018a4:	64e2                	ld	s1,24(sp)
    800018a6:	6942                	ld	s2,16(sp)
    800018a8:	69a2                	ld	s3,8(sp)
    800018aa:	6145                	addi	sp,sp,48
    800018ac:	8082                	ret
    printf("lazy alloc: out of memory\n");
    800018ae:	00007517          	auipc	a0,0x7
    800018b2:	8ea50513          	addi	a0,a0,-1814 # 80008198 <digits+0x158>
    800018b6:	fffff097          	auipc	ra,0xfffff
    800018ba:	cea080e7          	jalr	-790(ra) # 800005a0 <printf>
    p->killed = 1;
    800018be:	4785                	li	a5,1
    800018c0:	02f92823          	sw	a5,48(s2)
    800018c4:	bff1                	j	800018a0 <uvmlazytouch+0x4c>
      printf("lazy alloc: failed to map page\n");
    800018c6:	00007517          	auipc	a0,0x7
    800018ca:	8f250513          	addi	a0,a0,-1806 # 800081b8 <digits+0x178>
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	cd2080e7          	jalr	-814(ra) # 800005a0 <printf>
      kfree(mem);
    800018d6:	8526                	mv	a0,s1
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	15a080e7          	jalr	346(ra) # 80000a32 <kfree>
      p->killed = 1;
    800018e0:	4785                	li	a5,1
    800018e2:	02f92823          	sw	a5,48(s2)
}
    800018e6:	bf6d                	j	800018a0 <uvmlazytouch+0x4c>

00000000800018e8 <uvmshouldtouch>:

// whether a page is previously lazy-allocated and needed to be touched before use.
int uvmshouldtouch(uint64 va) {
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  pte_t *pte;
  struct proc *p = myproc();
    800018f4:	00000097          	auipc	ra,0x0
    800018f8:	2d2080e7          	jalr	722(ra) # 80001bc6 <myproc>
  
  return va < p->sz // within size of memory for the process
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    800018fc:	6538                	ld	a4,72(a0)
    800018fe:	02e4f863          	bgeu	s1,a4,8000192e <uvmshouldtouch+0x46>
    80001902:	87aa                	mv	a5,a0
  asm volatile("mv %0, sp" : "=r" (x) );
    80001904:	868a                	mv	a3,sp
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    80001906:	777d                	lui	a4,0xfffff
    80001908:	8f65                	and	a4,a4,s1
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    8000190a:	4501                	li	a0,0
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    8000190c:	02d70263          	beq	a4,a3,80001930 <uvmshouldtouch+0x48>
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80001910:	4601                	li	a2,0
    80001912:	85a6                	mv	a1,s1
    80001914:	6ba8                	ld	a0,80(a5)
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	6f0080e7          	jalr	1776(ra) # 80001006 <walk>
    8000191e:	87aa                	mv	a5,a0
    80001920:	4505                	li	a0,1
    80001922:	c799                	beqz	a5,80001930 <uvmshouldtouch+0x48>
    80001924:	6388                	ld	a0,0(a5)
    80001926:	00154513          	xori	a0,a0,1
    8000192a:	8905                	andi	a0,a0,1
    8000192c:	a011                	j	80001930 <uvmshouldtouch+0x48>
    8000192e:	4501                	li	a0,0
    80001930:	60e2                	ld	ra,24(sp)
    80001932:	6442                	ld	s0,16(sp)
    80001934:	64a2                	ld	s1,8(sp)
    80001936:	6105                	addi	sp,sp,32
    80001938:	8082                	ret

000000008000193a <copyout>:
{
    8000193a:	715d                	addi	sp,sp,-80
    8000193c:	e486                	sd	ra,72(sp)
    8000193e:	e0a2                	sd	s0,64(sp)
    80001940:	fc26                	sd	s1,56(sp)
    80001942:	f84a                	sd	s2,48(sp)
    80001944:	f44e                	sd	s3,40(sp)
    80001946:	f052                	sd	s4,32(sp)
    80001948:	ec56                	sd	s5,24(sp)
    8000194a:	e85a                	sd	s6,16(sp)
    8000194c:	e45e                	sd	s7,8(sp)
    8000194e:	e062                	sd	s8,0(sp)
    80001950:	0880                	addi	s0,sp,80
    80001952:	8b2a                	mv	s6,a0
    80001954:	8c2e                	mv	s8,a1
    80001956:	8a32                	mv	s4,a2
    80001958:	89b6                	mv	s3,a3
  if(uvmshouldtouch(dstva))
    8000195a:	852e                	mv	a0,a1
    8000195c:	00000097          	auipc	ra,0x0
    80001960:	f8c080e7          	jalr	-116(ra) # 800018e8 <uvmshouldtouch>
    80001964:	e511                	bnez	a0,80001970 <copyout+0x36>
  while(len > 0){
    80001966:	04098e63          	beqz	s3,800019c2 <copyout+0x88>
    va0 = PGROUNDDOWN(dstva);
    8000196a:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (dstva - va0);
    8000196c:	6a85                	lui	s5,0x1
    8000196e:	a805                	j	8000199e <copyout+0x64>
    uvmlazytouch(dstva);
    80001970:	8562                	mv	a0,s8
    80001972:	00000097          	auipc	ra,0x0
    80001976:	ee2080e7          	jalr	-286(ra) # 80001854 <uvmlazytouch>
    8000197a:	b7f5                	j	80001966 <copyout+0x2c>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000197c:	9562                	add	a0,a0,s8
    8000197e:	0004861b          	sext.w	a2,s1
    80001982:	85d2                	mv	a1,s4
    80001984:	41250533          	sub	a0,a0,s2
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	3f2080e7          	jalr	1010(ra) # 80000d7a <memmove>
    len -= n;
    80001990:	409989b3          	sub	s3,s3,s1
    src += n;
    80001994:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001996:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000199a:	02098263          	beqz	s3,800019be <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    8000199e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019a2:	85ca                	mv	a1,s2
    800019a4:	855a                	mv	a0,s6
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	706080e7          	jalr	1798(ra) # 800010ac <walkaddr>
    if(pa0 == 0)
    800019ae:	cd01                	beqz	a0,800019c6 <copyout+0x8c>
    n = PGSIZE - (dstva - va0);
    800019b0:	418904b3          	sub	s1,s2,s8
    800019b4:	94d6                	add	s1,s1,s5
    if(n > len)
    800019b6:	fc99f3e3          	bgeu	s3,s1,8000197c <copyout+0x42>
    800019ba:	84ce                	mv	s1,s3
    800019bc:	b7c1                	j	8000197c <copyout+0x42>
  return 0;
    800019be:	4501                	li	a0,0
    800019c0:	a021                	j	800019c8 <copyout+0x8e>
    800019c2:	4501                	li	a0,0
    800019c4:	a011                	j	800019c8 <copyout+0x8e>
      return -1;
    800019c6:	557d                	li	a0,-1
}
    800019c8:	60a6                	ld	ra,72(sp)
    800019ca:	6406                	ld	s0,64(sp)
    800019cc:	74e2                	ld	s1,56(sp)
    800019ce:	7942                	ld	s2,48(sp)
    800019d0:	79a2                	ld	s3,40(sp)
    800019d2:	7a02                	ld	s4,32(sp)
    800019d4:	6ae2                	ld	s5,24(sp)
    800019d6:	6b42                	ld	s6,16(sp)
    800019d8:	6ba2                	ld	s7,8(sp)
    800019da:	6c02                	ld	s8,0(sp)
    800019dc:	6161                	addi	sp,sp,80
    800019de:	8082                	ret

00000000800019e0 <copyin>:
{
    800019e0:	715d                	addi	sp,sp,-80
    800019e2:	e486                	sd	ra,72(sp)
    800019e4:	e0a2                	sd	s0,64(sp)
    800019e6:	fc26                	sd	s1,56(sp)
    800019e8:	f84a                	sd	s2,48(sp)
    800019ea:	f44e                	sd	s3,40(sp)
    800019ec:	f052                	sd	s4,32(sp)
    800019ee:	ec56                	sd	s5,24(sp)
    800019f0:	e85a                	sd	s6,16(sp)
    800019f2:	e45e                	sd	s7,8(sp)
    800019f4:	e062                	sd	s8,0(sp)
    800019f6:	0880                	addi	s0,sp,80
    800019f8:	8b2a                	mv	s6,a0
    800019fa:	8a2e                	mv	s4,a1
    800019fc:	8c32                	mv	s8,a2
    800019fe:	89b6                	mv	s3,a3
  if(uvmshouldtouch(srcva))
    80001a00:	8532                	mv	a0,a2
    80001a02:	00000097          	auipc	ra,0x0
    80001a06:	ee6080e7          	jalr	-282(ra) # 800018e8 <uvmshouldtouch>
    80001a0a:	e511                	bnez	a0,80001a16 <copyin+0x36>
  while(len > 0){
    80001a0c:	04098e63          	beqz	s3,80001a68 <copyin+0x88>
    va0 = PGROUNDDOWN(srcva);
    80001a10:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (srcva - va0);
    80001a12:	6a85                	lui	s5,0x1
    80001a14:	a805                	j	80001a44 <copyin+0x64>
    uvmlazytouch(srcva);
    80001a16:	8562                	mv	a0,s8
    80001a18:	00000097          	auipc	ra,0x0
    80001a1c:	e3c080e7          	jalr	-452(ra) # 80001854 <uvmlazytouch>
    80001a20:	b7f5                	j	80001a0c <copyin+0x2c>
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001a22:	9562                	add	a0,a0,s8
    80001a24:	0004861b          	sext.w	a2,s1
    80001a28:	412505b3          	sub	a1,a0,s2
    80001a2c:	8552                	mv	a0,s4
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	34c080e7          	jalr	844(ra) # 80000d7a <memmove>
    len -= n;
    80001a36:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001a3a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001a3c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a40:	02098263          	beqz	s3,80001a64 <copyin+0x84>
    va0 = PGROUNDDOWN(srcva);
    80001a44:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a48:	85ca                	mv	a1,s2
    80001a4a:	855a                	mv	a0,s6
    80001a4c:	fffff097          	auipc	ra,0xfffff
    80001a50:	660080e7          	jalr	1632(ra) # 800010ac <walkaddr>
    if(pa0 == 0)
    80001a54:	cd01                	beqz	a0,80001a6c <copyin+0x8c>
    n = PGSIZE - (srcva - va0);
    80001a56:	418904b3          	sub	s1,s2,s8
    80001a5a:	94d6                	add	s1,s1,s5
    if(n > len)
    80001a5c:	fc99f3e3          	bgeu	s3,s1,80001a22 <copyin+0x42>
    80001a60:	84ce                	mv	s1,s3
    80001a62:	b7c1                	j	80001a22 <copyin+0x42>
  return 0;
    80001a64:	4501                	li	a0,0
    80001a66:	a021                	j	80001a6e <copyin+0x8e>
    80001a68:	4501                	li	a0,0
    80001a6a:	a011                	j	80001a6e <copyin+0x8e>
      return -1;
    80001a6c:	557d                	li	a0,-1
}
    80001a6e:	60a6                	ld	ra,72(sp)
    80001a70:	6406                	ld	s0,64(sp)
    80001a72:	74e2                	ld	s1,56(sp)
    80001a74:	7942                	ld	s2,48(sp)
    80001a76:	79a2                	ld	s3,40(sp)
    80001a78:	7a02                	ld	s4,32(sp)
    80001a7a:	6ae2                	ld	s5,24(sp)
    80001a7c:	6b42                	ld	s6,16(sp)
    80001a7e:	6ba2                	ld	s7,8(sp)
    80001a80:	6c02                	ld	s8,0(sp)
    80001a82:	6161                	addi	sp,sp,80
    80001a84:	8082                	ret

0000000080001a86 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a86:	1101                	addi	sp,sp,-32
    80001a88:	ec06                	sd	ra,24(sp)
    80001a8a:	e822                	sd	s0,16(sp)
    80001a8c:	e426                	sd	s1,8(sp)
    80001a8e:	1000                	addi	s0,sp,32
    80001a90:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	112080e7          	jalr	274(ra) # 80000ba4 <holding>
    80001a9a:	c909                	beqz	a0,80001aac <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a9c:	749c                	ld	a5,40(s1)
    80001a9e:	00978f63          	beq	a5,s1,80001abc <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001aa2:	60e2                	ld	ra,24(sp)
    80001aa4:	6442                	ld	s0,16(sp)
    80001aa6:	64a2                	ld	s1,8(sp)
    80001aa8:	6105                	addi	sp,sp,32
    80001aaa:	8082                	ret
    panic("wakeup1");
    80001aac:	00006517          	auipc	a0,0x6
    80001ab0:	72c50513          	addi	a0,a0,1836 # 800081d8 <digits+0x198>
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	aa2080e7          	jalr	-1374(ra) # 80000556 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001abc:	4c98                	lw	a4,24(s1)
    80001abe:	4785                	li	a5,1
    80001ac0:	fef711e3          	bne	a4,a5,80001aa2 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001ac4:	4789                	li	a5,2
    80001ac6:	cc9c                	sw	a5,24(s1)
}
    80001ac8:	bfe9                	j	80001aa2 <wakeup1+0x1c>

0000000080001aca <procinit>:
{
    80001aca:	715d                	addi	sp,sp,-80
    80001acc:	e486                	sd	ra,72(sp)
    80001ace:	e0a2                	sd	s0,64(sp)
    80001ad0:	fc26                	sd	s1,56(sp)
    80001ad2:	f84a                	sd	s2,48(sp)
    80001ad4:	f44e                	sd	s3,40(sp)
    80001ad6:	f052                	sd	s4,32(sp)
    80001ad8:	ec56                	sd	s5,24(sp)
    80001ada:	e85a                	sd	s6,16(sp)
    80001adc:	e45e                	sd	s7,8(sp)
    80001ade:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001ae0:	00006597          	auipc	a1,0x6
    80001ae4:	70058593          	addi	a1,a1,1792 # 800081e0 <digits+0x1a0>
    80001ae8:	00010517          	auipc	a0,0x10
    80001aec:	e6850513          	addi	a0,a0,-408 # 80011950 <pid_lock>
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	09e080e7          	jalr	158(ra) # 80000b8e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001af8:	00010917          	auipc	s2,0x10
    80001afc:	27090913          	addi	s2,s2,624 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001b00:	00006b97          	auipc	s7,0x6
    80001b04:	6e8b8b93          	addi	s7,s7,1768 # 800081e8 <digits+0x1a8>
      uint64 va = KSTACK((int) (p - proc));
    80001b08:	8b4a                	mv	s6,s2
    80001b0a:	00006a97          	auipc	s5,0x6
    80001b0e:	4f6a8a93          	addi	s5,s5,1270 # 80008000 <etext>
    80001b12:	040009b7          	lui	s3,0x4000
    80001b16:	19fd                	addi	s3,s3,-1
    80001b18:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b1a:	00016a17          	auipc	s4,0x16
    80001b1e:	c4ea0a13          	addi	s4,s4,-946 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001b22:	85de                	mv	a1,s7
    80001b24:	854a                	mv	a0,s2
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	068080e7          	jalr	104(ra) # 80000b8e <initlock>
      char *pa = kalloc();
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	000080e7          	jalr	ra # 80000b2e <kalloc>
    80001b36:	85aa                	mv	a1,a0
      if(pa == 0)
    80001b38:	c929                	beqz	a0,80001b8a <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001b3a:	416904b3          	sub	s1,s2,s6
    80001b3e:	848d                	srai	s1,s1,0x3
    80001b40:	000ab783          	ld	a5,0(s5)
    80001b44:	02f484b3          	mul	s1,s1,a5
    80001b48:	2485                	addiw	s1,s1,1
    80001b4a:	00d4949b          	slliw	s1,s1,0xd
    80001b4e:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b52:	4699                	li	a3,6
    80001b54:	6605                	lui	a2,0x1
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	682080e7          	jalr	1666(ra) # 800011da <kvmmap>
      p->kstack = va;
    80001b60:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b64:	16890913          	addi	s2,s2,360
    80001b68:	fb491de3          	bne	s2,s4,80001b22 <procinit+0x58>
  kvminithart();
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	476080e7          	jalr	1142(ra) # 80000fe2 <kvminithart>
}
    80001b74:	60a6                	ld	ra,72(sp)
    80001b76:	6406                	ld	s0,64(sp)
    80001b78:	74e2                	ld	s1,56(sp)
    80001b7a:	7942                	ld	s2,48(sp)
    80001b7c:	79a2                	ld	s3,40(sp)
    80001b7e:	7a02                	ld	s4,32(sp)
    80001b80:	6ae2                	ld	s5,24(sp)
    80001b82:	6b42                	ld	s6,16(sp)
    80001b84:	6ba2                	ld	s7,8(sp)
    80001b86:	6161                	addi	sp,sp,80
    80001b88:	8082                	ret
        panic("kalloc");
    80001b8a:	00006517          	auipc	a0,0x6
    80001b8e:	66650513          	addi	a0,a0,1638 # 800081f0 <digits+0x1b0>
    80001b92:	fffff097          	auipc	ra,0xfffff
    80001b96:	9c4080e7          	jalr	-1596(ra) # 80000556 <panic>

0000000080001b9a <cpuid>:
{
    80001b9a:	1141                	addi	sp,sp,-16
    80001b9c:	e422                	sd	s0,8(sp)
    80001b9e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ba0:	8512                	mv	a0,tp
}
    80001ba2:	2501                	sext.w	a0,a0
    80001ba4:	6422                	ld	s0,8(sp)
    80001ba6:	0141                	addi	sp,sp,16
    80001ba8:	8082                	ret

0000000080001baa <mycpu>:
mycpu(void) {
    80001baa:	1141                	addi	sp,sp,-16
    80001bac:	e422                	sd	s0,8(sp)
    80001bae:	0800                	addi	s0,sp,16
    80001bb0:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001bb2:	2781                	sext.w	a5,a5
    80001bb4:	079e                	slli	a5,a5,0x7
}
    80001bb6:	00010517          	auipc	a0,0x10
    80001bba:	db250513          	addi	a0,a0,-590 # 80011968 <cpus>
    80001bbe:	953e                	add	a0,a0,a5
    80001bc0:	6422                	ld	s0,8(sp)
    80001bc2:	0141                	addi	sp,sp,16
    80001bc4:	8082                	ret

0000000080001bc6 <myproc>:
myproc(void) {
    80001bc6:	1101                	addi	sp,sp,-32
    80001bc8:	ec06                	sd	ra,24(sp)
    80001bca:	e822                	sd	s0,16(sp)
    80001bcc:	e426                	sd	s1,8(sp)
    80001bce:	1000                	addi	s0,sp,32
  push_off();
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	002080e7          	jalr	2(ra) # 80000bd2 <push_off>
    80001bd8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001bda:	2781                	sext.w	a5,a5
    80001bdc:	079e                	slli	a5,a5,0x7
    80001bde:	00010717          	auipc	a4,0x10
    80001be2:	d7270713          	addi	a4,a4,-654 # 80011950 <pid_lock>
    80001be6:	97ba                	add	a5,a5,a4
    80001be8:	6f84                	ld	s1,24(a5)
  pop_off();
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	088080e7          	jalr	136(ra) # 80000c72 <pop_off>
}
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	60e2                	ld	ra,24(sp)
    80001bf6:	6442                	ld	s0,16(sp)
    80001bf8:	64a2                	ld	s1,8(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret

0000000080001bfe <forkret>:
{
    80001bfe:	1141                	addi	sp,sp,-16
    80001c00:	e406                	sd	ra,8(sp)
    80001c02:	e022                	sd	s0,0(sp)
    80001c04:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001c06:	00000097          	auipc	ra,0x0
    80001c0a:	fc0080e7          	jalr	-64(ra) # 80001bc6 <myproc>
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	0c4080e7          	jalr	196(ra) # 80000cd2 <release>
  if (first) {
    80001c16:	00007797          	auipc	a5,0x7
    80001c1a:	c0a7a783          	lw	a5,-1014(a5) # 80008820 <first.1674>
    80001c1e:	eb89                	bnez	a5,80001c30 <forkret+0x32>
  usertrapret();
    80001c20:	00001097          	auipc	ra,0x1
    80001c24:	c1c080e7          	jalr	-996(ra) # 8000283c <usertrapret>
}
    80001c28:	60a2                	ld	ra,8(sp)
    80001c2a:	6402                	ld	s0,0(sp)
    80001c2c:	0141                	addi	sp,sp,16
    80001c2e:	8082                	ret
    first = 0;
    80001c30:	00007797          	auipc	a5,0x7
    80001c34:	be07a823          	sw	zero,-1040(a5) # 80008820 <first.1674>
    fsinit(ROOTDEV);
    80001c38:	4505                	li	a0,1
    80001c3a:	00002097          	auipc	ra,0x2
    80001c3e:	98e080e7          	jalr	-1650(ra) # 800035c8 <fsinit>
    80001c42:	bff9                	j	80001c20 <forkret+0x22>

0000000080001c44 <allocpid>:
allocpid() {
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	e04a                	sd	s2,0(sp)
    80001c4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c50:	00010917          	auipc	s2,0x10
    80001c54:	d0090913          	addi	s2,s2,-768 # 80011950 <pid_lock>
    80001c58:	854a                	mv	a0,s2
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	fc4080e7          	jalr	-60(ra) # 80000c1e <acquire>
  pid = nextpid;
    80001c62:	00007797          	auipc	a5,0x7
    80001c66:	bc278793          	addi	a5,a5,-1086 # 80008824 <nextpid>
    80001c6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c6c:	0014871b          	addiw	a4,s1,1
    80001c70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c72:	854a                	mv	a0,s2
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	05e080e7          	jalr	94(ra) # 80000cd2 <release>
}
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6902                	ld	s2,0(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret

0000000080001c8a <proc_pagetable>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	e04a                	sd	s2,0(sp)
    80001c94:	1000                	addi	s0,sp,32
    80001c96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6f2080e7          	jalr	1778(ra) # 8000138a <uvmcreate>
    80001ca0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ca2:	c121                	beqz	a0,80001ce2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ca4:	4729                	li	a4,10
    80001ca6:	00005697          	auipc	a3,0x5
    80001caa:	35a68693          	addi	a3,a3,858 # 80007000 <_trampoline>
    80001cae:	6605                	lui	a2,0x1
    80001cb0:	040005b7          	lui	a1,0x4000
    80001cb4:	15fd                	addi	a1,a1,-1
    80001cb6:	05b2                	slli	a1,a1,0xc
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	494080e7          	jalr	1172(ra) # 8000114c <mappages>
    80001cc0:	02054863          	bltz	a0,80001cf0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cc4:	4719                	li	a4,6
    80001cc6:	05893683          	ld	a3,88(s2)
    80001cca:	6605                	lui	a2,0x1
    80001ccc:	020005b7          	lui	a1,0x2000
    80001cd0:	15fd                	addi	a1,a1,-1
    80001cd2:	05b6                	slli	a1,a1,0xd
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	476080e7          	jalr	1142(ra) # 8000114c <mappages>
    80001cde:	02054163          	bltz	a0,80001d00 <proc_pagetable+0x76>
}
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	60e2                	ld	ra,24(sp)
    80001ce6:	6442                	ld	s0,16(sp)
    80001ce8:	64a2                	ld	s1,8(sp)
    80001cea:	6902                	ld	s2,0(sp)
    80001cec:	6105                	addi	sp,sp,32
    80001cee:	8082                	ret
    uvmfree(pagetable, 0);
    80001cf0:	4581                	li	a1,0
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	892080e7          	jalr	-1902(ra) # 80001586 <uvmfree>
    return 0;
    80001cfc:	4481                	li	s1,0
    80001cfe:	b7d5                	j	80001ce2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d00:	4681                	li	a3,0
    80001d02:	4605                	li	a2,1
    80001d04:	040005b7          	lui	a1,0x4000
    80001d08:	15fd                	addi	a1,a1,-1
    80001d0a:	05b2                	slli	a1,a1,0xc
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	5d6080e7          	jalr	1494(ra) # 800012e4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d16:	4581                	li	a1,0
    80001d18:	8526                	mv	a0,s1
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	86c080e7          	jalr	-1940(ra) # 80001586 <uvmfree>
    return 0;
    80001d22:	4481                	li	s1,0
    80001d24:	bf7d                	j	80001ce2 <proc_pagetable+0x58>

0000000080001d26 <proc_freepagetable>:
{
    80001d26:	1101                	addi	sp,sp,-32
    80001d28:	ec06                	sd	ra,24(sp)
    80001d2a:	e822                	sd	s0,16(sp)
    80001d2c:	e426                	sd	s1,8(sp)
    80001d2e:	e04a                	sd	s2,0(sp)
    80001d30:	1000                	addi	s0,sp,32
    80001d32:	84aa                	mv	s1,a0
    80001d34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d36:	4681                	li	a3,0
    80001d38:	4605                	li	a2,1
    80001d3a:	040005b7          	lui	a1,0x4000
    80001d3e:	15fd                	addi	a1,a1,-1
    80001d40:	05b2                	slli	a1,a1,0xc
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	5a2080e7          	jalr	1442(ra) # 800012e4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d4a:	4681                	li	a3,0
    80001d4c:	4605                	li	a2,1
    80001d4e:	020005b7          	lui	a1,0x2000
    80001d52:	15fd                	addi	a1,a1,-1
    80001d54:	05b6                	slli	a1,a1,0xd
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	58c080e7          	jalr	1420(ra) # 800012e4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d60:	85ca                	mv	a1,s2
    80001d62:	8526                	mv	a0,s1
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	822080e7          	jalr	-2014(ra) # 80001586 <uvmfree>
}
    80001d6c:	60e2                	ld	ra,24(sp)
    80001d6e:	6442                	ld	s0,16(sp)
    80001d70:	64a2                	ld	s1,8(sp)
    80001d72:	6902                	ld	s2,0(sp)
    80001d74:	6105                	addi	sp,sp,32
    80001d76:	8082                	ret

0000000080001d78 <freeproc>:
{
    80001d78:	1101                	addi	sp,sp,-32
    80001d7a:	ec06                	sd	ra,24(sp)
    80001d7c:	e822                	sd	s0,16(sp)
    80001d7e:	e426                	sd	s1,8(sp)
    80001d80:	1000                	addi	s0,sp,32
    80001d82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d84:	6d28                	ld	a0,88(a0)
    80001d86:	c509                	beqz	a0,80001d90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d88:	fffff097          	auipc	ra,0xfffff
    80001d8c:	caa080e7          	jalr	-854(ra) # 80000a32 <kfree>
  p->trapframe = 0;
    80001d90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d94:	68a8                	ld	a0,80(s1)
    80001d96:	c511                	beqz	a0,80001da2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d98:	64ac                	ld	a1,72(s1)
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	f8c080e7          	jalr	-116(ra) # 80001d26 <proc_freepagetable>
  p->pagetable = 0;
    80001da2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001da6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001daa:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001dae:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001db2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001db6:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001dba:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001dbe:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001dc2:	0004ac23          	sw	zero,24(s1)
}
    80001dc6:	60e2                	ld	ra,24(sp)
    80001dc8:	6442                	ld	s0,16(sp)
    80001dca:	64a2                	ld	s1,8(sp)
    80001dcc:	6105                	addi	sp,sp,32
    80001dce:	8082                	ret

0000000080001dd0 <allocproc>:
{
    80001dd0:	1101                	addi	sp,sp,-32
    80001dd2:	ec06                	sd	ra,24(sp)
    80001dd4:	e822                	sd	s0,16(sp)
    80001dd6:	e426                	sd	s1,8(sp)
    80001dd8:	e04a                	sd	s2,0(sp)
    80001dda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ddc:	00010497          	auipc	s1,0x10
    80001de0:	f8c48493          	addi	s1,s1,-116 # 80011d68 <proc>
    80001de4:	00016917          	auipc	s2,0x16
    80001de8:	98490913          	addi	s2,s2,-1660 # 80017768 <tickslock>
    acquire(&p->lock);
    80001dec:	8526                	mv	a0,s1
    80001dee:	fffff097          	auipc	ra,0xfffff
    80001df2:	e30080e7          	jalr	-464(ra) # 80000c1e <acquire>
    if(p->state == UNUSED) {
    80001df6:	4c9c                	lw	a5,24(s1)
    80001df8:	cf81                	beqz	a5,80001e10 <allocproc+0x40>
      release(&p->lock);
    80001dfa:	8526                	mv	a0,s1
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	ed6080e7          	jalr	-298(ra) # 80000cd2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e04:	16848493          	addi	s1,s1,360
    80001e08:	ff2492e3          	bne	s1,s2,80001dec <allocproc+0x1c>
  return 0;
    80001e0c:	4481                	li	s1,0
    80001e0e:	a0b9                	j	80001e5c <allocproc+0x8c>
  p->pid = allocpid();
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	e34080e7          	jalr	-460(ra) # 80001c44 <allocpid>
    80001e18:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	d14080e7          	jalr	-748(ra) # 80000b2e <kalloc>
    80001e22:	892a                	mv	s2,a0
    80001e24:	eca8                	sd	a0,88(s1)
    80001e26:	c131                	beqz	a0,80001e6a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001e28:	8526                	mv	a0,s1
    80001e2a:	00000097          	auipc	ra,0x0
    80001e2e:	e60080e7          	jalr	-416(ra) # 80001c8a <proc_pagetable>
    80001e32:	892a                	mv	s2,a0
    80001e34:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e36:	c129                	beqz	a0,80001e78 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001e38:	07000613          	li	a2,112
    80001e3c:	4581                	li	a1,0
    80001e3e:	06048513          	addi	a0,s1,96
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	ed8080e7          	jalr	-296(ra) # 80000d1a <memset>
  p->context.ra = (uint64)forkret;
    80001e4a:	00000797          	auipc	a5,0x0
    80001e4e:	db478793          	addi	a5,a5,-588 # 80001bfe <forkret>
    80001e52:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e54:	60bc                	ld	a5,64(s1)
    80001e56:	6705                	lui	a4,0x1
    80001e58:	97ba                	add	a5,a5,a4
    80001e5a:	f4bc                	sd	a5,104(s1)
}
    80001e5c:	8526                	mv	a0,s1
    80001e5e:	60e2                	ld	ra,24(sp)
    80001e60:	6442                	ld	s0,16(sp)
    80001e62:	64a2                	ld	s1,8(sp)
    80001e64:	6902                	ld	s2,0(sp)
    80001e66:	6105                	addi	sp,sp,32
    80001e68:	8082                	ret
    release(&p->lock);
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e66080e7          	jalr	-410(ra) # 80000cd2 <release>
    return 0;
    80001e74:	84ca                	mv	s1,s2
    80001e76:	b7dd                	j	80001e5c <allocproc+0x8c>
    freeproc(p);
    80001e78:	8526                	mv	a0,s1
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	efe080e7          	jalr	-258(ra) # 80001d78 <freeproc>
    release(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e4e080e7          	jalr	-434(ra) # 80000cd2 <release>
    return 0;
    80001e8c:	84ca                	mv	s1,s2
    80001e8e:	b7f9                	j	80001e5c <allocproc+0x8c>

0000000080001e90 <userinit>:
{
    80001e90:	1101                	addi	sp,sp,-32
    80001e92:	ec06                	sd	ra,24(sp)
    80001e94:	e822                	sd	s0,16(sp)
    80001e96:	e426                	sd	s1,8(sp)
    80001e98:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	f36080e7          	jalr	-202(ra) # 80001dd0 <allocproc>
    80001ea2:	84aa                	mv	s1,a0
  initproc = p;
    80001ea4:	00007797          	auipc	a5,0x7
    80001ea8:	16a7ba23          	sd	a0,372(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001eac:	03400613          	li	a2,52
    80001eb0:	00007597          	auipc	a1,0x7
    80001eb4:	98058593          	addi	a1,a1,-1664 # 80008830 <initcode>
    80001eb8:	6928                	ld	a0,80(a0)
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	4fe080e7          	jalr	1278(ra) # 800013b8 <uvminit>
  p->sz = PGSIZE;
    80001ec2:	6785                	lui	a5,0x1
    80001ec4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ec6:	6cb8                	ld	a4,88(s1)
    80001ec8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001ecc:	6cb8                	ld	a4,88(s1)
    80001ece:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ed0:	4641                	li	a2,16
    80001ed2:	00006597          	auipc	a1,0x6
    80001ed6:	32658593          	addi	a1,a1,806 # 800081f8 <digits+0x1b8>
    80001eda:	15848513          	addi	a0,s1,344
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	f92080e7          	jalr	-110(ra) # 80000e70 <safestrcpy>
  p->cwd = namei("/");
    80001ee6:	00006517          	auipc	a0,0x6
    80001eea:	32250513          	addi	a0,a0,802 # 80008208 <digits+0x1c8>
    80001eee:	00002097          	auipc	ra,0x2
    80001ef2:	106080e7          	jalr	262(ra) # 80003ff4 <namei>
    80001ef6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001efa:	4789                	li	a5,2
    80001efc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	dd2080e7          	jalr	-558(ra) # 80000cd2 <release>
}
    80001f08:	60e2                	ld	ra,24(sp)
    80001f0a:	6442                	ld	s0,16(sp)
    80001f0c:	64a2                	ld	s1,8(sp)
    80001f0e:	6105                	addi	sp,sp,32
    80001f10:	8082                	ret

0000000080001f12 <growproc>:
{
    80001f12:	1101                	addi	sp,sp,-32
    80001f14:	ec06                	sd	ra,24(sp)
    80001f16:	e822                	sd	s0,16(sp)
    80001f18:	e426                	sd	s1,8(sp)
    80001f1a:	e04a                	sd	s2,0(sp)
    80001f1c:	1000                	addi	s0,sp,32
    80001f1e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f20:	00000097          	auipc	ra,0x0
    80001f24:	ca6080e7          	jalr	-858(ra) # 80001bc6 <myproc>
    80001f28:	892a                	mv	s2,a0
  sz = p->sz;
    80001f2a:	652c                	ld	a1,72(a0)
    80001f2c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f30:	00904f63          	bgtz	s1,80001f4e <growproc+0x3c>
  } else if(n < 0){
    80001f34:	0204cc63          	bltz	s1,80001f6c <growproc+0x5a>
  p->sz = sz;
    80001f38:	1602                	slli	a2,a2,0x20
    80001f3a:	9201                	srli	a2,a2,0x20
    80001f3c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f40:	4501                	li	a0,0
}
    80001f42:	60e2                	ld	ra,24(sp)
    80001f44:	6442                	ld	s0,16(sp)
    80001f46:	64a2                	ld	s1,8(sp)
    80001f48:	6902                	ld	s2,0(sp)
    80001f4a:	6105                	addi	sp,sp,32
    80001f4c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f4e:	9e25                	addw	a2,a2,s1
    80001f50:	1602                	slli	a2,a2,0x20
    80001f52:	9201                	srli	a2,a2,0x20
    80001f54:	1582                	slli	a1,a1,0x20
    80001f56:	9181                	srli	a1,a1,0x20
    80001f58:	6928                	ld	a0,80(a0)
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	518080e7          	jalr	1304(ra) # 80001472 <uvmalloc>
    80001f62:	0005061b          	sext.w	a2,a0
    80001f66:	fa69                	bnez	a2,80001f38 <growproc+0x26>
      return -1;
    80001f68:	557d                	li	a0,-1
    80001f6a:	bfe1                	j	80001f42 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f6c:	9e25                	addw	a2,a2,s1
    80001f6e:	1602                	slli	a2,a2,0x20
    80001f70:	9201                	srli	a2,a2,0x20
    80001f72:	1582                	slli	a1,a1,0x20
    80001f74:	9181                	srli	a1,a1,0x20
    80001f76:	6928                	ld	a0,80(a0)
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	4b2080e7          	jalr	1202(ra) # 8000142a <uvmdealloc>
    80001f80:	0005061b          	sext.w	a2,a0
    80001f84:	bf55                	j	80001f38 <growproc+0x26>

0000000080001f86 <fork>:
{
    80001f86:	7179                	addi	sp,sp,-48
    80001f88:	f406                	sd	ra,40(sp)
    80001f8a:	f022                	sd	s0,32(sp)
    80001f8c:	ec26                	sd	s1,24(sp)
    80001f8e:	e84a                	sd	s2,16(sp)
    80001f90:	e44e                	sd	s3,8(sp)
    80001f92:	e052                	sd	s4,0(sp)
    80001f94:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f96:	00000097          	auipc	ra,0x0
    80001f9a:	c30080e7          	jalr	-976(ra) # 80001bc6 <myproc>
    80001f9e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	e30080e7          	jalr	-464(ra) # 80001dd0 <allocproc>
    80001fa8:	c175                	beqz	a0,8000208c <fork+0x106>
    80001faa:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001fac:	04893603          	ld	a2,72(s2)
    80001fb0:	692c                	ld	a1,80(a0)
    80001fb2:	05093503          	ld	a0,80(s2)
    80001fb6:	fffff097          	auipc	ra,0xfffff
    80001fba:	608080e7          	jalr	1544(ra) # 800015be <uvmcopy>
    80001fbe:	04054863          	bltz	a0,8000200e <fork+0x88>
  np->sz = p->sz;
    80001fc2:	04893783          	ld	a5,72(s2)
    80001fc6:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001fca:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001fce:	05893683          	ld	a3,88(s2)
    80001fd2:	87b6                	mv	a5,a3
    80001fd4:	0589b703          	ld	a4,88(s3)
    80001fd8:	12068693          	addi	a3,a3,288
    80001fdc:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fe0:	6788                	ld	a0,8(a5)
    80001fe2:	6b8c                	ld	a1,16(a5)
    80001fe4:	6f90                	ld	a2,24(a5)
    80001fe6:	01073023          	sd	a6,0(a4)
    80001fea:	e708                	sd	a0,8(a4)
    80001fec:	eb0c                	sd	a1,16(a4)
    80001fee:	ef10                	sd	a2,24(a4)
    80001ff0:	02078793          	addi	a5,a5,32
    80001ff4:	02070713          	addi	a4,a4,32
    80001ff8:	fed792e3          	bne	a5,a3,80001fdc <fork+0x56>
  np->trapframe->a0 = 0;
    80001ffc:	0589b783          	ld	a5,88(s3)
    80002000:	0607b823          	sd	zero,112(a5)
    80002004:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002008:	15000a13          	li	s4,336
    8000200c:	a03d                	j	8000203a <fork+0xb4>
    freeproc(np);
    8000200e:	854e                	mv	a0,s3
    80002010:	00000097          	auipc	ra,0x0
    80002014:	d68080e7          	jalr	-664(ra) # 80001d78 <freeproc>
    release(&np->lock);
    80002018:	854e                	mv	a0,s3
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	cb8080e7          	jalr	-840(ra) # 80000cd2 <release>
    return -1;
    80002022:	54fd                	li	s1,-1
    80002024:	a899                	j	8000207a <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002026:	00002097          	auipc	ra,0x2
    8000202a:	65a080e7          	jalr	1626(ra) # 80004680 <filedup>
    8000202e:	009987b3          	add	a5,s3,s1
    80002032:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002034:	04a1                	addi	s1,s1,8
    80002036:	01448763          	beq	s1,s4,80002044 <fork+0xbe>
    if(p->ofile[i])
    8000203a:	009907b3          	add	a5,s2,s1
    8000203e:	6388                	ld	a0,0(a5)
    80002040:	f17d                	bnez	a0,80002026 <fork+0xa0>
    80002042:	bfcd                	j	80002034 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002044:	15093503          	ld	a0,336(s2)
    80002048:	00001097          	auipc	ra,0x1
    8000204c:	7ba080e7          	jalr	1978(ra) # 80003802 <idup>
    80002050:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002054:	4641                	li	a2,16
    80002056:	15890593          	addi	a1,s2,344
    8000205a:	15898513          	addi	a0,s3,344
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	e12080e7          	jalr	-494(ra) # 80000e70 <safestrcpy>
  pid = np->pid;
    80002066:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    8000206a:	4789                	li	a5,2
    8000206c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002070:	854e                	mv	a0,s3
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	c60080e7          	jalr	-928(ra) # 80000cd2 <release>
}
    8000207a:	8526                	mv	a0,s1
    8000207c:	70a2                	ld	ra,40(sp)
    8000207e:	7402                	ld	s0,32(sp)
    80002080:	64e2                	ld	s1,24(sp)
    80002082:	6942                	ld	s2,16(sp)
    80002084:	69a2                	ld	s3,8(sp)
    80002086:	6a02                	ld	s4,0(sp)
    80002088:	6145                	addi	sp,sp,48
    8000208a:	8082                	ret
    return -1;
    8000208c:	54fd                	li	s1,-1
    8000208e:	b7f5                	j	8000207a <fork+0xf4>

0000000080002090 <reparent>:
{
    80002090:	7179                	addi	sp,sp,-48
    80002092:	f406                	sd	ra,40(sp)
    80002094:	f022                	sd	s0,32(sp)
    80002096:	ec26                	sd	s1,24(sp)
    80002098:	e84a                	sd	s2,16(sp)
    8000209a:	e44e                	sd	s3,8(sp)
    8000209c:	e052                	sd	s4,0(sp)
    8000209e:	1800                	addi	s0,sp,48
    800020a0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020a2:	00010497          	auipc	s1,0x10
    800020a6:	cc648493          	addi	s1,s1,-826 # 80011d68 <proc>
      pp->parent = initproc;
    800020aa:	00007a17          	auipc	s4,0x7
    800020ae:	f6ea0a13          	addi	s4,s4,-146 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020b2:	00015997          	auipc	s3,0x15
    800020b6:	6b698993          	addi	s3,s3,1718 # 80017768 <tickslock>
    800020ba:	a029                	j	800020c4 <reparent+0x34>
    800020bc:	16848493          	addi	s1,s1,360
    800020c0:	03348363          	beq	s1,s3,800020e6 <reparent+0x56>
    if(pp->parent == p){
    800020c4:	709c                	ld	a5,32(s1)
    800020c6:	ff279be3          	bne	a5,s2,800020bc <reparent+0x2c>
      acquire(&pp->lock);
    800020ca:	8526                	mv	a0,s1
    800020cc:	fffff097          	auipc	ra,0xfffff
    800020d0:	b52080e7          	jalr	-1198(ra) # 80000c1e <acquire>
      pp->parent = initproc;
    800020d4:	000a3783          	ld	a5,0(s4)
    800020d8:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020da:	8526                	mv	a0,s1
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	bf6080e7          	jalr	-1034(ra) # 80000cd2 <release>
    800020e4:	bfe1                	j	800020bc <reparent+0x2c>
}
    800020e6:	70a2                	ld	ra,40(sp)
    800020e8:	7402                	ld	s0,32(sp)
    800020ea:	64e2                	ld	s1,24(sp)
    800020ec:	6942                	ld	s2,16(sp)
    800020ee:	69a2                	ld	s3,8(sp)
    800020f0:	6a02                	ld	s4,0(sp)
    800020f2:	6145                	addi	sp,sp,48
    800020f4:	8082                	ret

00000000800020f6 <scheduler>:
{
    800020f6:	711d                	addi	sp,sp,-96
    800020f8:	ec86                	sd	ra,88(sp)
    800020fa:	e8a2                	sd	s0,80(sp)
    800020fc:	e4a6                	sd	s1,72(sp)
    800020fe:	e0ca                	sd	s2,64(sp)
    80002100:	fc4e                	sd	s3,56(sp)
    80002102:	f852                	sd	s4,48(sp)
    80002104:	f456                	sd	s5,40(sp)
    80002106:	f05a                	sd	s6,32(sp)
    80002108:	ec5e                	sd	s7,24(sp)
    8000210a:	e862                	sd	s8,16(sp)
    8000210c:	e466                	sd	s9,8(sp)
    8000210e:	1080                	addi	s0,sp,96
    80002110:	8792                	mv	a5,tp
  int id = r_tp();
    80002112:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002114:	00779c13          	slli	s8,a5,0x7
    80002118:	00010717          	auipc	a4,0x10
    8000211c:	83870713          	addi	a4,a4,-1992 # 80011950 <pid_lock>
    80002120:	9762                	add	a4,a4,s8
    80002122:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002126:	00010717          	auipc	a4,0x10
    8000212a:	84a70713          	addi	a4,a4,-1974 # 80011970 <cpus+0x8>
    8000212e:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002130:	4a89                	li	s5,2
        c->proc = p;
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	00010b17          	auipc	s6,0x10
    80002138:	81cb0b13          	addi	s6,s6,-2020 # 80011950 <pid_lock>
    8000213c:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000213e:	00015a17          	auipc	s4,0x15
    80002142:	62aa0a13          	addi	s4,s4,1578 # 80017768 <tickslock>
    int nproc = 0;
    80002146:	4c81                	li	s9,0
    80002148:	a8a1                	j	800021a0 <scheduler+0xaa>
        p->state = RUNNING;
    8000214a:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    8000214e:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002152:	06048593          	addi	a1,s1,96
    80002156:	8562                	mv	a0,s8
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	63a080e7          	jalr	1594(ra) # 80002792 <swtch>
        c->proc = 0;
    80002160:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	b6c080e7          	jalr	-1172(ra) # 80000cd2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000216e:	16848493          	addi	s1,s1,360
    80002172:	01448d63          	beq	s1,s4,8000218c <scheduler+0x96>
      acquire(&p->lock);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	aa6080e7          	jalr	-1370(ra) # 80000c1e <acquire>
      if(p->state != UNUSED) {
    80002180:	4c9c                	lw	a5,24(s1)
    80002182:	d3ed                	beqz	a5,80002164 <scheduler+0x6e>
        nproc++;
    80002184:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002186:	fd579fe3          	bne	a5,s5,80002164 <scheduler+0x6e>
    8000218a:	b7c1                	j	8000214a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000218c:	013aca63          	blt	s5,s3,800021a0 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002190:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002194:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002198:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000219c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021a4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021a8:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800021ac:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800021ae:	00010497          	auipc	s1,0x10
    800021b2:	bba48493          	addi	s1,s1,-1094 # 80011d68 <proc>
        p->state = RUNNING;
    800021b6:	4b8d                	li	s7,3
    800021b8:	bf7d                	j	80002176 <scheduler+0x80>

00000000800021ba <sched>:
{
    800021ba:	7179                	addi	sp,sp,-48
    800021bc:	f406                	sd	ra,40(sp)
    800021be:	f022                	sd	s0,32(sp)
    800021c0:	ec26                	sd	s1,24(sp)
    800021c2:	e84a                	sd	s2,16(sp)
    800021c4:	e44e                	sd	s3,8(sp)
    800021c6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	9fe080e7          	jalr	-1538(ra) # 80001bc6 <myproc>
    800021d0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	9d2080e7          	jalr	-1582(ra) # 80000ba4 <holding>
    800021da:	c93d                	beqz	a0,80002250 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021dc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021de:	2781                	sext.w	a5,a5
    800021e0:	079e                	slli	a5,a5,0x7
    800021e2:	0000f717          	auipc	a4,0xf
    800021e6:	76e70713          	addi	a4,a4,1902 # 80011950 <pid_lock>
    800021ea:	97ba                	add	a5,a5,a4
    800021ec:	0907a703          	lw	a4,144(a5)
    800021f0:	4785                	li	a5,1
    800021f2:	06f71763          	bne	a4,a5,80002260 <sched+0xa6>
  if(p->state == RUNNING)
    800021f6:	4c98                	lw	a4,24(s1)
    800021f8:	478d                	li	a5,3
    800021fa:	06f70b63          	beq	a4,a5,80002270 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021fe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002202:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002204:	efb5                	bnez	a5,80002280 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002206:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002208:	0000f917          	auipc	s2,0xf
    8000220c:	74890913          	addi	s2,s2,1864 # 80011950 <pid_lock>
    80002210:	2781                	sext.w	a5,a5
    80002212:	079e                	slli	a5,a5,0x7
    80002214:	97ca                	add	a5,a5,s2
    80002216:	0947a983          	lw	s3,148(a5)
    8000221a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000221c:	2781                	sext.w	a5,a5
    8000221e:	079e                	slli	a5,a5,0x7
    80002220:	0000f597          	auipc	a1,0xf
    80002224:	75058593          	addi	a1,a1,1872 # 80011970 <cpus+0x8>
    80002228:	95be                	add	a1,a1,a5
    8000222a:	06048513          	addi	a0,s1,96
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	564080e7          	jalr	1380(ra) # 80002792 <swtch>
    80002236:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002238:	2781                	sext.w	a5,a5
    8000223a:	079e                	slli	a5,a5,0x7
    8000223c:	97ca                	add	a5,a5,s2
    8000223e:	0937aa23          	sw	s3,148(a5)
}
    80002242:	70a2                	ld	ra,40(sp)
    80002244:	7402                	ld	s0,32(sp)
    80002246:	64e2                	ld	s1,24(sp)
    80002248:	6942                	ld	s2,16(sp)
    8000224a:	69a2                	ld	s3,8(sp)
    8000224c:	6145                	addi	sp,sp,48
    8000224e:	8082                	ret
    panic("sched p->lock");
    80002250:	00006517          	auipc	a0,0x6
    80002254:	fc050513          	addi	a0,a0,-64 # 80008210 <digits+0x1d0>
    80002258:	ffffe097          	auipc	ra,0xffffe
    8000225c:	2fe080e7          	jalr	766(ra) # 80000556 <panic>
    panic("sched locks");
    80002260:	00006517          	auipc	a0,0x6
    80002264:	fc050513          	addi	a0,a0,-64 # 80008220 <digits+0x1e0>
    80002268:	ffffe097          	auipc	ra,0xffffe
    8000226c:	2ee080e7          	jalr	750(ra) # 80000556 <panic>
    panic("sched running");
    80002270:	00006517          	auipc	a0,0x6
    80002274:	fc050513          	addi	a0,a0,-64 # 80008230 <digits+0x1f0>
    80002278:	ffffe097          	auipc	ra,0xffffe
    8000227c:	2de080e7          	jalr	734(ra) # 80000556 <panic>
    panic("sched interruptible");
    80002280:	00006517          	auipc	a0,0x6
    80002284:	fc050513          	addi	a0,a0,-64 # 80008240 <digits+0x200>
    80002288:	ffffe097          	auipc	ra,0xffffe
    8000228c:	2ce080e7          	jalr	718(ra) # 80000556 <panic>

0000000080002290 <exit>:
{
    80002290:	7179                	addi	sp,sp,-48
    80002292:	f406                	sd	ra,40(sp)
    80002294:	f022                	sd	s0,32(sp)
    80002296:	ec26                	sd	s1,24(sp)
    80002298:	e84a                	sd	s2,16(sp)
    8000229a:	e44e                	sd	s3,8(sp)
    8000229c:	e052                	sd	s4,0(sp)
    8000229e:	1800                	addi	s0,sp,48
    800022a0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022a2:	00000097          	auipc	ra,0x0
    800022a6:	924080e7          	jalr	-1756(ra) # 80001bc6 <myproc>
    800022aa:	89aa                	mv	s3,a0
  if(p == initproc)
    800022ac:	00007797          	auipc	a5,0x7
    800022b0:	d6c7b783          	ld	a5,-660(a5) # 80009018 <initproc>
    800022b4:	0d050493          	addi	s1,a0,208
    800022b8:	15050913          	addi	s2,a0,336
    800022bc:	02a79363          	bne	a5,a0,800022e2 <exit+0x52>
    panic("init exiting");
    800022c0:	00006517          	auipc	a0,0x6
    800022c4:	f9850513          	addi	a0,a0,-104 # 80008258 <digits+0x218>
    800022c8:	ffffe097          	auipc	ra,0xffffe
    800022cc:	28e080e7          	jalr	654(ra) # 80000556 <panic>
      fileclose(f);
    800022d0:	00002097          	auipc	ra,0x2
    800022d4:	402080e7          	jalr	1026(ra) # 800046d2 <fileclose>
      p->ofile[fd] = 0;
    800022d8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022dc:	04a1                	addi	s1,s1,8
    800022de:	01248563          	beq	s1,s2,800022e8 <exit+0x58>
    if(p->ofile[fd]){
    800022e2:	6088                	ld	a0,0(s1)
    800022e4:	f575                	bnez	a0,800022d0 <exit+0x40>
    800022e6:	bfdd                	j	800022dc <exit+0x4c>
  begin_op();
    800022e8:	00002097          	auipc	ra,0x2
    800022ec:	f18080e7          	jalr	-232(ra) # 80004200 <begin_op>
  iput(p->cwd);
    800022f0:	1509b503          	ld	a0,336(s3)
    800022f4:	00001097          	auipc	ra,0x1
    800022f8:	706080e7          	jalr	1798(ra) # 800039fa <iput>
  end_op();
    800022fc:	00002097          	auipc	ra,0x2
    80002300:	f84080e7          	jalr	-124(ra) # 80004280 <end_op>
  p->cwd = 0;
    80002304:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002308:	00007497          	auipc	s1,0x7
    8000230c:	d1048493          	addi	s1,s1,-752 # 80009018 <initproc>
    80002310:	6088                	ld	a0,0(s1)
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	90c080e7          	jalr	-1780(ra) # 80000c1e <acquire>
  wakeup1(initproc);
    8000231a:	6088                	ld	a0,0(s1)
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	76a080e7          	jalr	1898(ra) # 80001a86 <wakeup1>
  release(&initproc->lock);
    80002324:	6088                	ld	a0,0(s1)
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	9ac080e7          	jalr	-1620(ra) # 80000cd2 <release>
  acquire(&p->lock);
    8000232e:	854e                	mv	a0,s3
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8ee080e7          	jalr	-1810(ra) # 80000c1e <acquire>
  struct proc *original_parent = p->parent;
    80002338:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000233c:	854e                	mv	a0,s3
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	994080e7          	jalr	-1644(ra) # 80000cd2 <release>
  acquire(&original_parent->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	8d6080e7          	jalr	-1834(ra) # 80000c1e <acquire>
  acquire(&p->lock);
    80002350:	854e                	mv	a0,s3
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	8cc080e7          	jalr	-1844(ra) # 80000c1e <acquire>
  reparent(p);
    8000235a:	854e                	mv	a0,s3
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	d34080e7          	jalr	-716(ra) # 80002090 <reparent>
  wakeup1(original_parent);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	720080e7          	jalr	1824(ra) # 80001a86 <wakeup1>
  p->xstate = status;
    8000236e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002372:	4791                	li	a5,4
    80002374:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002378:	8526                	mv	a0,s1
    8000237a:	fffff097          	auipc	ra,0xfffff
    8000237e:	958080e7          	jalr	-1704(ra) # 80000cd2 <release>
  sched();
    80002382:	00000097          	auipc	ra,0x0
    80002386:	e38080e7          	jalr	-456(ra) # 800021ba <sched>
  panic("zombie exit");
    8000238a:	00006517          	auipc	a0,0x6
    8000238e:	ede50513          	addi	a0,a0,-290 # 80008268 <digits+0x228>
    80002392:	ffffe097          	auipc	ra,0xffffe
    80002396:	1c4080e7          	jalr	452(ra) # 80000556 <panic>

000000008000239a <yield>:
{
    8000239a:	1101                	addi	sp,sp,-32
    8000239c:	ec06                	sd	ra,24(sp)
    8000239e:	e822                	sd	s0,16(sp)
    800023a0:	e426                	sd	s1,8(sp)
    800023a2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023a4:	00000097          	auipc	ra,0x0
    800023a8:	822080e7          	jalr	-2014(ra) # 80001bc6 <myproc>
    800023ac:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	870080e7          	jalr	-1936(ra) # 80000c1e <acquire>
  p->state = RUNNABLE;
    800023b6:	4789                	li	a5,2
    800023b8:	cc9c                	sw	a5,24(s1)
  sched();
    800023ba:	00000097          	auipc	ra,0x0
    800023be:	e00080e7          	jalr	-512(ra) # 800021ba <sched>
  release(&p->lock);
    800023c2:	8526                	mv	a0,s1
    800023c4:	fffff097          	auipc	ra,0xfffff
    800023c8:	90e080e7          	jalr	-1778(ra) # 80000cd2 <release>
}
    800023cc:	60e2                	ld	ra,24(sp)
    800023ce:	6442                	ld	s0,16(sp)
    800023d0:	64a2                	ld	s1,8(sp)
    800023d2:	6105                	addi	sp,sp,32
    800023d4:	8082                	ret

00000000800023d6 <sleep>:
{
    800023d6:	7179                	addi	sp,sp,-48
    800023d8:	f406                	sd	ra,40(sp)
    800023da:	f022                	sd	s0,32(sp)
    800023dc:	ec26                	sd	s1,24(sp)
    800023de:	e84a                	sd	s2,16(sp)
    800023e0:	e44e                	sd	s3,8(sp)
    800023e2:	1800                	addi	s0,sp,48
    800023e4:	89aa                	mv	s3,a0
    800023e6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	7de080e7          	jalr	2014(ra) # 80001bc6 <myproc>
    800023f0:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800023f2:	05250663          	beq	a0,s2,8000243e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	828080e7          	jalr	-2008(ra) # 80000c1e <acquire>
    release(lk);
    800023fe:	854a                	mv	a0,s2
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	8d2080e7          	jalr	-1838(ra) # 80000cd2 <release>
  p->chan = chan;
    80002408:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000240c:	4785                	li	a5,1
    8000240e:	cc9c                	sw	a5,24(s1)
  sched();
    80002410:	00000097          	auipc	ra,0x0
    80002414:	daa080e7          	jalr	-598(ra) # 800021ba <sched>
  p->chan = 0;
    80002418:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	8b4080e7          	jalr	-1868(ra) # 80000cd2 <release>
    acquire(lk);
    80002426:	854a                	mv	a0,s2
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	7f6080e7          	jalr	2038(ra) # 80000c1e <acquire>
}
    80002430:	70a2                	ld	ra,40(sp)
    80002432:	7402                	ld	s0,32(sp)
    80002434:	64e2                	ld	s1,24(sp)
    80002436:	6942                	ld	s2,16(sp)
    80002438:	69a2                	ld	s3,8(sp)
    8000243a:	6145                	addi	sp,sp,48
    8000243c:	8082                	ret
  p->chan = chan;
    8000243e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002442:	4785                	li	a5,1
    80002444:	cd1c                	sw	a5,24(a0)
  sched();
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	d74080e7          	jalr	-652(ra) # 800021ba <sched>
  p->chan = 0;
    8000244e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002452:	bff9                	j	80002430 <sleep+0x5a>

0000000080002454 <wait>:
{
    80002454:	715d                	addi	sp,sp,-80
    80002456:	e486                	sd	ra,72(sp)
    80002458:	e0a2                	sd	s0,64(sp)
    8000245a:	fc26                	sd	s1,56(sp)
    8000245c:	f84a                	sd	s2,48(sp)
    8000245e:	f44e                	sd	s3,40(sp)
    80002460:	f052                	sd	s4,32(sp)
    80002462:	ec56                	sd	s5,24(sp)
    80002464:	e85a                	sd	s6,16(sp)
    80002466:	e45e                	sd	s7,8(sp)
    80002468:	e062                	sd	s8,0(sp)
    8000246a:	0880                	addi	s0,sp,80
    8000246c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000246e:	fffff097          	auipc	ra,0xfffff
    80002472:	758080e7          	jalr	1880(ra) # 80001bc6 <myproc>
    80002476:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002478:	8c2a                	mv	s8,a0
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	7a4080e7          	jalr	1956(ra) # 80000c1e <acquire>
    havekids = 0;
    80002482:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002484:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002486:	00015997          	auipc	s3,0x15
    8000248a:	2e298993          	addi	s3,s3,738 # 80017768 <tickslock>
        havekids = 1;
    8000248e:	4a85                	li	s5,1
    havekids = 0;
    80002490:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002492:	00010497          	auipc	s1,0x10
    80002496:	8d648493          	addi	s1,s1,-1834 # 80011d68 <proc>
    8000249a:	a08d                	j	800024fc <wait+0xa8>
          pid = np->pid;
    8000249c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024a0:	000b0e63          	beqz	s6,800024bc <wait+0x68>
    800024a4:	4691                	li	a3,4
    800024a6:	03448613          	addi	a2,s1,52
    800024aa:	85da                	mv	a1,s6
    800024ac:	05093503          	ld	a0,80(s2)
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	48a080e7          	jalr	1162(ra) # 8000193a <copyout>
    800024b8:	02054263          	bltz	a0,800024dc <wait+0x88>
          freeproc(np);
    800024bc:	8526                	mv	a0,s1
    800024be:	00000097          	auipc	ra,0x0
    800024c2:	8ba080e7          	jalr	-1862(ra) # 80001d78 <freeproc>
          release(&np->lock);
    800024c6:	8526                	mv	a0,s1
    800024c8:	fffff097          	auipc	ra,0xfffff
    800024cc:	80a080e7          	jalr	-2038(ra) # 80000cd2 <release>
          release(&p->lock);
    800024d0:	854a                	mv	a0,s2
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	800080e7          	jalr	-2048(ra) # 80000cd2 <release>
          return pid;
    800024da:	a8a9                	j	80002534 <wait+0xe0>
            release(&np->lock);
    800024dc:	8526                	mv	a0,s1
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7f4080e7          	jalr	2036(ra) # 80000cd2 <release>
            release(&p->lock);
    800024e6:	854a                	mv	a0,s2
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7ea080e7          	jalr	2026(ra) # 80000cd2 <release>
            return -1;
    800024f0:	59fd                	li	s3,-1
    800024f2:	a089                	j	80002534 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800024f4:	16848493          	addi	s1,s1,360
    800024f8:	03348463          	beq	s1,s3,80002520 <wait+0xcc>
      if(np->parent == p){
    800024fc:	709c                	ld	a5,32(s1)
    800024fe:	ff279be3          	bne	a5,s2,800024f4 <wait+0xa0>
        acquire(&np->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	71a080e7          	jalr	1818(ra) # 80000c1e <acquire>
        if(np->state == ZOMBIE){
    8000250c:	4c9c                	lw	a5,24(s1)
    8000250e:	f94787e3          	beq	a5,s4,8000249c <wait+0x48>
        release(&np->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	7be080e7          	jalr	1982(ra) # 80000cd2 <release>
        havekids = 1;
    8000251c:	8756                	mv	a4,s5
    8000251e:	bfd9                	j	800024f4 <wait+0xa0>
    if(!havekids || p->killed){
    80002520:	c701                	beqz	a4,80002528 <wait+0xd4>
    80002522:	03092783          	lw	a5,48(s2)
    80002526:	c785                	beqz	a5,8000254e <wait+0xfa>
      release(&p->lock);
    80002528:	854a                	mv	a0,s2
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	7a8080e7          	jalr	1960(ra) # 80000cd2 <release>
      return -1;
    80002532:	59fd                	li	s3,-1
}
    80002534:	854e                	mv	a0,s3
    80002536:	60a6                	ld	ra,72(sp)
    80002538:	6406                	ld	s0,64(sp)
    8000253a:	74e2                	ld	s1,56(sp)
    8000253c:	7942                	ld	s2,48(sp)
    8000253e:	79a2                	ld	s3,40(sp)
    80002540:	7a02                	ld	s4,32(sp)
    80002542:	6ae2                	ld	s5,24(sp)
    80002544:	6b42                	ld	s6,16(sp)
    80002546:	6ba2                	ld	s7,8(sp)
    80002548:	6c02                	ld	s8,0(sp)
    8000254a:	6161                	addi	sp,sp,80
    8000254c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000254e:	85e2                	mv	a1,s8
    80002550:	854a                	mv	a0,s2
    80002552:	00000097          	auipc	ra,0x0
    80002556:	e84080e7          	jalr	-380(ra) # 800023d6 <sleep>
    havekids = 0;
    8000255a:	bf1d                	j	80002490 <wait+0x3c>

000000008000255c <wakeup>:
{
    8000255c:	7139                	addi	sp,sp,-64
    8000255e:	fc06                	sd	ra,56(sp)
    80002560:	f822                	sd	s0,48(sp)
    80002562:	f426                	sd	s1,40(sp)
    80002564:	f04a                	sd	s2,32(sp)
    80002566:	ec4e                	sd	s3,24(sp)
    80002568:	e852                	sd	s4,16(sp)
    8000256a:	e456                	sd	s5,8(sp)
    8000256c:	0080                	addi	s0,sp,64
    8000256e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002570:	0000f497          	auipc	s1,0xf
    80002574:	7f848493          	addi	s1,s1,2040 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002578:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000257a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000257c:	00015917          	auipc	s2,0x15
    80002580:	1ec90913          	addi	s2,s2,492 # 80017768 <tickslock>
    80002584:	a821                	j	8000259c <wakeup+0x40>
      p->state = RUNNABLE;
    80002586:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000258a:	8526                	mv	a0,s1
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	746080e7          	jalr	1862(ra) # 80000cd2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002594:	16848493          	addi	s1,s1,360
    80002598:	01248e63          	beq	s1,s2,800025b4 <wakeup+0x58>
    acquire(&p->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	680080e7          	jalr	1664(ra) # 80000c1e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800025a6:	4c9c                	lw	a5,24(s1)
    800025a8:	ff3791e3          	bne	a5,s3,8000258a <wakeup+0x2e>
    800025ac:	749c                	ld	a5,40(s1)
    800025ae:	fd479ee3          	bne	a5,s4,8000258a <wakeup+0x2e>
    800025b2:	bfd1                	j	80002586 <wakeup+0x2a>
}
    800025b4:	70e2                	ld	ra,56(sp)
    800025b6:	7442                	ld	s0,48(sp)
    800025b8:	74a2                	ld	s1,40(sp)
    800025ba:	7902                	ld	s2,32(sp)
    800025bc:	69e2                	ld	s3,24(sp)
    800025be:	6a42                	ld	s4,16(sp)
    800025c0:	6aa2                	ld	s5,8(sp)
    800025c2:	6121                	addi	sp,sp,64
    800025c4:	8082                	ret

00000000800025c6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025c6:	7179                	addi	sp,sp,-48
    800025c8:	f406                	sd	ra,40(sp)
    800025ca:	f022                	sd	s0,32(sp)
    800025cc:	ec26                	sd	s1,24(sp)
    800025ce:	e84a                	sd	s2,16(sp)
    800025d0:	e44e                	sd	s3,8(sp)
    800025d2:	1800                	addi	s0,sp,48
    800025d4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025d6:	0000f497          	auipc	s1,0xf
    800025da:	79248493          	addi	s1,s1,1938 # 80011d68 <proc>
    800025de:	00015997          	auipc	s3,0x15
    800025e2:	18a98993          	addi	s3,s3,394 # 80017768 <tickslock>
    acquire(&p->lock);
    800025e6:	8526                	mv	a0,s1
    800025e8:	ffffe097          	auipc	ra,0xffffe
    800025ec:	636080e7          	jalr	1590(ra) # 80000c1e <acquire>
    if(p->pid == pid){
    800025f0:	5c9c                	lw	a5,56(s1)
    800025f2:	01278d63          	beq	a5,s2,8000260c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025f6:	8526                	mv	a0,s1
    800025f8:	ffffe097          	auipc	ra,0xffffe
    800025fc:	6da080e7          	jalr	1754(ra) # 80000cd2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002600:	16848493          	addi	s1,s1,360
    80002604:	ff3491e3          	bne	s1,s3,800025e6 <kill+0x20>
  }
  return -1;
    80002608:	557d                	li	a0,-1
    8000260a:	a829                	j	80002624 <kill+0x5e>
      p->killed = 1;
    8000260c:	4785                	li	a5,1
    8000260e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002610:	4c98                	lw	a4,24(s1)
    80002612:	4785                	li	a5,1
    80002614:	00f70f63          	beq	a4,a5,80002632 <kill+0x6c>
      release(&p->lock);
    80002618:	8526                	mv	a0,s1
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	6b8080e7          	jalr	1720(ra) # 80000cd2 <release>
      return 0;
    80002622:	4501                	li	a0,0
}
    80002624:	70a2                	ld	ra,40(sp)
    80002626:	7402                	ld	s0,32(sp)
    80002628:	64e2                	ld	s1,24(sp)
    8000262a:	6942                	ld	s2,16(sp)
    8000262c:	69a2                	ld	s3,8(sp)
    8000262e:	6145                	addi	sp,sp,48
    80002630:	8082                	ret
        p->state = RUNNABLE;
    80002632:	4789                	li	a5,2
    80002634:	cc9c                	sw	a5,24(s1)
    80002636:	b7cd                	j	80002618 <kill+0x52>

0000000080002638 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002638:	7179                	addi	sp,sp,-48
    8000263a:	f406                	sd	ra,40(sp)
    8000263c:	f022                	sd	s0,32(sp)
    8000263e:	ec26                	sd	s1,24(sp)
    80002640:	e84a                	sd	s2,16(sp)
    80002642:	e44e                	sd	s3,8(sp)
    80002644:	e052                	sd	s4,0(sp)
    80002646:	1800                	addi	s0,sp,48
    80002648:	84aa                	mv	s1,a0
    8000264a:	892e                	mv	s2,a1
    8000264c:	89b2                	mv	s3,a2
    8000264e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	576080e7          	jalr	1398(ra) # 80001bc6 <myproc>
  if(user_dst){
    80002658:	c08d                	beqz	s1,8000267a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000265a:	86d2                	mv	a3,s4
    8000265c:	864e                	mv	a2,s3
    8000265e:	85ca                	mv	a1,s2
    80002660:	6928                	ld	a0,80(a0)
    80002662:	fffff097          	auipc	ra,0xfffff
    80002666:	2d8080e7          	jalr	728(ra) # 8000193a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000266a:	70a2                	ld	ra,40(sp)
    8000266c:	7402                	ld	s0,32(sp)
    8000266e:	64e2                	ld	s1,24(sp)
    80002670:	6942                	ld	s2,16(sp)
    80002672:	69a2                	ld	s3,8(sp)
    80002674:	6a02                	ld	s4,0(sp)
    80002676:	6145                	addi	sp,sp,48
    80002678:	8082                	ret
    memmove((char *)dst, src, len);
    8000267a:	000a061b          	sext.w	a2,s4
    8000267e:	85ce                	mv	a1,s3
    80002680:	854a                	mv	a0,s2
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	6f8080e7          	jalr	1784(ra) # 80000d7a <memmove>
    return 0;
    8000268a:	8526                	mv	a0,s1
    8000268c:	bff9                	j	8000266a <either_copyout+0x32>

000000008000268e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000268e:	7179                	addi	sp,sp,-48
    80002690:	f406                	sd	ra,40(sp)
    80002692:	f022                	sd	s0,32(sp)
    80002694:	ec26                	sd	s1,24(sp)
    80002696:	e84a                	sd	s2,16(sp)
    80002698:	e44e                	sd	s3,8(sp)
    8000269a:	e052                	sd	s4,0(sp)
    8000269c:	1800                	addi	s0,sp,48
    8000269e:	892a                	mv	s2,a0
    800026a0:	84ae                	mv	s1,a1
    800026a2:	89b2                	mv	s3,a2
    800026a4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	520080e7          	jalr	1312(ra) # 80001bc6 <myproc>
  if(user_src){
    800026ae:	c08d                	beqz	s1,800026d0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026b0:	86d2                	mv	a3,s4
    800026b2:	864e                	mv	a2,s3
    800026b4:	85ca                	mv	a1,s2
    800026b6:	6928                	ld	a0,80(a0)
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	328080e7          	jalr	808(ra) # 800019e0 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026c0:	70a2                	ld	ra,40(sp)
    800026c2:	7402                	ld	s0,32(sp)
    800026c4:	64e2                	ld	s1,24(sp)
    800026c6:	6942                	ld	s2,16(sp)
    800026c8:	69a2                	ld	s3,8(sp)
    800026ca:	6a02                	ld	s4,0(sp)
    800026cc:	6145                	addi	sp,sp,48
    800026ce:	8082                	ret
    memmove(dst, (char*)src, len);
    800026d0:	000a061b          	sext.w	a2,s4
    800026d4:	85ce                	mv	a1,s3
    800026d6:	854a                	mv	a0,s2
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	6a2080e7          	jalr	1698(ra) # 80000d7a <memmove>
    return 0;
    800026e0:	8526                	mv	a0,s1
    800026e2:	bff9                	j	800026c0 <either_copyin+0x32>

00000000800026e4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026e4:	715d                	addi	sp,sp,-80
    800026e6:	e486                	sd	ra,72(sp)
    800026e8:	e0a2                	sd	s0,64(sp)
    800026ea:	fc26                	sd	s1,56(sp)
    800026ec:	f84a                	sd	s2,48(sp)
    800026ee:	f44e                	sd	s3,40(sp)
    800026f0:	f052                	sd	s4,32(sp)
    800026f2:	ec56                	sd	s5,24(sp)
    800026f4:	e85a                	sd	s6,16(sp)
    800026f6:	e45e                	sd	s7,8(sp)
    800026f8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026fa:	00006517          	auipc	a0,0x6
    800026fe:	9ce50513          	addi	a0,a0,-1586 # 800080c8 <digits+0x88>
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	e9e080e7          	jalr	-354(ra) # 800005a0 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000270a:	0000f497          	auipc	s1,0xf
    8000270e:	7b648493          	addi	s1,s1,1974 # 80011ec0 <proc+0x158>
    80002712:	00015917          	auipc	s2,0x15
    80002716:	1ae90913          	addi	s2,s2,430 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000271a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000271c:	00006997          	auipc	s3,0x6
    80002720:	b5c98993          	addi	s3,s3,-1188 # 80008278 <digits+0x238>
    printf("%d %s %s", p->pid, state, p->name);
    80002724:	00006a97          	auipc	s5,0x6
    80002728:	b5ca8a93          	addi	s5,s5,-1188 # 80008280 <digits+0x240>
    printf("\n");
    8000272c:	00006a17          	auipc	s4,0x6
    80002730:	99ca0a13          	addi	s4,s4,-1636 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002734:	00006b97          	auipc	s7,0x6
    80002738:	b84b8b93          	addi	s7,s7,-1148 # 800082b8 <states.1714>
    8000273c:	a00d                	j	8000275e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000273e:	ee06a583          	lw	a1,-288(a3)
    80002742:	8556                	mv	a0,s5
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	e5c080e7          	jalr	-420(ra) # 800005a0 <printf>
    printf("\n");
    8000274c:	8552                	mv	a0,s4
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	e52080e7          	jalr	-430(ra) # 800005a0 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002756:	16848493          	addi	s1,s1,360
    8000275a:	03248163          	beq	s1,s2,8000277c <procdump+0x98>
    if(p->state == UNUSED)
    8000275e:	86a6                	mv	a3,s1
    80002760:	ec04a783          	lw	a5,-320(s1)
    80002764:	dbed                	beqz	a5,80002756 <procdump+0x72>
      state = "???";
    80002766:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002768:	fcfb6be3          	bltu	s6,a5,8000273e <procdump+0x5a>
    8000276c:	1782                	slli	a5,a5,0x20
    8000276e:	9381                	srli	a5,a5,0x20
    80002770:	078e                	slli	a5,a5,0x3
    80002772:	97de                	add	a5,a5,s7
    80002774:	6390                	ld	a2,0(a5)
    80002776:	f661                	bnez	a2,8000273e <procdump+0x5a>
      state = "???";
    80002778:	864e                	mv	a2,s3
    8000277a:	b7d1                	j	8000273e <procdump+0x5a>
  }
}
    8000277c:	60a6                	ld	ra,72(sp)
    8000277e:	6406                	ld	s0,64(sp)
    80002780:	74e2                	ld	s1,56(sp)
    80002782:	7942                	ld	s2,48(sp)
    80002784:	79a2                	ld	s3,40(sp)
    80002786:	7a02                	ld	s4,32(sp)
    80002788:	6ae2                	ld	s5,24(sp)
    8000278a:	6b42                	ld	s6,16(sp)
    8000278c:	6ba2                	ld	s7,8(sp)
    8000278e:	6161                	addi	sp,sp,80
    80002790:	8082                	ret

0000000080002792 <swtch>:
    80002792:	00153023          	sd	ra,0(a0)
    80002796:	00253423          	sd	sp,8(a0)
    8000279a:	e900                	sd	s0,16(a0)
    8000279c:	ed04                	sd	s1,24(a0)
    8000279e:	03253023          	sd	s2,32(a0)
    800027a2:	03353423          	sd	s3,40(a0)
    800027a6:	03453823          	sd	s4,48(a0)
    800027aa:	03553c23          	sd	s5,56(a0)
    800027ae:	05653023          	sd	s6,64(a0)
    800027b2:	05753423          	sd	s7,72(a0)
    800027b6:	05853823          	sd	s8,80(a0)
    800027ba:	05953c23          	sd	s9,88(a0)
    800027be:	07a53023          	sd	s10,96(a0)
    800027c2:	07b53423          	sd	s11,104(a0)
    800027c6:	0005b083          	ld	ra,0(a1)
    800027ca:	0085b103          	ld	sp,8(a1)
    800027ce:	6980                	ld	s0,16(a1)
    800027d0:	6d84                	ld	s1,24(a1)
    800027d2:	0205b903          	ld	s2,32(a1)
    800027d6:	0285b983          	ld	s3,40(a1)
    800027da:	0305ba03          	ld	s4,48(a1)
    800027de:	0385ba83          	ld	s5,56(a1)
    800027e2:	0405bb03          	ld	s6,64(a1)
    800027e6:	0485bb83          	ld	s7,72(a1)
    800027ea:	0505bc03          	ld	s8,80(a1)
    800027ee:	0585bc83          	ld	s9,88(a1)
    800027f2:	0605bd03          	ld	s10,96(a1)
    800027f6:	0685bd83          	ld	s11,104(a1)
    800027fa:	8082                	ret

00000000800027fc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027fc:	1141                	addi	sp,sp,-16
    800027fe:	e406                	sd	ra,8(sp)
    80002800:	e022                	sd	s0,0(sp)
    80002802:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002804:	00006597          	auipc	a1,0x6
    80002808:	adc58593          	addi	a1,a1,-1316 # 800082e0 <states.1714+0x28>
    8000280c:	00015517          	auipc	a0,0x15
    80002810:	f5c50513          	addi	a0,a0,-164 # 80017768 <tickslock>
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	37a080e7          	jalr	890(ra) # 80000b8e <initlock>
}
    8000281c:	60a2                	ld	ra,8(sp)
    8000281e:	6402                	ld	s0,0(sp)
    80002820:	0141                	addi	sp,sp,16
    80002822:	8082                	ret

0000000080002824 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002824:	1141                	addi	sp,sp,-16
    80002826:	e422                	sd	s0,8(sp)
    80002828:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000282a:	00003797          	auipc	a5,0x3
    8000282e:	51678793          	addi	a5,a5,1302 # 80005d40 <kernelvec>
    80002832:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002836:	6422                	ld	s0,8(sp)
    80002838:	0141                	addi	sp,sp,16
    8000283a:	8082                	ret

000000008000283c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000283c:	1141                	addi	sp,sp,-16
    8000283e:	e406                	sd	ra,8(sp)
    80002840:	e022                	sd	s0,0(sp)
    80002842:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	382080e7          	jalr	898(ra) # 80001bc6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000284c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002850:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002852:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002856:	00004617          	auipc	a2,0x4
    8000285a:	7aa60613          	addi	a2,a2,1962 # 80007000 <_trampoline>
    8000285e:	00004697          	auipc	a3,0x4
    80002862:	7a268693          	addi	a3,a3,1954 # 80007000 <_trampoline>
    80002866:	8e91                	sub	a3,a3,a2
    80002868:	040007b7          	lui	a5,0x4000
    8000286c:	17fd                	addi	a5,a5,-1
    8000286e:	07b2                	slli	a5,a5,0xc
    80002870:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002872:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002876:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002878:	180026f3          	csrr	a3,satp
    8000287c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000287e:	6d38                	ld	a4,88(a0)
    80002880:	6134                	ld	a3,64(a0)
    80002882:	6585                	lui	a1,0x1
    80002884:	96ae                	add	a3,a3,a1
    80002886:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002888:	6d38                	ld	a4,88(a0)
    8000288a:	00000697          	auipc	a3,0x0
    8000288e:	13868693          	addi	a3,a3,312 # 800029c2 <usertrap>
    80002892:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002894:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002896:	8692                	mv	a3,tp
    80002898:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000289e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028a2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028aa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ac:	6f18                	ld	a4,24(a4)
    800028ae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028b2:	692c                	ld	a1,80(a0)
    800028b4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800028b6:	00004717          	auipc	a4,0x4
    800028ba:	7da70713          	addi	a4,a4,2010 # 80007090 <userret>
    800028be:	8f11                	sub	a4,a4,a2
    800028c0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800028c2:	577d                	li	a4,-1
    800028c4:	177e                	slli	a4,a4,0x3f
    800028c6:	8dd9                	or	a1,a1,a4
    800028c8:	02000537          	lui	a0,0x2000
    800028cc:	157d                	addi	a0,a0,-1
    800028ce:	0536                	slli	a0,a0,0xd
    800028d0:	9782                	jalr	a5
}
    800028d2:	60a2                	ld	ra,8(sp)
    800028d4:	6402                	ld	s0,0(sp)
    800028d6:	0141                	addi	sp,sp,16
    800028d8:	8082                	ret

00000000800028da <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028da:	1101                	addi	sp,sp,-32
    800028dc:	ec06                	sd	ra,24(sp)
    800028de:	e822                	sd	s0,16(sp)
    800028e0:	e426                	sd	s1,8(sp)
    800028e2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028e4:	00015497          	auipc	s1,0x15
    800028e8:	e8448493          	addi	s1,s1,-380 # 80017768 <tickslock>
    800028ec:	8526                	mv	a0,s1
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	330080e7          	jalr	816(ra) # 80000c1e <acquire>
  ticks++;
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	72a50513          	addi	a0,a0,1834 # 80009020 <ticks>
    800028fe:	411c                	lw	a5,0(a0)
    80002900:	2785                	addiw	a5,a5,1
    80002902:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002904:	00000097          	auipc	ra,0x0
    80002908:	c58080e7          	jalr	-936(ra) # 8000255c <wakeup>
  release(&tickslock);
    8000290c:	8526                	mv	a0,s1
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	3c4080e7          	jalr	964(ra) # 80000cd2 <release>
}
    80002916:	60e2                	ld	ra,24(sp)
    80002918:	6442                	ld	s0,16(sp)
    8000291a:	64a2                	ld	s1,8(sp)
    8000291c:	6105                	addi	sp,sp,32
    8000291e:	8082                	ret

0000000080002920 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002920:	1101                	addi	sp,sp,-32
    80002922:	ec06                	sd	ra,24(sp)
    80002924:	e822                	sd	s0,16(sp)
    80002926:	e426                	sd	s1,8(sp)
    80002928:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000292a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000292e:	00074d63          	bltz	a4,80002948 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002932:	57fd                	li	a5,-1
    80002934:	17fe                	slli	a5,a5,0x3f
    80002936:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002938:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000293a:	06f70363          	beq	a4,a5,800029a0 <devintr+0x80>
  }
}
    8000293e:	60e2                	ld	ra,24(sp)
    80002940:	6442                	ld	s0,16(sp)
    80002942:	64a2                	ld	s1,8(sp)
    80002944:	6105                	addi	sp,sp,32
    80002946:	8082                	ret
     (scause & 0xff) == 9){
    80002948:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000294c:	46a5                	li	a3,9
    8000294e:	fed792e3          	bne	a5,a3,80002932 <devintr+0x12>
    int irq = plic_claim();
    80002952:	00003097          	auipc	ra,0x3
    80002956:	512080e7          	jalr	1298(ra) # 80005e64 <plic_claim>
    8000295a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000295c:	47a9                	li	a5,10
    8000295e:	02f50763          	beq	a0,a5,8000298c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002962:	4785                	li	a5,1
    80002964:	02f50963          	beq	a0,a5,80002996 <devintr+0x76>
    return 1;
    80002968:	4505                	li	a0,1
    } else if(irq){
    8000296a:	d8f1                	beqz	s1,8000293e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000296c:	85a6                	mv	a1,s1
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	97a50513          	addi	a0,a0,-1670 # 800082e8 <states.1714+0x30>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	c2a080e7          	jalr	-982(ra) # 800005a0 <printf>
      plic_complete(irq);
    8000297e:	8526                	mv	a0,s1
    80002980:	00003097          	auipc	ra,0x3
    80002984:	508080e7          	jalr	1288(ra) # 80005e88 <plic_complete>
    return 1;
    80002988:	4505                	li	a0,1
    8000298a:	bf55                	j	8000293e <devintr+0x1e>
      uartintr();
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	056080e7          	jalr	86(ra) # 800009e2 <uartintr>
    80002994:	b7ed                	j	8000297e <devintr+0x5e>
      virtio_disk_intr();
    80002996:	00004097          	auipc	ra,0x4
    8000299a:	98c080e7          	jalr	-1652(ra) # 80006322 <virtio_disk_intr>
    8000299e:	b7c5                	j	8000297e <devintr+0x5e>
    if(cpuid() == 0){
    800029a0:	fffff097          	auipc	ra,0xfffff
    800029a4:	1fa080e7          	jalr	506(ra) # 80001b9a <cpuid>
    800029a8:	c901                	beqz	a0,800029b8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029aa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029b0:	14479073          	csrw	sip,a5
    return 2;
    800029b4:	4509                	li	a0,2
    800029b6:	b761                	j	8000293e <devintr+0x1e>
      clockintr();
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	f22080e7          	jalr	-222(ra) # 800028da <clockintr>
    800029c0:	b7ed                	j	800029aa <devintr+0x8a>

00000000800029c2 <usertrap>:
{
    800029c2:	7179                	addi	sp,sp,-48
    800029c4:	f406                	sd	ra,40(sp)
    800029c6:	f022                	sd	s0,32(sp)
    800029c8:	ec26                	sd	s1,24(sp)
    800029ca:	e84a                	sd	s2,16(sp)
    800029cc:	e44e                	sd	s3,8(sp)
    800029ce:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029d4:	1007f793          	andi	a5,a5,256
    800029d8:	e3b5                	bnez	a5,80002a3c <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029da:	00003797          	auipc	a5,0x3
    800029de:	36678793          	addi	a5,a5,870 # 80005d40 <kernelvec>
    800029e2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	1e0080e7          	jalr	480(ra) # 80001bc6 <myproc>
    800029ee:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029f0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f2:	14102773          	csrr	a4,sepc
    800029f6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029fc:	47a1                	li	a5,8
    800029fe:	04f71d63          	bne	a4,a5,80002a58 <usertrap+0x96>
    if(p->killed)
    80002a02:	591c                	lw	a5,48(a0)
    80002a04:	e7a1                	bnez	a5,80002a4c <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002a06:	6cb8                	ld	a4,88(s1)
    80002a08:	6f1c                	ld	a5,24(a4)
    80002a0a:	0791                	addi	a5,a5,4
    80002a0c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a12:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a16:	10079073          	csrw	sstatus,a5
    syscall();
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	312080e7          	jalr	786(ra) # 80002d2c <syscall>
  if(p->killed)
    80002a22:	589c                	lw	a5,48(s1)
    80002a24:	e3e9                	bnez	a5,80002ae6 <usertrap+0x124>
  usertrapret();
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	e16080e7          	jalr	-490(ra) # 8000283c <usertrapret>
}
    80002a2e:	70a2                	ld	ra,40(sp)
    80002a30:	7402                	ld	s0,32(sp)
    80002a32:	64e2                	ld	s1,24(sp)
    80002a34:	6942                	ld	s2,16(sp)
    80002a36:	69a2                	ld	s3,8(sp)
    80002a38:	6145                	addi	sp,sp,48
    80002a3a:	8082                	ret
    panic("usertrap: not from user mode");
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	8cc50513          	addi	a0,a0,-1844 # 80008308 <states.1714+0x50>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	b12080e7          	jalr	-1262(ra) # 80000556 <panic>
      exit(-1);
    80002a4c:	557d                	li	a0,-1
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	842080e7          	jalr	-1982(ra) # 80002290 <exit>
    80002a56:	bf45                	j	80002a06 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002a58:	00000097          	auipc	ra,0x0
    80002a5c:	ec8080e7          	jalr	-312(ra) # 80002920 <devintr>
    80002a60:	892a                	mv	s2,a0
    80002a62:	ed3d                	bnez	a0,80002ae0 <usertrap+0x11e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a64:	143029f3          	csrr	s3,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a68:	14202773          	csrr	a4,scause
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){
    80002a6c:	47b5                	li	a5,13
    80002a6e:	04f70d63          	beq	a4,a5,80002ac8 <usertrap+0x106>
    80002a72:	14202773          	csrr	a4,scause
    80002a76:	47bd                	li	a5,15
    80002a78:	04f70863          	beq	a4,a5,80002ac8 <usertrap+0x106>
    80002a7c:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a80:	5c90                	lw	a2,56(s1)
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	8a650513          	addi	a0,a0,-1882 # 80008328 <states.1714+0x70>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b16080e7          	jalr	-1258(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a92:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a96:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8be50513          	addi	a0,a0,-1858 # 80008358 <states.1714+0xa0>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	afe080e7          	jalr	-1282(ra) # 800005a0 <printf>
      p->killed = 1;
    80002aaa:	4785                	li	a5,1
    80002aac:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002aae:	557d                	li	a0,-1
    80002ab0:	fffff097          	auipc	ra,0xfffff
    80002ab4:	7e0080e7          	jalr	2016(ra) # 80002290 <exit>
  if(which_dev == 2)
    80002ab8:	4789                	li	a5,2
    80002aba:	f6f916e3          	bne	s2,a5,80002a26 <usertrap+0x64>
    yield();
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	8dc080e7          	jalr	-1828(ra) # 8000239a <yield>
    80002ac6:	b785                	j	80002a26 <usertrap+0x64>
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){
    80002ac8:	854e                	mv	a0,s3
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	e1e080e7          	jalr	-482(ra) # 800018e8 <uvmshouldtouch>
    80002ad2:	d54d                	beqz	a0,80002a7c <usertrap+0xba>
      uvmlazytouch(va); // lazy page allocation
    80002ad4:	854e                	mv	a0,s3
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	d7e080e7          	jalr	-642(ra) # 80001854 <uvmlazytouch>
    80002ade:	b791                	j	80002a22 <usertrap+0x60>
  if(p->killed)
    80002ae0:	589c                	lw	a5,48(s1)
    80002ae2:	dbf9                	beqz	a5,80002ab8 <usertrap+0xf6>
    80002ae4:	b7e9                	j	80002aae <usertrap+0xec>
    80002ae6:	4901                	li	s2,0
    80002ae8:	b7d9                	j	80002aae <usertrap+0xec>

0000000080002aea <kerneltrap>:
{
    80002aea:	7179                	addi	sp,sp,-48
    80002aec:	f406                	sd	ra,40(sp)
    80002aee:	f022                	sd	s0,32(sp)
    80002af0:	ec26                	sd	s1,24(sp)
    80002af2:	e84a                	sd	s2,16(sp)
    80002af4:	e44e                	sd	s3,8(sp)
    80002af6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002afc:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b00:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b04:	1004f793          	andi	a5,s1,256
    80002b08:	cb85                	beqz	a5,80002b38 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b0e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b10:	ef85                	bnez	a5,80002b48 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b12:	00000097          	auipc	ra,0x0
    80002b16:	e0e080e7          	jalr	-498(ra) # 80002920 <devintr>
    80002b1a:	cd1d                	beqz	a0,80002b58 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1c:	4789                	li	a5,2
    80002b1e:	06f50a63          	beq	a0,a5,80002b92 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b22:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b26:	10049073          	csrw	sstatus,s1
}
    80002b2a:	70a2                	ld	ra,40(sp)
    80002b2c:	7402                	ld	s0,32(sp)
    80002b2e:	64e2                	ld	s1,24(sp)
    80002b30:	6942                	ld	s2,16(sp)
    80002b32:	69a2                	ld	s3,8(sp)
    80002b34:	6145                	addi	sp,sp,48
    80002b36:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	84050513          	addi	a0,a0,-1984 # 80008378 <states.1714+0xc0>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	a16080e7          	jalr	-1514(ra) # 80000556 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	85850513          	addi	a0,a0,-1960 # 800083a0 <states.1714+0xe8>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	a06080e7          	jalr	-1530(ra) # 80000556 <panic>
    printf("scause %p\n", scause);
    80002b58:	85ce                	mv	a1,s3
    80002b5a:	00006517          	auipc	a0,0x6
    80002b5e:	86650513          	addi	a0,a0,-1946 # 800083c0 <states.1714+0x108>
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	a3e080e7          	jalr	-1474(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b6e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b72:	00006517          	auipc	a0,0x6
    80002b76:	85e50513          	addi	a0,a0,-1954 # 800083d0 <states.1714+0x118>
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	a26080e7          	jalr	-1498(ra) # 800005a0 <printf>
    panic("kerneltrap");
    80002b82:	00006517          	auipc	a0,0x6
    80002b86:	86650513          	addi	a0,a0,-1946 # 800083e8 <states.1714+0x130>
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	9cc080e7          	jalr	-1588(ra) # 80000556 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b92:	fffff097          	auipc	ra,0xfffff
    80002b96:	034080e7          	jalr	52(ra) # 80001bc6 <myproc>
    80002b9a:	d541                	beqz	a0,80002b22 <kerneltrap+0x38>
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	02a080e7          	jalr	42(ra) # 80001bc6 <myproc>
    80002ba4:	4d18                	lw	a4,24(a0)
    80002ba6:	478d                	li	a5,3
    80002ba8:	f6f71de3          	bne	a4,a5,80002b22 <kerneltrap+0x38>
    yield();
    80002bac:	fffff097          	auipc	ra,0xfffff
    80002bb0:	7ee080e7          	jalr	2030(ra) # 8000239a <yield>
    80002bb4:	b7bd                	j	80002b22 <kerneltrap+0x38>

0000000080002bb6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	1000                	addi	s0,sp,32
    80002bc0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	004080e7          	jalr	4(ra) # 80001bc6 <myproc>
  switch (n) {
    80002bca:	4795                	li	a5,5
    80002bcc:	0497e163          	bltu	a5,s1,80002c0e <argraw+0x58>
    80002bd0:	048a                	slli	s1,s1,0x2
    80002bd2:	00006717          	auipc	a4,0x6
    80002bd6:	84e70713          	addi	a4,a4,-1970 # 80008420 <states.1714+0x168>
    80002bda:	94ba                	add	s1,s1,a4
    80002bdc:	409c                	lw	a5,0(s1)
    80002bde:	97ba                	add	a5,a5,a4
    80002be0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002be2:	6d3c                	ld	a5,88(a0)
    80002be4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002be6:	60e2                	ld	ra,24(sp)
    80002be8:	6442                	ld	s0,16(sp)
    80002bea:	64a2                	ld	s1,8(sp)
    80002bec:	6105                	addi	sp,sp,32
    80002bee:	8082                	ret
    return p->trapframe->a1;
    80002bf0:	6d3c                	ld	a5,88(a0)
    80002bf2:	7fa8                	ld	a0,120(a5)
    80002bf4:	bfcd                	j	80002be6 <argraw+0x30>
    return p->trapframe->a2;
    80002bf6:	6d3c                	ld	a5,88(a0)
    80002bf8:	63c8                	ld	a0,128(a5)
    80002bfa:	b7f5                	j	80002be6 <argraw+0x30>
    return p->trapframe->a3;
    80002bfc:	6d3c                	ld	a5,88(a0)
    80002bfe:	67c8                	ld	a0,136(a5)
    80002c00:	b7dd                	j	80002be6 <argraw+0x30>
    return p->trapframe->a4;
    80002c02:	6d3c                	ld	a5,88(a0)
    80002c04:	6bc8                	ld	a0,144(a5)
    80002c06:	b7c5                	j	80002be6 <argraw+0x30>
    return p->trapframe->a5;
    80002c08:	6d3c                	ld	a5,88(a0)
    80002c0a:	6fc8                	ld	a0,152(a5)
    80002c0c:	bfe9                	j	80002be6 <argraw+0x30>
  panic("argraw");
    80002c0e:	00005517          	auipc	a0,0x5
    80002c12:	7ea50513          	addi	a0,a0,2026 # 800083f8 <states.1714+0x140>
    80002c16:	ffffe097          	auipc	ra,0xffffe
    80002c1a:	940080e7          	jalr	-1728(ra) # 80000556 <panic>

0000000080002c1e <fetchaddr>:
{
    80002c1e:	1101                	addi	sp,sp,-32
    80002c20:	ec06                	sd	ra,24(sp)
    80002c22:	e822                	sd	s0,16(sp)
    80002c24:	e426                	sd	s1,8(sp)
    80002c26:	e04a                	sd	s2,0(sp)
    80002c28:	1000                	addi	s0,sp,32
    80002c2a:	84aa                	mv	s1,a0
    80002c2c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	f98080e7          	jalr	-104(ra) # 80001bc6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c36:	653c                	ld	a5,72(a0)
    80002c38:	02f4f863          	bgeu	s1,a5,80002c68 <fetchaddr+0x4a>
    80002c3c:	00848713          	addi	a4,s1,8
    80002c40:	02e7e663          	bltu	a5,a4,80002c6c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c44:	46a1                	li	a3,8
    80002c46:	8626                	mv	a2,s1
    80002c48:	85ca                	mv	a1,s2
    80002c4a:	6928                	ld	a0,80(a0)
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d94080e7          	jalr	-620(ra) # 800019e0 <copyin>
    80002c54:	00a03533          	snez	a0,a0
    80002c58:	40a00533          	neg	a0,a0
}
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6902                	ld	s2,0(sp)
    80002c64:	6105                	addi	sp,sp,32
    80002c66:	8082                	ret
    return -1;
    80002c68:	557d                	li	a0,-1
    80002c6a:	bfcd                	j	80002c5c <fetchaddr+0x3e>
    80002c6c:	557d                	li	a0,-1
    80002c6e:	b7fd                	j	80002c5c <fetchaddr+0x3e>

0000000080002c70 <fetchstr>:
{
    80002c70:	7179                	addi	sp,sp,-48
    80002c72:	f406                	sd	ra,40(sp)
    80002c74:	f022                	sd	s0,32(sp)
    80002c76:	ec26                	sd	s1,24(sp)
    80002c78:	e84a                	sd	s2,16(sp)
    80002c7a:	e44e                	sd	s3,8(sp)
    80002c7c:	1800                	addi	s0,sp,48
    80002c7e:	892a                	mv	s2,a0
    80002c80:	84ae                	mv	s1,a1
    80002c82:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	f42080e7          	jalr	-190(ra) # 80001bc6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c8c:	86ce                	mv	a3,s3
    80002c8e:	864a                	mv	a2,s2
    80002c90:	85a6                	mv	a1,s1
    80002c92:	6928                	ld	a0,80(a0)
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	a12080e7          	jalr	-1518(ra) # 800016a6 <copyinstr>
  if(err < 0)
    80002c9c:	00054763          	bltz	a0,80002caa <fetchstr+0x3a>
  return strlen(buf);
    80002ca0:	8526                	mv	a0,s1
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	200080e7          	jalr	512(ra) # 80000ea2 <strlen>
}
    80002caa:	70a2                	ld	ra,40(sp)
    80002cac:	7402                	ld	s0,32(sp)
    80002cae:	64e2                	ld	s1,24(sp)
    80002cb0:	6942                	ld	s2,16(sp)
    80002cb2:	69a2                	ld	s3,8(sp)
    80002cb4:	6145                	addi	sp,sp,48
    80002cb6:	8082                	ret

0000000080002cb8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	1000                	addi	s0,sp,32
    80002cc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	ef2080e7          	jalr	-270(ra) # 80002bb6 <argraw>
    80002ccc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cce:	4501                	li	a0,0
    80002cd0:	60e2                	ld	ra,24(sp)
    80002cd2:	6442                	ld	s0,16(sp)
    80002cd4:	64a2                	ld	s1,8(sp)
    80002cd6:	6105                	addi	sp,sp,32
    80002cd8:	8082                	ret

0000000080002cda <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	e426                	sd	s1,8(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce6:	00000097          	auipc	ra,0x0
    80002cea:	ed0080e7          	jalr	-304(ra) # 80002bb6 <argraw>
    80002cee:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cf0:	4501                	li	a0,0
    80002cf2:	60e2                	ld	ra,24(sp)
    80002cf4:	6442                	ld	s0,16(sp)
    80002cf6:	64a2                	ld	s1,8(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cfc:	1101                	addi	sp,sp,-32
    80002cfe:	ec06                	sd	ra,24(sp)
    80002d00:	e822                	sd	s0,16(sp)
    80002d02:	e426                	sd	s1,8(sp)
    80002d04:	e04a                	sd	s2,0(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84ae                	mv	s1,a1
    80002d0a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	eaa080e7          	jalr	-342(ra) # 80002bb6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d14:	864a                	mv	a2,s2
    80002d16:	85a6                	mv	a1,s1
    80002d18:	00000097          	auipc	ra,0x0
    80002d1c:	f58080e7          	jalr	-168(ra) # 80002c70 <fetchstr>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	64a2                	ld	s1,8(sp)
    80002d26:	6902                	ld	s2,0(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	e04a                	sd	s2,0(sp)
    80002d36:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	e8e080e7          	jalr	-370(ra) # 80001bc6 <myproc>
    80002d40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d42:	05853903          	ld	s2,88(a0)
    80002d46:	0a893783          	ld	a5,168(s2)
    80002d4a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d4e:	37fd                	addiw	a5,a5,-1
    80002d50:	4751                	li	a4,20
    80002d52:	00f76f63          	bltu	a4,a5,80002d70 <syscall+0x44>
    80002d56:	00369713          	slli	a4,a3,0x3
    80002d5a:	00005797          	auipc	a5,0x5
    80002d5e:	6de78793          	addi	a5,a5,1758 # 80008438 <syscalls>
    80002d62:	97ba                	add	a5,a5,a4
    80002d64:	639c                	ld	a5,0(a5)
    80002d66:	c789                	beqz	a5,80002d70 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d68:	9782                	jalr	a5
    80002d6a:	06a93823          	sd	a0,112(s2)
    80002d6e:	a839                	j	80002d8c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d70:	15848613          	addi	a2,s1,344
    80002d74:	5c8c                	lw	a1,56(s1)
    80002d76:	00005517          	auipc	a0,0x5
    80002d7a:	68a50513          	addi	a0,a0,1674 # 80008400 <states.1714+0x148>
    80002d7e:	ffffe097          	auipc	ra,0xffffe
    80002d82:	822080e7          	jalr	-2014(ra) # 800005a0 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d86:	6cbc                	ld	a5,88(s1)
    80002d88:	577d                	li	a4,-1
    80002d8a:	fbb8                	sd	a4,112(a5)
  }
}
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6902                	ld	s2,0(sp)
    80002d94:	6105                	addi	sp,sp,32
    80002d96:	8082                	ret

0000000080002d98 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d98:	1101                	addi	sp,sp,-32
    80002d9a:	ec06                	sd	ra,24(sp)
    80002d9c:	e822                	sd	s0,16(sp)
    80002d9e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002da0:	fec40593          	addi	a1,s0,-20
    80002da4:	4501                	li	a0,0
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	f12080e7          	jalr	-238(ra) # 80002cb8 <argint>
    return -1;
    80002dae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002db0:	00054963          	bltz	a0,80002dc2 <sys_exit+0x2a>
  exit(n);
    80002db4:	fec42503          	lw	a0,-20(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	4d8080e7          	jalr	1240(ra) # 80002290 <exit>
  return 0;  // not reached
    80002dc0:	4781                	li	a5,0
}
    80002dc2:	853e                	mv	a0,a5
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dcc:	1141                	addi	sp,sp,-16
    80002dce:	e406                	sd	ra,8(sp)
    80002dd0:	e022                	sd	s0,0(sp)
    80002dd2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	df2080e7          	jalr	-526(ra) # 80001bc6 <myproc>
}
    80002ddc:	5d08                	lw	a0,56(a0)
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <sys_fork>:

uint64
sys_fork(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e406                	sd	ra,8(sp)
    80002dea:	e022                	sd	s0,0(sp)
    80002dec:	0800                	addi	s0,sp,16
  return fork();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	198080e7          	jalr	408(ra) # 80001f86 <fork>
}
    80002df6:	60a2                	ld	ra,8(sp)
    80002df8:	6402                	ld	s0,0(sp)
    80002dfa:	0141                	addi	sp,sp,16
    80002dfc:	8082                	ret

0000000080002dfe <sys_wait>:

uint64
sys_wait(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e06:	fe840593          	addi	a1,s0,-24
    80002e0a:	4501                	li	a0,0
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	ece080e7          	jalr	-306(ra) # 80002cda <argaddr>
    80002e14:	87aa                	mv	a5,a0
    return -1;
    80002e16:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e18:	0007c863          	bltz	a5,80002e28 <sys_wait+0x2a>
  return wait(p);
    80002e1c:	fe843503          	ld	a0,-24(s0)
    80002e20:	fffff097          	auipc	ra,0xfffff
    80002e24:	634080e7          	jalr	1588(ra) # 80002454 <wait>
}
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	6105                	addi	sp,sp,32
    80002e2e:	8082                	ret

0000000080002e30 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e30:	7179                	addi	sp,sp,-48
    80002e32:	f406                	sd	ra,40(sp)
    80002e34:	f022                	sd	s0,32(sp)
    80002e36:	ec26                	sd	s1,24(sp)
    80002e38:	e84a                	sd	s2,16(sp)
    80002e3a:	1800                	addi	s0,sp,48
  int addr;
  int n;
  struct proc *p = myproc();
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	d8a080e7          	jalr	-630(ra) # 80001bc6 <myproc>
    80002e44:	84aa                	mv	s1,a0
  if(argint(0, &n) < 0)
    80002e46:	fdc40593          	addi	a1,s0,-36
    80002e4a:	4501                	li	a0,0
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	e6c080e7          	jalr	-404(ra) # 80002cb8 <argint>
    80002e54:	02054c63          	bltz	a0,80002e8c <sys_sbrk+0x5c>
    return -1;
  // printf("sbrk: %d\n",n);
  addr = p->sz;
    80002e58:	64ac                	ld	a1,72(s1)
    80002e5a:	0005891b          	sext.w	s2,a1
  // lazy allocation
  if(n < 0) {
    80002e5e:	fdc42603          	lw	a2,-36(s0)
    80002e62:	00064e63          	bltz	a2,80002e7e <sys_sbrk+0x4e>
    uvmdealloc(p->pagetable, p->sz, p->sz+n); // dealloc immediately
  }
  p->sz += n;
    80002e66:	fdc42703          	lw	a4,-36(s0)
    80002e6a:	64bc                	ld	a5,72(s1)
    80002e6c:	97ba                	add	a5,a5,a4
    80002e6e:	e4bc                	sd	a5,72(s1)
  return addr;
    80002e70:	854a                	mv	a0,s2
}
    80002e72:	70a2                	ld	ra,40(sp)
    80002e74:	7402                	ld	s0,32(sp)
    80002e76:	64e2                	ld	s1,24(sp)
    80002e78:	6942                	ld	s2,16(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret
    uvmdealloc(p->pagetable, p->sz, p->sz+n); // dealloc immediately
    80002e7e:	962e                	add	a2,a2,a1
    80002e80:	68a8                	ld	a0,80(s1)
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	5a8080e7          	jalr	1448(ra) # 8000142a <uvmdealloc>
    80002e8a:	bff1                	j	80002e66 <sys_sbrk+0x36>
    return -1;
    80002e8c:	557d                	li	a0,-1
    80002e8e:	b7d5                	j	80002e72 <sys_sbrk+0x42>

0000000080002e90 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e90:	7139                	addi	sp,sp,-64
    80002e92:	fc06                	sd	ra,56(sp)
    80002e94:	f822                	sd	s0,48(sp)
    80002e96:	f426                	sd	s1,40(sp)
    80002e98:	f04a                	sd	s2,32(sp)
    80002e9a:	ec4e                	sd	s3,24(sp)
    80002e9c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e9e:	fcc40593          	addi	a1,s0,-52
    80002ea2:	4501                	li	a0,0
    80002ea4:	00000097          	auipc	ra,0x0
    80002ea8:	e14080e7          	jalr	-492(ra) # 80002cb8 <argint>
    return -1;
    80002eac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eae:	06054563          	bltz	a0,80002f18 <sys_sleep+0x88>
  acquire(&tickslock);
    80002eb2:	00015517          	auipc	a0,0x15
    80002eb6:	8b650513          	addi	a0,a0,-1866 # 80017768 <tickslock>
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	d64080e7          	jalr	-668(ra) # 80000c1e <acquire>
  ticks0 = ticks;
    80002ec2:	00006917          	auipc	s2,0x6
    80002ec6:	15e92903          	lw	s2,350(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002eca:	fcc42783          	lw	a5,-52(s0)
    80002ece:	cf85                	beqz	a5,80002f06 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ed0:	00015997          	auipc	s3,0x15
    80002ed4:	89898993          	addi	s3,s3,-1896 # 80017768 <tickslock>
    80002ed8:	00006497          	auipc	s1,0x6
    80002edc:	14848493          	addi	s1,s1,328 # 80009020 <ticks>
    if(myproc()->killed){
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	ce6080e7          	jalr	-794(ra) # 80001bc6 <myproc>
    80002ee8:	591c                	lw	a5,48(a0)
    80002eea:	ef9d                	bnez	a5,80002f28 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002eec:	85ce                	mv	a1,s3
    80002eee:	8526                	mv	a0,s1
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	4e6080e7          	jalr	1254(ra) # 800023d6 <sleep>
  while(ticks - ticks0 < n){
    80002ef8:	409c                	lw	a5,0(s1)
    80002efa:	412787bb          	subw	a5,a5,s2
    80002efe:	fcc42703          	lw	a4,-52(s0)
    80002f02:	fce7efe3          	bltu	a5,a4,80002ee0 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f06:	00015517          	auipc	a0,0x15
    80002f0a:	86250513          	addi	a0,a0,-1950 # 80017768 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	dc4080e7          	jalr	-572(ra) # 80000cd2 <release>
  return 0;
    80002f16:	4781                	li	a5,0
}
    80002f18:	853e                	mv	a0,a5
    80002f1a:	70e2                	ld	ra,56(sp)
    80002f1c:	7442                	ld	s0,48(sp)
    80002f1e:	74a2                	ld	s1,40(sp)
    80002f20:	7902                	ld	s2,32(sp)
    80002f22:	69e2                	ld	s3,24(sp)
    80002f24:	6121                	addi	sp,sp,64
    80002f26:	8082                	ret
      release(&tickslock);
    80002f28:	00015517          	auipc	a0,0x15
    80002f2c:	84050513          	addi	a0,a0,-1984 # 80017768 <tickslock>
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	da2080e7          	jalr	-606(ra) # 80000cd2 <release>
      return -1;
    80002f38:	57fd                	li	a5,-1
    80002f3a:	bff9                	j	80002f18 <sys_sleep+0x88>

0000000080002f3c <sys_kill>:

uint64
sys_kill(void)
{
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f44:	fec40593          	addi	a1,s0,-20
    80002f48:	4501                	li	a0,0
    80002f4a:	00000097          	auipc	ra,0x0
    80002f4e:	d6e080e7          	jalr	-658(ra) # 80002cb8 <argint>
    80002f52:	87aa                	mv	a5,a0
    return -1;
    80002f54:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f56:	0007c863          	bltz	a5,80002f66 <sys_kill+0x2a>
  return kill(pid);
    80002f5a:	fec42503          	lw	a0,-20(s0)
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	668080e7          	jalr	1640(ra) # 800025c6 <kill>
}
    80002f66:	60e2                	ld	ra,24(sp)
    80002f68:	6442                	ld	s0,16(sp)
    80002f6a:	6105                	addi	sp,sp,32
    80002f6c:	8082                	ret

0000000080002f6e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	e426                	sd	s1,8(sp)
    80002f76:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f78:	00014517          	auipc	a0,0x14
    80002f7c:	7f050513          	addi	a0,a0,2032 # 80017768 <tickslock>
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	c9e080e7          	jalr	-866(ra) # 80000c1e <acquire>
  xticks = ticks;
    80002f88:	00006497          	auipc	s1,0x6
    80002f8c:	0984a483          	lw	s1,152(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	7d850513          	addi	a0,a0,2008 # 80017768 <tickslock>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	d3a080e7          	jalr	-710(ra) # 80000cd2 <release>
  return xticks;
}
    80002fa0:	02049513          	slli	a0,s1,0x20
    80002fa4:	9101                	srli	a0,a0,0x20
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	64a2                	ld	s1,8(sp)
    80002fac:	6105                	addi	sp,sp,32
    80002fae:	8082                	ret

0000000080002fb0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fb0:	7179                	addi	sp,sp,-48
    80002fb2:	f406                	sd	ra,40(sp)
    80002fb4:	f022                	sd	s0,32(sp)
    80002fb6:	ec26                	sd	s1,24(sp)
    80002fb8:	e84a                	sd	s2,16(sp)
    80002fba:	e44e                	sd	s3,8(sp)
    80002fbc:	e052                	sd	s4,0(sp)
    80002fbe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fc0:	00005597          	auipc	a1,0x5
    80002fc4:	52858593          	addi	a1,a1,1320 # 800084e8 <syscalls+0xb0>
    80002fc8:	00014517          	auipc	a0,0x14
    80002fcc:	7b850513          	addi	a0,a0,1976 # 80017780 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	bbe080e7          	jalr	-1090(ra) # 80000b8e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fd8:	0001c797          	auipc	a5,0x1c
    80002fdc:	7a878793          	addi	a5,a5,1960 # 8001f780 <bcache+0x8000>
    80002fe0:	0001d717          	auipc	a4,0x1d
    80002fe4:	a0870713          	addi	a4,a4,-1528 # 8001f9e8 <bcache+0x8268>
    80002fe8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ff0:	00014497          	auipc	s1,0x14
    80002ff4:	7a848493          	addi	s1,s1,1960 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ff8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ffa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ffc:	00005a17          	auipc	s4,0x5
    80003000:	4f4a0a13          	addi	s4,s4,1268 # 800084f0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003004:	2b893783          	ld	a5,696(s2)
    80003008:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000300a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000300e:	85d2                	mv	a1,s4
    80003010:	01048513          	addi	a0,s1,16
    80003014:	00001097          	auipc	ra,0x1
    80003018:	4b0080e7          	jalr	1200(ra) # 800044c4 <initsleeplock>
    bcache.head.next->prev = b;
    8000301c:	2b893783          	ld	a5,696(s2)
    80003020:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003022:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003026:	45848493          	addi	s1,s1,1112
    8000302a:	fd349de3          	bne	s1,s3,80003004 <binit+0x54>
  }
}
    8000302e:	70a2                	ld	ra,40(sp)
    80003030:	7402                	ld	s0,32(sp)
    80003032:	64e2                	ld	s1,24(sp)
    80003034:	6942                	ld	s2,16(sp)
    80003036:	69a2                	ld	s3,8(sp)
    80003038:	6a02                	ld	s4,0(sp)
    8000303a:	6145                	addi	sp,sp,48
    8000303c:	8082                	ret

000000008000303e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	e84a                	sd	s2,16(sp)
    80003048:	e44e                	sd	s3,8(sp)
    8000304a:	1800                	addi	s0,sp,48
    8000304c:	89aa                	mv	s3,a0
    8000304e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003050:	00014517          	auipc	a0,0x14
    80003054:	73050513          	addi	a0,a0,1840 # 80017780 <bcache>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	bc6080e7          	jalr	-1082(ra) # 80000c1e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003060:	0001d497          	auipc	s1,0x1d
    80003064:	9d84b483          	ld	s1,-1576(s1) # 8001fa38 <bcache+0x82b8>
    80003068:	0001d797          	auipc	a5,0x1d
    8000306c:	98078793          	addi	a5,a5,-1664 # 8001f9e8 <bcache+0x8268>
    80003070:	02f48f63          	beq	s1,a5,800030ae <bread+0x70>
    80003074:	873e                	mv	a4,a5
    80003076:	a021                	j	8000307e <bread+0x40>
    80003078:	68a4                	ld	s1,80(s1)
    8000307a:	02e48a63          	beq	s1,a4,800030ae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000307e:	449c                	lw	a5,8(s1)
    80003080:	ff379ce3          	bne	a5,s3,80003078 <bread+0x3a>
    80003084:	44dc                	lw	a5,12(s1)
    80003086:	ff2799e3          	bne	a5,s2,80003078 <bread+0x3a>
      b->refcnt++;
    8000308a:	40bc                	lw	a5,64(s1)
    8000308c:	2785                	addiw	a5,a5,1
    8000308e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003090:	00014517          	auipc	a0,0x14
    80003094:	6f050513          	addi	a0,a0,1776 # 80017780 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	c3a080e7          	jalr	-966(ra) # 80000cd2 <release>
      acquiresleep(&b->lock);
    800030a0:	01048513          	addi	a0,s1,16
    800030a4:	00001097          	auipc	ra,0x1
    800030a8:	45a080e7          	jalr	1114(ra) # 800044fe <acquiresleep>
      return b;
    800030ac:	a8b9                	j	8000310a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ae:	0001d497          	auipc	s1,0x1d
    800030b2:	9824b483          	ld	s1,-1662(s1) # 8001fa30 <bcache+0x82b0>
    800030b6:	0001d797          	auipc	a5,0x1d
    800030ba:	93278793          	addi	a5,a5,-1742 # 8001f9e8 <bcache+0x8268>
    800030be:	00f48863          	beq	s1,a5,800030ce <bread+0x90>
    800030c2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030c4:	40bc                	lw	a5,64(s1)
    800030c6:	cf81                	beqz	a5,800030de <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030c8:	64a4                	ld	s1,72(s1)
    800030ca:	fee49de3          	bne	s1,a4,800030c4 <bread+0x86>
  panic("bget: no buffers");
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	42a50513          	addi	a0,a0,1066 # 800084f8 <syscalls+0xc0>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	480080e7          	jalr	1152(ra) # 80000556 <panic>
      b->dev = dev;
    800030de:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030e2:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030e6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030ea:	4785                	li	a5,1
    800030ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ee:	00014517          	auipc	a0,0x14
    800030f2:	69250513          	addi	a0,a0,1682 # 80017780 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	bdc080e7          	jalr	-1060(ra) # 80000cd2 <release>
      acquiresleep(&b->lock);
    800030fe:	01048513          	addi	a0,s1,16
    80003102:	00001097          	auipc	ra,0x1
    80003106:	3fc080e7          	jalr	1020(ra) # 800044fe <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000310a:	409c                	lw	a5,0(s1)
    8000310c:	cb89                	beqz	a5,8000311e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000310e:	8526                	mv	a0,s1
    80003110:	70a2                	ld	ra,40(sp)
    80003112:	7402                	ld	s0,32(sp)
    80003114:	64e2                	ld	s1,24(sp)
    80003116:	6942                	ld	s2,16(sp)
    80003118:	69a2                	ld	s3,8(sp)
    8000311a:	6145                	addi	sp,sp,48
    8000311c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000311e:	4581                	li	a1,0
    80003120:	8526                	mv	a0,s1
    80003122:	00003097          	auipc	ra,0x3
    80003126:	f56080e7          	jalr	-170(ra) # 80006078 <virtio_disk_rw>
    b->valid = 1;
    8000312a:	4785                	li	a5,1
    8000312c:	c09c                	sw	a5,0(s1)
  return b;
    8000312e:	b7c5                	j	8000310e <bread+0xd0>

0000000080003130 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003130:	1101                	addi	sp,sp,-32
    80003132:	ec06                	sd	ra,24(sp)
    80003134:	e822                	sd	s0,16(sp)
    80003136:	e426                	sd	s1,8(sp)
    80003138:	1000                	addi	s0,sp,32
    8000313a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000313c:	0541                	addi	a0,a0,16
    8000313e:	00001097          	auipc	ra,0x1
    80003142:	45a080e7          	jalr	1114(ra) # 80004598 <holdingsleep>
    80003146:	cd01                	beqz	a0,8000315e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003148:	4585                	li	a1,1
    8000314a:	8526                	mv	a0,s1
    8000314c:	00003097          	auipc	ra,0x3
    80003150:	f2c080e7          	jalr	-212(ra) # 80006078 <virtio_disk_rw>
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6105                	addi	sp,sp,32
    8000315c:	8082                	ret
    panic("bwrite");
    8000315e:	00005517          	auipc	a0,0x5
    80003162:	3b250513          	addi	a0,a0,946 # 80008510 <syscalls+0xd8>
    80003166:	ffffd097          	auipc	ra,0xffffd
    8000316a:	3f0080e7          	jalr	1008(ra) # 80000556 <panic>

000000008000316e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000316e:	1101                	addi	sp,sp,-32
    80003170:	ec06                	sd	ra,24(sp)
    80003172:	e822                	sd	s0,16(sp)
    80003174:	e426                	sd	s1,8(sp)
    80003176:	e04a                	sd	s2,0(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000317c:	01050913          	addi	s2,a0,16
    80003180:	854a                	mv	a0,s2
    80003182:	00001097          	auipc	ra,0x1
    80003186:	416080e7          	jalr	1046(ra) # 80004598 <holdingsleep>
    8000318a:	c92d                	beqz	a0,800031fc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000318c:	854a                	mv	a0,s2
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	3c6080e7          	jalr	966(ra) # 80004554 <releasesleep>

  acquire(&bcache.lock);
    80003196:	00014517          	auipc	a0,0x14
    8000319a:	5ea50513          	addi	a0,a0,1514 # 80017780 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a80080e7          	jalr	-1408(ra) # 80000c1e <acquire>
  b->refcnt--;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	37fd                	addiw	a5,a5,-1
    800031aa:	0007871b          	sext.w	a4,a5
    800031ae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031b0:	eb05                	bnez	a4,800031e0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031b2:	68bc                	ld	a5,80(s1)
    800031b4:	64b8                	ld	a4,72(s1)
    800031b6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031b8:	64bc                	ld	a5,72(s1)
    800031ba:	68b8                	ld	a4,80(s1)
    800031bc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031be:	0001c797          	auipc	a5,0x1c
    800031c2:	5c278793          	addi	a5,a5,1474 # 8001f780 <bcache+0x8000>
    800031c6:	2b87b703          	ld	a4,696(a5)
    800031ca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031cc:	0001d717          	auipc	a4,0x1d
    800031d0:	81c70713          	addi	a4,a4,-2020 # 8001f9e8 <bcache+0x8268>
    800031d4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031d6:	2b87b703          	ld	a4,696(a5)
    800031da:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031dc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031e0:	00014517          	auipc	a0,0x14
    800031e4:	5a050513          	addi	a0,a0,1440 # 80017780 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	aea080e7          	jalr	-1302(ra) # 80000cd2 <release>
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6902                	ld	s2,0(sp)
    800031f8:	6105                	addi	sp,sp,32
    800031fa:	8082                	ret
    panic("brelse");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	31c50513          	addi	a0,a0,796 # 80008518 <syscalls+0xe0>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	352080e7          	jalr	850(ra) # 80000556 <panic>

000000008000320c <bpin>:

void
bpin(struct buf *b) {
    8000320c:	1101                	addi	sp,sp,-32
    8000320e:	ec06                	sd	ra,24(sp)
    80003210:	e822                	sd	s0,16(sp)
    80003212:	e426                	sd	s1,8(sp)
    80003214:	1000                	addi	s0,sp,32
    80003216:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003218:	00014517          	auipc	a0,0x14
    8000321c:	56850513          	addi	a0,a0,1384 # 80017780 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	9fe080e7          	jalr	-1538(ra) # 80000c1e <acquire>
  b->refcnt++;
    80003228:	40bc                	lw	a5,64(s1)
    8000322a:	2785                	addiw	a5,a5,1
    8000322c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000322e:	00014517          	auipc	a0,0x14
    80003232:	55250513          	addi	a0,a0,1362 # 80017780 <bcache>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	a9c080e7          	jalr	-1380(ra) # 80000cd2 <release>
}
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	64a2                	ld	s1,8(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret

0000000080003248 <bunpin>:

void
bunpin(struct buf *b) {
    80003248:	1101                	addi	sp,sp,-32
    8000324a:	ec06                	sd	ra,24(sp)
    8000324c:	e822                	sd	s0,16(sp)
    8000324e:	e426                	sd	s1,8(sp)
    80003250:	1000                	addi	s0,sp,32
    80003252:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003254:	00014517          	auipc	a0,0x14
    80003258:	52c50513          	addi	a0,a0,1324 # 80017780 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	9c2080e7          	jalr	-1598(ra) # 80000c1e <acquire>
  b->refcnt--;
    80003264:	40bc                	lw	a5,64(s1)
    80003266:	37fd                	addiw	a5,a5,-1
    80003268:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000326a:	00014517          	auipc	a0,0x14
    8000326e:	51650513          	addi	a0,a0,1302 # 80017780 <bcache>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	a60080e7          	jalr	-1440(ra) # 80000cd2 <release>
}
    8000327a:	60e2                	ld	ra,24(sp)
    8000327c:	6442                	ld	s0,16(sp)
    8000327e:	64a2                	ld	s1,8(sp)
    80003280:	6105                	addi	sp,sp,32
    80003282:	8082                	ret

0000000080003284 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003284:	1101                	addi	sp,sp,-32
    80003286:	ec06                	sd	ra,24(sp)
    80003288:	e822                	sd	s0,16(sp)
    8000328a:	e426                	sd	s1,8(sp)
    8000328c:	e04a                	sd	s2,0(sp)
    8000328e:	1000                	addi	s0,sp,32
    80003290:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003292:	00d5d59b          	srliw	a1,a1,0xd
    80003296:	0001d797          	auipc	a5,0x1d
    8000329a:	bc67a783          	lw	a5,-1082(a5) # 8001fe5c <sb+0x1c>
    8000329e:	9dbd                	addw	a1,a1,a5
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	d9e080e7          	jalr	-610(ra) # 8000303e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032a8:	0074f713          	andi	a4,s1,7
    800032ac:	4785                	li	a5,1
    800032ae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032b2:	14ce                	slli	s1,s1,0x33
    800032b4:	90d9                	srli	s1,s1,0x36
    800032b6:	00950733          	add	a4,a0,s1
    800032ba:	05874703          	lbu	a4,88(a4)
    800032be:	00e7f6b3          	and	a3,a5,a4
    800032c2:	c69d                	beqz	a3,800032f0 <bfree+0x6c>
    800032c4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032c6:	94aa                	add	s1,s1,a0
    800032c8:	fff7c793          	not	a5,a5
    800032cc:	8ff9                	and	a5,a5,a4
    800032ce:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	104080e7          	jalr	260(ra) # 800043d6 <log_write>
  brelse(bp);
    800032da:	854a                	mv	a0,s2
    800032dc:	00000097          	auipc	ra,0x0
    800032e0:	e92080e7          	jalr	-366(ra) # 8000316e <brelse>
}
    800032e4:	60e2                	ld	ra,24(sp)
    800032e6:	6442                	ld	s0,16(sp)
    800032e8:	64a2                	ld	s1,8(sp)
    800032ea:	6902                	ld	s2,0(sp)
    800032ec:	6105                	addi	sp,sp,32
    800032ee:	8082                	ret
    panic("freeing free block");
    800032f0:	00005517          	auipc	a0,0x5
    800032f4:	23050513          	addi	a0,a0,560 # 80008520 <syscalls+0xe8>
    800032f8:	ffffd097          	auipc	ra,0xffffd
    800032fc:	25e080e7          	jalr	606(ra) # 80000556 <panic>

0000000080003300 <balloc>:
{
    80003300:	711d                	addi	sp,sp,-96
    80003302:	ec86                	sd	ra,88(sp)
    80003304:	e8a2                	sd	s0,80(sp)
    80003306:	e4a6                	sd	s1,72(sp)
    80003308:	e0ca                	sd	s2,64(sp)
    8000330a:	fc4e                	sd	s3,56(sp)
    8000330c:	f852                	sd	s4,48(sp)
    8000330e:	f456                	sd	s5,40(sp)
    80003310:	f05a                	sd	s6,32(sp)
    80003312:	ec5e                	sd	s7,24(sp)
    80003314:	e862                	sd	s8,16(sp)
    80003316:	e466                	sd	s9,8(sp)
    80003318:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000331a:	0001d797          	auipc	a5,0x1d
    8000331e:	b2a7a783          	lw	a5,-1238(a5) # 8001fe44 <sb+0x4>
    80003322:	cbd1                	beqz	a5,800033b6 <balloc+0xb6>
    80003324:	8baa                	mv	s7,a0
    80003326:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003328:	0001db17          	auipc	s6,0x1d
    8000332c:	b18b0b13          	addi	s6,s6,-1256 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003330:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003332:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003334:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003336:	6c89                	lui	s9,0x2
    80003338:	a831                	j	80003354 <balloc+0x54>
    brelse(bp);
    8000333a:	854a                	mv	a0,s2
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	e32080e7          	jalr	-462(ra) # 8000316e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003344:	015c87bb          	addw	a5,s9,s5
    80003348:	00078a9b          	sext.w	s5,a5
    8000334c:	004b2703          	lw	a4,4(s6)
    80003350:	06eaf363          	bgeu	s5,a4,800033b6 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003354:	41fad79b          	sraiw	a5,s5,0x1f
    80003358:	0137d79b          	srliw	a5,a5,0x13
    8000335c:	015787bb          	addw	a5,a5,s5
    80003360:	40d7d79b          	sraiw	a5,a5,0xd
    80003364:	01cb2583          	lw	a1,28(s6)
    80003368:	9dbd                	addw	a1,a1,a5
    8000336a:	855e                	mv	a0,s7
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	cd2080e7          	jalr	-814(ra) # 8000303e <bread>
    80003374:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003376:	004b2503          	lw	a0,4(s6)
    8000337a:	000a849b          	sext.w	s1,s5
    8000337e:	8662                	mv	a2,s8
    80003380:	faa4fde3          	bgeu	s1,a0,8000333a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003384:	41f6579b          	sraiw	a5,a2,0x1f
    80003388:	01d7d69b          	srliw	a3,a5,0x1d
    8000338c:	00c6873b          	addw	a4,a3,a2
    80003390:	00777793          	andi	a5,a4,7
    80003394:	9f95                	subw	a5,a5,a3
    80003396:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000339a:	4037571b          	sraiw	a4,a4,0x3
    8000339e:	00e906b3          	add	a3,s2,a4
    800033a2:	0586c683          	lbu	a3,88(a3)
    800033a6:	00d7f5b3          	and	a1,a5,a3
    800033aa:	cd91                	beqz	a1,800033c6 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ac:	2605                	addiw	a2,a2,1
    800033ae:	2485                	addiw	s1,s1,1
    800033b0:	fd4618e3          	bne	a2,s4,80003380 <balloc+0x80>
    800033b4:	b759                	j	8000333a <balloc+0x3a>
  panic("balloc: out of blocks");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	18250513          	addi	a0,a0,386 # 80008538 <syscalls+0x100>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	198080e7          	jalr	408(ra) # 80000556 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033c6:	974a                	add	a4,a4,s2
    800033c8:	8fd5                	or	a5,a5,a3
    800033ca:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033ce:	854a                	mv	a0,s2
    800033d0:	00001097          	auipc	ra,0x1
    800033d4:	006080e7          	jalr	6(ra) # 800043d6 <log_write>
        brelse(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00000097          	auipc	ra,0x0
    800033de:	d94080e7          	jalr	-620(ra) # 8000316e <brelse>
  bp = bread(dev, bno);
    800033e2:	85a6                	mv	a1,s1
    800033e4:	855e                	mv	a0,s7
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	c58080e7          	jalr	-936(ra) # 8000303e <bread>
    800033ee:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033f0:	40000613          	li	a2,1024
    800033f4:	4581                	li	a1,0
    800033f6:	05850513          	addi	a0,a0,88
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	920080e7          	jalr	-1760(ra) # 80000d1a <memset>
  log_write(bp);
    80003402:	854a                	mv	a0,s2
    80003404:	00001097          	auipc	ra,0x1
    80003408:	fd2080e7          	jalr	-46(ra) # 800043d6 <log_write>
  brelse(bp);
    8000340c:	854a                	mv	a0,s2
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	d60080e7          	jalr	-672(ra) # 8000316e <brelse>
}
    80003416:	8526                	mv	a0,s1
    80003418:	60e6                	ld	ra,88(sp)
    8000341a:	6446                	ld	s0,80(sp)
    8000341c:	64a6                	ld	s1,72(sp)
    8000341e:	6906                	ld	s2,64(sp)
    80003420:	79e2                	ld	s3,56(sp)
    80003422:	7a42                	ld	s4,48(sp)
    80003424:	7aa2                	ld	s5,40(sp)
    80003426:	7b02                	ld	s6,32(sp)
    80003428:	6be2                	ld	s7,24(sp)
    8000342a:	6c42                	ld	s8,16(sp)
    8000342c:	6ca2                	ld	s9,8(sp)
    8000342e:	6125                	addi	sp,sp,96
    80003430:	8082                	ret

0000000080003432 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003432:	7179                	addi	sp,sp,-48
    80003434:	f406                	sd	ra,40(sp)
    80003436:	f022                	sd	s0,32(sp)
    80003438:	ec26                	sd	s1,24(sp)
    8000343a:	e84a                	sd	s2,16(sp)
    8000343c:	e44e                	sd	s3,8(sp)
    8000343e:	e052                	sd	s4,0(sp)
    80003440:	1800                	addi	s0,sp,48
    80003442:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003444:	47ad                	li	a5,11
    80003446:	04b7fe63          	bgeu	a5,a1,800034a2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000344a:	ff45849b          	addiw	s1,a1,-12
    8000344e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003452:	0ff00793          	li	a5,255
    80003456:	0ae7e363          	bltu	a5,a4,800034fc <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000345a:	08052583          	lw	a1,128(a0)
    8000345e:	c5ad                	beqz	a1,800034c8 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003460:	00092503          	lw	a0,0(s2)
    80003464:	00000097          	auipc	ra,0x0
    80003468:	bda080e7          	jalr	-1062(ra) # 8000303e <bread>
    8000346c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000346e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003472:	02049593          	slli	a1,s1,0x20
    80003476:	9181                	srli	a1,a1,0x20
    80003478:	058a                	slli	a1,a1,0x2
    8000347a:	00b784b3          	add	s1,a5,a1
    8000347e:	0004a983          	lw	s3,0(s1)
    80003482:	04098d63          	beqz	s3,800034dc <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003486:	8552                	mv	a0,s4
    80003488:	00000097          	auipc	ra,0x0
    8000348c:	ce6080e7          	jalr	-794(ra) # 8000316e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003490:	854e                	mv	a0,s3
    80003492:	70a2                	ld	ra,40(sp)
    80003494:	7402                	ld	s0,32(sp)
    80003496:	64e2                	ld	s1,24(sp)
    80003498:	6942                	ld	s2,16(sp)
    8000349a:	69a2                	ld	s3,8(sp)
    8000349c:	6a02                	ld	s4,0(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034a2:	02059493          	slli	s1,a1,0x20
    800034a6:	9081                	srli	s1,s1,0x20
    800034a8:	048a                	slli	s1,s1,0x2
    800034aa:	94aa                	add	s1,s1,a0
    800034ac:	0504a983          	lw	s3,80(s1)
    800034b0:	fe0990e3          	bnez	s3,80003490 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034b4:	4108                	lw	a0,0(a0)
    800034b6:	00000097          	auipc	ra,0x0
    800034ba:	e4a080e7          	jalr	-438(ra) # 80003300 <balloc>
    800034be:	0005099b          	sext.w	s3,a0
    800034c2:	0534a823          	sw	s3,80(s1)
    800034c6:	b7e9                	j	80003490 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034c8:	4108                	lw	a0,0(a0)
    800034ca:	00000097          	auipc	ra,0x0
    800034ce:	e36080e7          	jalr	-458(ra) # 80003300 <balloc>
    800034d2:	0005059b          	sext.w	a1,a0
    800034d6:	08b92023          	sw	a1,128(s2)
    800034da:	b759                	j	80003460 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034dc:	00092503          	lw	a0,0(s2)
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	e20080e7          	jalr	-480(ra) # 80003300 <balloc>
    800034e8:	0005099b          	sext.w	s3,a0
    800034ec:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034f0:	8552                	mv	a0,s4
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	ee4080e7          	jalr	-284(ra) # 800043d6 <log_write>
    800034fa:	b771                	j	80003486 <bmap+0x54>
  panic("bmap: out of range");
    800034fc:	00005517          	auipc	a0,0x5
    80003500:	05450513          	addi	a0,a0,84 # 80008550 <syscalls+0x118>
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	052080e7          	jalr	82(ra) # 80000556 <panic>

000000008000350c <iget>:
{
    8000350c:	7179                	addi	sp,sp,-48
    8000350e:	f406                	sd	ra,40(sp)
    80003510:	f022                	sd	s0,32(sp)
    80003512:	ec26                	sd	s1,24(sp)
    80003514:	e84a                	sd	s2,16(sp)
    80003516:	e44e                	sd	s3,8(sp)
    80003518:	e052                	sd	s4,0(sp)
    8000351a:	1800                	addi	s0,sp,48
    8000351c:	89aa                	mv	s3,a0
    8000351e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003520:	0001d517          	auipc	a0,0x1d
    80003524:	94050513          	addi	a0,a0,-1728 # 8001fe60 <icache>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	6f6080e7          	jalr	1782(ra) # 80000c1e <acquire>
  empty = 0;
    80003530:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003532:	0001d497          	auipc	s1,0x1d
    80003536:	94648493          	addi	s1,s1,-1722 # 8001fe78 <icache+0x18>
    8000353a:	0001e697          	auipc	a3,0x1e
    8000353e:	3ce68693          	addi	a3,a3,974 # 80021908 <log>
    80003542:	a039                	j	80003550 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003544:	02090b63          	beqz	s2,8000357a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003548:	08848493          	addi	s1,s1,136
    8000354c:	02d48a63          	beq	s1,a3,80003580 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003550:	449c                	lw	a5,8(s1)
    80003552:	fef059e3          	blez	a5,80003544 <iget+0x38>
    80003556:	4098                	lw	a4,0(s1)
    80003558:	ff3716e3          	bne	a4,s3,80003544 <iget+0x38>
    8000355c:	40d8                	lw	a4,4(s1)
    8000355e:	ff4713e3          	bne	a4,s4,80003544 <iget+0x38>
      ip->ref++;
    80003562:	2785                	addiw	a5,a5,1
    80003564:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003566:	0001d517          	auipc	a0,0x1d
    8000356a:	8fa50513          	addi	a0,a0,-1798 # 8001fe60 <icache>
    8000356e:	ffffd097          	auipc	ra,0xffffd
    80003572:	764080e7          	jalr	1892(ra) # 80000cd2 <release>
      return ip;
    80003576:	8926                	mv	s2,s1
    80003578:	a03d                	j	800035a6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357a:	f7f9                	bnez	a5,80003548 <iget+0x3c>
    8000357c:	8926                	mv	s2,s1
    8000357e:	b7e9                	j	80003548 <iget+0x3c>
  if(empty == 0)
    80003580:	02090c63          	beqz	s2,800035b8 <iget+0xac>
  ip->dev = dev;
    80003584:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003588:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000358c:	4785                	li	a5,1
    8000358e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003592:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003596:	0001d517          	auipc	a0,0x1d
    8000359a:	8ca50513          	addi	a0,a0,-1846 # 8001fe60 <icache>
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	734080e7          	jalr	1844(ra) # 80000cd2 <release>
}
    800035a6:	854a                	mv	a0,s2
    800035a8:	70a2                	ld	ra,40(sp)
    800035aa:	7402                	ld	s0,32(sp)
    800035ac:	64e2                	ld	s1,24(sp)
    800035ae:	6942                	ld	s2,16(sp)
    800035b0:	69a2                	ld	s3,8(sp)
    800035b2:	6a02                	ld	s4,0(sp)
    800035b4:	6145                	addi	sp,sp,48
    800035b6:	8082                	ret
    panic("iget: no inodes");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	fb050513          	addi	a0,a0,-80 # 80008568 <syscalls+0x130>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f96080e7          	jalr	-106(ra) # 80000556 <panic>

00000000800035c8 <fsinit>:
fsinit(int dev) {
    800035c8:	7179                	addi	sp,sp,-48
    800035ca:	f406                	sd	ra,40(sp)
    800035cc:	f022                	sd	s0,32(sp)
    800035ce:	ec26                	sd	s1,24(sp)
    800035d0:	e84a                	sd	s2,16(sp)
    800035d2:	e44e                	sd	s3,8(sp)
    800035d4:	1800                	addi	s0,sp,48
    800035d6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035d8:	4585                	li	a1,1
    800035da:	00000097          	auipc	ra,0x0
    800035de:	a64080e7          	jalr	-1436(ra) # 8000303e <bread>
    800035e2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035e4:	0001d997          	auipc	s3,0x1d
    800035e8:	85c98993          	addi	s3,s3,-1956 # 8001fe40 <sb>
    800035ec:	02000613          	li	a2,32
    800035f0:	05850593          	addi	a1,a0,88
    800035f4:	854e                	mv	a0,s3
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	784080e7          	jalr	1924(ra) # 80000d7a <memmove>
  brelse(bp);
    800035fe:	8526                	mv	a0,s1
    80003600:	00000097          	auipc	ra,0x0
    80003604:	b6e080e7          	jalr	-1170(ra) # 8000316e <brelse>
  if(sb.magic != FSMAGIC)
    80003608:	0009a703          	lw	a4,0(s3)
    8000360c:	102037b7          	lui	a5,0x10203
    80003610:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003614:	02f71263          	bne	a4,a5,80003638 <fsinit+0x70>
  initlog(dev, &sb);
    80003618:	0001d597          	auipc	a1,0x1d
    8000361c:	82858593          	addi	a1,a1,-2008 # 8001fe40 <sb>
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	b3c080e7          	jalr	-1220(ra) # 8000415e <initlog>
}
    8000362a:	70a2                	ld	ra,40(sp)
    8000362c:	7402                	ld	s0,32(sp)
    8000362e:	64e2                	ld	s1,24(sp)
    80003630:	6942                	ld	s2,16(sp)
    80003632:	69a2                	ld	s3,8(sp)
    80003634:	6145                	addi	sp,sp,48
    80003636:	8082                	ret
    panic("invalid file system");
    80003638:	00005517          	auipc	a0,0x5
    8000363c:	f4050513          	addi	a0,a0,-192 # 80008578 <syscalls+0x140>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	f16080e7          	jalr	-234(ra) # 80000556 <panic>

0000000080003648 <iinit>:
{
    80003648:	7179                	addi	sp,sp,-48
    8000364a:	f406                	sd	ra,40(sp)
    8000364c:	f022                	sd	s0,32(sp)
    8000364e:	ec26                	sd	s1,24(sp)
    80003650:	e84a                	sd	s2,16(sp)
    80003652:	e44e                	sd	s3,8(sp)
    80003654:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003656:	00005597          	auipc	a1,0x5
    8000365a:	f3a58593          	addi	a1,a1,-198 # 80008590 <syscalls+0x158>
    8000365e:	0001d517          	auipc	a0,0x1d
    80003662:	80250513          	addi	a0,a0,-2046 # 8001fe60 <icache>
    80003666:	ffffd097          	auipc	ra,0xffffd
    8000366a:	528080e7          	jalr	1320(ra) # 80000b8e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000366e:	0001d497          	auipc	s1,0x1d
    80003672:	81a48493          	addi	s1,s1,-2022 # 8001fe88 <icache+0x28>
    80003676:	0001e997          	auipc	s3,0x1e
    8000367a:	2a298993          	addi	s3,s3,674 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000367e:	00005917          	auipc	s2,0x5
    80003682:	f1a90913          	addi	s2,s2,-230 # 80008598 <syscalls+0x160>
    80003686:	85ca                	mv	a1,s2
    80003688:	8526                	mv	a0,s1
    8000368a:	00001097          	auipc	ra,0x1
    8000368e:	e3a080e7          	jalr	-454(ra) # 800044c4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003692:	08848493          	addi	s1,s1,136
    80003696:	ff3498e3          	bne	s1,s3,80003686 <iinit+0x3e>
}
    8000369a:	70a2                	ld	ra,40(sp)
    8000369c:	7402                	ld	s0,32(sp)
    8000369e:	64e2                	ld	s1,24(sp)
    800036a0:	6942                	ld	s2,16(sp)
    800036a2:	69a2                	ld	s3,8(sp)
    800036a4:	6145                	addi	sp,sp,48
    800036a6:	8082                	ret

00000000800036a8 <ialloc>:
{
    800036a8:	715d                	addi	sp,sp,-80
    800036aa:	e486                	sd	ra,72(sp)
    800036ac:	e0a2                	sd	s0,64(sp)
    800036ae:	fc26                	sd	s1,56(sp)
    800036b0:	f84a                	sd	s2,48(sp)
    800036b2:	f44e                	sd	s3,40(sp)
    800036b4:	f052                	sd	s4,32(sp)
    800036b6:	ec56                	sd	s5,24(sp)
    800036b8:	e85a                	sd	s6,16(sp)
    800036ba:	e45e                	sd	s7,8(sp)
    800036bc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036be:	0001c717          	auipc	a4,0x1c
    800036c2:	78e72703          	lw	a4,1934(a4) # 8001fe4c <sb+0xc>
    800036c6:	4785                	li	a5,1
    800036c8:	04e7fa63          	bgeu	a5,a4,8000371c <ialloc+0x74>
    800036cc:	8aaa                	mv	s5,a0
    800036ce:	8bae                	mv	s7,a1
    800036d0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036d2:	0001ca17          	auipc	s4,0x1c
    800036d6:	76ea0a13          	addi	s4,s4,1902 # 8001fe40 <sb>
    800036da:	00048b1b          	sext.w	s6,s1
    800036de:	0044d593          	srli	a1,s1,0x4
    800036e2:	018a2783          	lw	a5,24(s4)
    800036e6:	9dbd                	addw	a1,a1,a5
    800036e8:	8556                	mv	a0,s5
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	954080e7          	jalr	-1708(ra) # 8000303e <bread>
    800036f2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036f4:	05850993          	addi	s3,a0,88
    800036f8:	00f4f793          	andi	a5,s1,15
    800036fc:	079a                	slli	a5,a5,0x6
    800036fe:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003700:	00099783          	lh	a5,0(s3)
    80003704:	c785                	beqz	a5,8000372c <ialloc+0x84>
    brelse(bp);
    80003706:	00000097          	auipc	ra,0x0
    8000370a:	a68080e7          	jalr	-1432(ra) # 8000316e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000370e:	0485                	addi	s1,s1,1
    80003710:	00ca2703          	lw	a4,12(s4)
    80003714:	0004879b          	sext.w	a5,s1
    80003718:	fce7e1e3          	bltu	a5,a4,800036da <ialloc+0x32>
  panic("ialloc: no inodes");
    8000371c:	00005517          	auipc	a0,0x5
    80003720:	e8450513          	addi	a0,a0,-380 # 800085a0 <syscalls+0x168>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	e32080e7          	jalr	-462(ra) # 80000556 <panic>
      memset(dip, 0, sizeof(*dip));
    8000372c:	04000613          	li	a2,64
    80003730:	4581                	li	a1,0
    80003732:	854e                	mv	a0,s3
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	5e6080e7          	jalr	1510(ra) # 80000d1a <memset>
      dip->type = type;
    8000373c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003740:	854a                	mv	a0,s2
    80003742:	00001097          	auipc	ra,0x1
    80003746:	c94080e7          	jalr	-876(ra) # 800043d6 <log_write>
      brelse(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	a22080e7          	jalr	-1502(ra) # 8000316e <brelse>
      return iget(dev, inum);
    80003754:	85da                	mv	a1,s6
    80003756:	8556                	mv	a0,s5
    80003758:	00000097          	auipc	ra,0x0
    8000375c:	db4080e7          	jalr	-588(ra) # 8000350c <iget>
}
    80003760:	60a6                	ld	ra,72(sp)
    80003762:	6406                	ld	s0,64(sp)
    80003764:	74e2                	ld	s1,56(sp)
    80003766:	7942                	ld	s2,48(sp)
    80003768:	79a2                	ld	s3,40(sp)
    8000376a:	7a02                	ld	s4,32(sp)
    8000376c:	6ae2                	ld	s5,24(sp)
    8000376e:	6b42                	ld	s6,16(sp)
    80003770:	6ba2                	ld	s7,8(sp)
    80003772:	6161                	addi	sp,sp,80
    80003774:	8082                	ret

0000000080003776 <iupdate>:
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	e04a                	sd	s2,0(sp)
    80003780:	1000                	addi	s0,sp,32
    80003782:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003784:	415c                	lw	a5,4(a0)
    80003786:	0047d79b          	srliw	a5,a5,0x4
    8000378a:	0001c597          	auipc	a1,0x1c
    8000378e:	6ce5a583          	lw	a1,1742(a1) # 8001fe58 <sb+0x18>
    80003792:	9dbd                	addw	a1,a1,a5
    80003794:	4108                	lw	a0,0(a0)
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	8a8080e7          	jalr	-1880(ra) # 8000303e <bread>
    8000379e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037a0:	05850793          	addi	a5,a0,88
    800037a4:	40c8                	lw	a0,4(s1)
    800037a6:	893d                	andi	a0,a0,15
    800037a8:	051a                	slli	a0,a0,0x6
    800037aa:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037ac:	04449703          	lh	a4,68(s1)
    800037b0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037b4:	04649703          	lh	a4,70(s1)
    800037b8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037bc:	04849703          	lh	a4,72(s1)
    800037c0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037c4:	04a49703          	lh	a4,74(s1)
    800037c8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037cc:	44f8                	lw	a4,76(s1)
    800037ce:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037d0:	03400613          	li	a2,52
    800037d4:	05048593          	addi	a1,s1,80
    800037d8:	0531                	addi	a0,a0,12
    800037da:	ffffd097          	auipc	ra,0xffffd
    800037de:	5a0080e7          	jalr	1440(ra) # 80000d7a <memmove>
  log_write(bp);
    800037e2:	854a                	mv	a0,s2
    800037e4:	00001097          	auipc	ra,0x1
    800037e8:	bf2080e7          	jalr	-1038(ra) # 800043d6 <log_write>
  brelse(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	980080e7          	jalr	-1664(ra) # 8000316e <brelse>
}
    800037f6:	60e2                	ld	ra,24(sp)
    800037f8:	6442                	ld	s0,16(sp)
    800037fa:	64a2                	ld	s1,8(sp)
    800037fc:	6902                	ld	s2,0(sp)
    800037fe:	6105                	addi	sp,sp,32
    80003800:	8082                	ret

0000000080003802 <idup>:
{
    80003802:	1101                	addi	sp,sp,-32
    80003804:	ec06                	sd	ra,24(sp)
    80003806:	e822                	sd	s0,16(sp)
    80003808:	e426                	sd	s1,8(sp)
    8000380a:	1000                	addi	s0,sp,32
    8000380c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000380e:	0001c517          	auipc	a0,0x1c
    80003812:	65250513          	addi	a0,a0,1618 # 8001fe60 <icache>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	408080e7          	jalr	1032(ra) # 80000c1e <acquire>
  ip->ref++;
    8000381e:	449c                	lw	a5,8(s1)
    80003820:	2785                	addiw	a5,a5,1
    80003822:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003824:	0001c517          	auipc	a0,0x1c
    80003828:	63c50513          	addi	a0,a0,1596 # 8001fe60 <icache>
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	4a6080e7          	jalr	1190(ra) # 80000cd2 <release>
}
    80003834:	8526                	mv	a0,s1
    80003836:	60e2                	ld	ra,24(sp)
    80003838:	6442                	ld	s0,16(sp)
    8000383a:	64a2                	ld	s1,8(sp)
    8000383c:	6105                	addi	sp,sp,32
    8000383e:	8082                	ret

0000000080003840 <ilock>:
{
    80003840:	1101                	addi	sp,sp,-32
    80003842:	ec06                	sd	ra,24(sp)
    80003844:	e822                	sd	s0,16(sp)
    80003846:	e426                	sd	s1,8(sp)
    80003848:	e04a                	sd	s2,0(sp)
    8000384a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000384c:	c115                	beqz	a0,80003870 <ilock+0x30>
    8000384e:	84aa                	mv	s1,a0
    80003850:	451c                	lw	a5,8(a0)
    80003852:	00f05f63          	blez	a5,80003870 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003856:	0541                	addi	a0,a0,16
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	ca6080e7          	jalr	-858(ra) # 800044fe <acquiresleep>
  if(ip->valid == 0){
    80003860:	40bc                	lw	a5,64(s1)
    80003862:	cf99                	beqz	a5,80003880 <ilock+0x40>
}
    80003864:	60e2                	ld	ra,24(sp)
    80003866:	6442                	ld	s0,16(sp)
    80003868:	64a2                	ld	s1,8(sp)
    8000386a:	6902                	ld	s2,0(sp)
    8000386c:	6105                	addi	sp,sp,32
    8000386e:	8082                	ret
    panic("ilock");
    80003870:	00005517          	auipc	a0,0x5
    80003874:	d4850513          	addi	a0,a0,-696 # 800085b8 <syscalls+0x180>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	cde080e7          	jalr	-802(ra) # 80000556 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003880:	40dc                	lw	a5,4(s1)
    80003882:	0047d79b          	srliw	a5,a5,0x4
    80003886:	0001c597          	auipc	a1,0x1c
    8000388a:	5d25a583          	lw	a1,1490(a1) # 8001fe58 <sb+0x18>
    8000388e:	9dbd                	addw	a1,a1,a5
    80003890:	4088                	lw	a0,0(s1)
    80003892:	fffff097          	auipc	ra,0xfffff
    80003896:	7ac080e7          	jalr	1964(ra) # 8000303e <bread>
    8000389a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000389c:	05850593          	addi	a1,a0,88
    800038a0:	40dc                	lw	a5,4(s1)
    800038a2:	8bbd                	andi	a5,a5,15
    800038a4:	079a                	slli	a5,a5,0x6
    800038a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038a8:	00059783          	lh	a5,0(a1)
    800038ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038b0:	00259783          	lh	a5,2(a1)
    800038b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038b8:	00459783          	lh	a5,4(a1)
    800038bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038c0:	00659783          	lh	a5,6(a1)
    800038c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038c8:	459c                	lw	a5,8(a1)
    800038ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038cc:	03400613          	li	a2,52
    800038d0:	05b1                	addi	a1,a1,12
    800038d2:	05048513          	addi	a0,s1,80
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	4a4080e7          	jalr	1188(ra) # 80000d7a <memmove>
    brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	88e080e7          	jalr	-1906(ra) # 8000316e <brelse>
    ip->valid = 1;
    800038e8:	4785                	li	a5,1
    800038ea:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038ec:	04449783          	lh	a5,68(s1)
    800038f0:	fbb5                	bnez	a5,80003864 <ilock+0x24>
      panic("ilock: no type");
    800038f2:	00005517          	auipc	a0,0x5
    800038f6:	cce50513          	addi	a0,a0,-818 # 800085c0 <syscalls+0x188>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	c5c080e7          	jalr	-932(ra) # 80000556 <panic>

0000000080003902 <iunlock>:
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000390e:	c905                	beqz	a0,8000393e <iunlock+0x3c>
    80003910:	84aa                	mv	s1,a0
    80003912:	01050913          	addi	s2,a0,16
    80003916:	854a                	mv	a0,s2
    80003918:	00001097          	auipc	ra,0x1
    8000391c:	c80080e7          	jalr	-896(ra) # 80004598 <holdingsleep>
    80003920:	cd19                	beqz	a0,8000393e <iunlock+0x3c>
    80003922:	449c                	lw	a5,8(s1)
    80003924:	00f05d63          	blez	a5,8000393e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003928:	854a                	mv	a0,s2
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	c2a080e7          	jalr	-982(ra) # 80004554 <releasesleep>
}
    80003932:	60e2                	ld	ra,24(sp)
    80003934:	6442                	ld	s0,16(sp)
    80003936:	64a2                	ld	s1,8(sp)
    80003938:	6902                	ld	s2,0(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret
    panic("iunlock");
    8000393e:	00005517          	auipc	a0,0x5
    80003942:	c9250513          	addi	a0,a0,-878 # 800085d0 <syscalls+0x198>
    80003946:	ffffd097          	auipc	ra,0xffffd
    8000394a:	c10080e7          	jalr	-1008(ra) # 80000556 <panic>

000000008000394e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000394e:	7179                	addi	sp,sp,-48
    80003950:	f406                	sd	ra,40(sp)
    80003952:	f022                	sd	s0,32(sp)
    80003954:	ec26                	sd	s1,24(sp)
    80003956:	e84a                	sd	s2,16(sp)
    80003958:	e44e                	sd	s3,8(sp)
    8000395a:	e052                	sd	s4,0(sp)
    8000395c:	1800                	addi	s0,sp,48
    8000395e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003960:	05050493          	addi	s1,a0,80
    80003964:	08050913          	addi	s2,a0,128
    80003968:	a021                	j	80003970 <itrunc+0x22>
    8000396a:	0491                	addi	s1,s1,4
    8000396c:	01248d63          	beq	s1,s2,80003986 <itrunc+0x38>
    if(ip->addrs[i]){
    80003970:	408c                	lw	a1,0(s1)
    80003972:	dde5                	beqz	a1,8000396a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003974:	0009a503          	lw	a0,0(s3)
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	90c080e7          	jalr	-1780(ra) # 80003284 <bfree>
      ip->addrs[i] = 0;
    80003980:	0004a023          	sw	zero,0(s1)
    80003984:	b7dd                	j	8000396a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003986:	0809a583          	lw	a1,128(s3)
    8000398a:	e185                	bnez	a1,800039aa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000398c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003990:	854e                	mv	a0,s3
    80003992:	00000097          	auipc	ra,0x0
    80003996:	de4080e7          	jalr	-540(ra) # 80003776 <iupdate>
}
    8000399a:	70a2                	ld	ra,40(sp)
    8000399c:	7402                	ld	s0,32(sp)
    8000399e:	64e2                	ld	s1,24(sp)
    800039a0:	6942                	ld	s2,16(sp)
    800039a2:	69a2                	ld	s3,8(sp)
    800039a4:	6a02                	ld	s4,0(sp)
    800039a6:	6145                	addi	sp,sp,48
    800039a8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039aa:	0009a503          	lw	a0,0(s3)
    800039ae:	fffff097          	auipc	ra,0xfffff
    800039b2:	690080e7          	jalr	1680(ra) # 8000303e <bread>
    800039b6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039b8:	05850493          	addi	s1,a0,88
    800039bc:	45850913          	addi	s2,a0,1112
    800039c0:	a811                	j	800039d4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039c2:	0009a503          	lw	a0,0(s3)
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	8be080e7          	jalr	-1858(ra) # 80003284 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039ce:	0491                	addi	s1,s1,4
    800039d0:	01248563          	beq	s1,s2,800039da <itrunc+0x8c>
      if(a[j])
    800039d4:	408c                	lw	a1,0(s1)
    800039d6:	dde5                	beqz	a1,800039ce <itrunc+0x80>
    800039d8:	b7ed                	j	800039c2 <itrunc+0x74>
    brelse(bp);
    800039da:	8552                	mv	a0,s4
    800039dc:	fffff097          	auipc	ra,0xfffff
    800039e0:	792080e7          	jalr	1938(ra) # 8000316e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039e4:	0809a583          	lw	a1,128(s3)
    800039e8:	0009a503          	lw	a0,0(s3)
    800039ec:	00000097          	auipc	ra,0x0
    800039f0:	898080e7          	jalr	-1896(ra) # 80003284 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039f4:	0809a023          	sw	zero,128(s3)
    800039f8:	bf51                	j	8000398c <itrunc+0x3e>

00000000800039fa <iput>:
{
    800039fa:	1101                	addi	sp,sp,-32
    800039fc:	ec06                	sd	ra,24(sp)
    800039fe:	e822                	sd	s0,16(sp)
    80003a00:	e426                	sd	s1,8(sp)
    80003a02:	e04a                	sd	s2,0(sp)
    80003a04:	1000                	addi	s0,sp,32
    80003a06:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a08:	0001c517          	auipc	a0,0x1c
    80003a0c:	45850513          	addi	a0,a0,1112 # 8001fe60 <icache>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	20e080e7          	jalr	526(ra) # 80000c1e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a18:	4498                	lw	a4,8(s1)
    80003a1a:	4785                	li	a5,1
    80003a1c:	02f70363          	beq	a4,a5,80003a42 <iput+0x48>
  ip->ref--;
    80003a20:	449c                	lw	a5,8(s1)
    80003a22:	37fd                	addiw	a5,a5,-1
    80003a24:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a26:	0001c517          	auipc	a0,0x1c
    80003a2a:	43a50513          	addi	a0,a0,1082 # 8001fe60 <icache>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	2a4080e7          	jalr	676(ra) # 80000cd2 <release>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6902                	ld	s2,0(sp)
    80003a3e:	6105                	addi	sp,sp,32
    80003a40:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a42:	40bc                	lw	a5,64(s1)
    80003a44:	dff1                	beqz	a5,80003a20 <iput+0x26>
    80003a46:	04a49783          	lh	a5,74(s1)
    80003a4a:	fbf9                	bnez	a5,80003a20 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a4c:	01048913          	addi	s2,s1,16
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	aac080e7          	jalr	-1364(ra) # 800044fe <acquiresleep>
    release(&icache.lock);
    80003a5a:	0001c517          	auipc	a0,0x1c
    80003a5e:	40650513          	addi	a0,a0,1030 # 8001fe60 <icache>
    80003a62:	ffffd097          	auipc	ra,0xffffd
    80003a66:	270080e7          	jalr	624(ra) # 80000cd2 <release>
    itrunc(ip);
    80003a6a:	8526                	mv	a0,s1
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	ee2080e7          	jalr	-286(ra) # 8000394e <itrunc>
    ip->type = 0;
    80003a74:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a78:	8526                	mv	a0,s1
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	cfc080e7          	jalr	-772(ra) # 80003776 <iupdate>
    ip->valid = 0;
    80003a82:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a86:	854a                	mv	a0,s2
    80003a88:	00001097          	auipc	ra,0x1
    80003a8c:	acc080e7          	jalr	-1332(ra) # 80004554 <releasesleep>
    acquire(&icache.lock);
    80003a90:	0001c517          	auipc	a0,0x1c
    80003a94:	3d050513          	addi	a0,a0,976 # 8001fe60 <icache>
    80003a98:	ffffd097          	auipc	ra,0xffffd
    80003a9c:	186080e7          	jalr	390(ra) # 80000c1e <acquire>
    80003aa0:	b741                	j	80003a20 <iput+0x26>

0000000080003aa2 <iunlockput>:
{
    80003aa2:	1101                	addi	sp,sp,-32
    80003aa4:	ec06                	sd	ra,24(sp)
    80003aa6:	e822                	sd	s0,16(sp)
    80003aa8:	e426                	sd	s1,8(sp)
    80003aaa:	1000                	addi	s0,sp,32
    80003aac:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	e54080e7          	jalr	-428(ra) # 80003902 <iunlock>
  iput(ip);
    80003ab6:	8526                	mv	a0,s1
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	f42080e7          	jalr	-190(ra) # 800039fa <iput>
}
    80003ac0:	60e2                	ld	ra,24(sp)
    80003ac2:	6442                	ld	s0,16(sp)
    80003ac4:	64a2                	ld	s1,8(sp)
    80003ac6:	6105                	addi	sp,sp,32
    80003ac8:	8082                	ret

0000000080003aca <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aca:	1141                	addi	sp,sp,-16
    80003acc:	e422                	sd	s0,8(sp)
    80003ace:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ad0:	411c                	lw	a5,0(a0)
    80003ad2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ad4:	415c                	lw	a5,4(a0)
    80003ad6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ad8:	04451783          	lh	a5,68(a0)
    80003adc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ae0:	04a51783          	lh	a5,74(a0)
    80003ae4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ae8:	04c56783          	lwu	a5,76(a0)
    80003aec:	e99c                	sd	a5,16(a1)
}
    80003aee:	6422                	ld	s0,8(sp)
    80003af0:	0141                	addi	sp,sp,16
    80003af2:	8082                	ret

0000000080003af4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003af4:	457c                	lw	a5,76(a0)
    80003af6:	0ed7e963          	bltu	a5,a3,80003be8 <readi+0xf4>
{
    80003afa:	7159                	addi	sp,sp,-112
    80003afc:	f486                	sd	ra,104(sp)
    80003afe:	f0a2                	sd	s0,96(sp)
    80003b00:	eca6                	sd	s1,88(sp)
    80003b02:	e8ca                	sd	s2,80(sp)
    80003b04:	e4ce                	sd	s3,72(sp)
    80003b06:	e0d2                	sd	s4,64(sp)
    80003b08:	fc56                	sd	s5,56(sp)
    80003b0a:	f85a                	sd	s6,48(sp)
    80003b0c:	f45e                	sd	s7,40(sp)
    80003b0e:	f062                	sd	s8,32(sp)
    80003b10:	ec66                	sd	s9,24(sp)
    80003b12:	e86a                	sd	s10,16(sp)
    80003b14:	e46e                	sd	s11,8(sp)
    80003b16:	1880                	addi	s0,sp,112
    80003b18:	8baa                	mv	s7,a0
    80003b1a:	8c2e                	mv	s8,a1
    80003b1c:	8ab2                	mv	s5,a2
    80003b1e:	84b6                	mv	s1,a3
    80003b20:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b22:	9f35                	addw	a4,a4,a3
    return 0;
    80003b24:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b26:	0ad76063          	bltu	a4,a3,80003bc6 <readi+0xd2>
  if(off + n > ip->size)
    80003b2a:	00e7f463          	bgeu	a5,a4,80003b32 <readi+0x3e>
    n = ip->size - off;
    80003b2e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b32:	0a0b0963          	beqz	s6,80003be4 <readi+0xf0>
    80003b36:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b38:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b3c:	5cfd                	li	s9,-1
    80003b3e:	a82d                	j	80003b78 <readi+0x84>
    80003b40:	020a1d93          	slli	s11,s4,0x20
    80003b44:	020ddd93          	srli	s11,s11,0x20
    80003b48:	05890613          	addi	a2,s2,88
    80003b4c:	86ee                	mv	a3,s11
    80003b4e:	963a                	add	a2,a2,a4
    80003b50:	85d6                	mv	a1,s5
    80003b52:	8562                	mv	a0,s8
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	ae4080e7          	jalr	-1308(ra) # 80002638 <either_copyout>
    80003b5c:	05950d63          	beq	a0,s9,80003bb6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b60:	854a                	mv	a0,s2
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	60c080e7          	jalr	1548(ra) # 8000316e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6a:	013a09bb          	addw	s3,s4,s3
    80003b6e:	009a04bb          	addw	s1,s4,s1
    80003b72:	9aee                	add	s5,s5,s11
    80003b74:	0569f763          	bgeu	s3,s6,80003bc2 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b78:	000ba903          	lw	s2,0(s7)
    80003b7c:	00a4d59b          	srliw	a1,s1,0xa
    80003b80:	855e                	mv	a0,s7
    80003b82:	00000097          	auipc	ra,0x0
    80003b86:	8b0080e7          	jalr	-1872(ra) # 80003432 <bmap>
    80003b8a:	0005059b          	sext.w	a1,a0
    80003b8e:	854a                	mv	a0,s2
    80003b90:	fffff097          	auipc	ra,0xfffff
    80003b94:	4ae080e7          	jalr	1198(ra) # 8000303e <bread>
    80003b98:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9a:	3ff4f713          	andi	a4,s1,1023
    80003b9e:	40ed07bb          	subw	a5,s10,a4
    80003ba2:	413b06bb          	subw	a3,s6,s3
    80003ba6:	8a3e                	mv	s4,a5
    80003ba8:	2781                	sext.w	a5,a5
    80003baa:	0006861b          	sext.w	a2,a3
    80003bae:	f8f679e3          	bgeu	a2,a5,80003b40 <readi+0x4c>
    80003bb2:	8a36                	mv	s4,a3
    80003bb4:	b771                	j	80003b40 <readi+0x4c>
      brelse(bp);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	5b6080e7          	jalr	1462(ra) # 8000316e <brelse>
      tot = -1;
    80003bc0:	59fd                	li	s3,-1
  }
  return tot;
    80003bc2:	0009851b          	sext.w	a0,s3
}
    80003bc6:	70a6                	ld	ra,104(sp)
    80003bc8:	7406                	ld	s0,96(sp)
    80003bca:	64e6                	ld	s1,88(sp)
    80003bcc:	6946                	ld	s2,80(sp)
    80003bce:	69a6                	ld	s3,72(sp)
    80003bd0:	6a06                	ld	s4,64(sp)
    80003bd2:	7ae2                	ld	s5,56(sp)
    80003bd4:	7b42                	ld	s6,48(sp)
    80003bd6:	7ba2                	ld	s7,40(sp)
    80003bd8:	7c02                	ld	s8,32(sp)
    80003bda:	6ce2                	ld	s9,24(sp)
    80003bdc:	6d42                	ld	s10,16(sp)
    80003bde:	6da2                	ld	s11,8(sp)
    80003be0:	6165                	addi	sp,sp,112
    80003be2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003be4:	89da                	mv	s3,s6
    80003be6:	bff1                	j	80003bc2 <readi+0xce>
    return 0;
    80003be8:	4501                	li	a0,0
}
    80003bea:	8082                	ret

0000000080003bec <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bec:	457c                	lw	a5,76(a0)
    80003bee:	10d7e763          	bltu	a5,a3,80003cfc <writei+0x110>
{
    80003bf2:	7159                	addi	sp,sp,-112
    80003bf4:	f486                	sd	ra,104(sp)
    80003bf6:	f0a2                	sd	s0,96(sp)
    80003bf8:	eca6                	sd	s1,88(sp)
    80003bfa:	e8ca                	sd	s2,80(sp)
    80003bfc:	e4ce                	sd	s3,72(sp)
    80003bfe:	e0d2                	sd	s4,64(sp)
    80003c00:	fc56                	sd	s5,56(sp)
    80003c02:	f85a                	sd	s6,48(sp)
    80003c04:	f45e                	sd	s7,40(sp)
    80003c06:	f062                	sd	s8,32(sp)
    80003c08:	ec66                	sd	s9,24(sp)
    80003c0a:	e86a                	sd	s10,16(sp)
    80003c0c:	e46e                	sd	s11,8(sp)
    80003c0e:	1880                	addi	s0,sp,112
    80003c10:	8baa                	mv	s7,a0
    80003c12:	8c2e                	mv	s8,a1
    80003c14:	8ab2                	mv	s5,a2
    80003c16:	8936                	mv	s2,a3
    80003c18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c1a:	00e687bb          	addw	a5,a3,a4
    80003c1e:	0ed7e163          	bltu	a5,a3,80003d00 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c22:	00043737          	lui	a4,0x43
    80003c26:	0cf76f63          	bltu	a4,a5,80003d04 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c2a:	0a0b0863          	beqz	s6,80003cda <writei+0xee>
    80003c2e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c30:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c34:	5cfd                	li	s9,-1
    80003c36:	a091                	j	80003c7a <writei+0x8e>
    80003c38:	02099d93          	slli	s11,s3,0x20
    80003c3c:	020ddd93          	srli	s11,s11,0x20
    80003c40:	05848513          	addi	a0,s1,88
    80003c44:	86ee                	mv	a3,s11
    80003c46:	8656                	mv	a2,s5
    80003c48:	85e2                	mv	a1,s8
    80003c4a:	953a                	add	a0,a0,a4
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	a42080e7          	jalr	-1470(ra) # 8000268e <either_copyin>
    80003c54:	07950263          	beq	a0,s9,80003cb8 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003c58:	8526                	mv	a0,s1
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	77c080e7          	jalr	1916(ra) # 800043d6 <log_write>
    brelse(bp);
    80003c62:	8526                	mv	a0,s1
    80003c64:	fffff097          	auipc	ra,0xfffff
    80003c68:	50a080e7          	jalr	1290(ra) # 8000316e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6c:	01498a3b          	addw	s4,s3,s4
    80003c70:	0129893b          	addw	s2,s3,s2
    80003c74:	9aee                	add	s5,s5,s11
    80003c76:	056a7763          	bgeu	s4,s6,80003cc4 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c7a:	000ba483          	lw	s1,0(s7)
    80003c7e:	00a9559b          	srliw	a1,s2,0xa
    80003c82:	855e                	mv	a0,s7
    80003c84:	fffff097          	auipc	ra,0xfffff
    80003c88:	7ae080e7          	jalr	1966(ra) # 80003432 <bmap>
    80003c8c:	0005059b          	sext.w	a1,a0
    80003c90:	8526                	mv	a0,s1
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	3ac080e7          	jalr	940(ra) # 8000303e <bread>
    80003c9a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9c:	3ff97713          	andi	a4,s2,1023
    80003ca0:	40ed07bb          	subw	a5,s10,a4
    80003ca4:	414b06bb          	subw	a3,s6,s4
    80003ca8:	89be                	mv	s3,a5
    80003caa:	2781                	sext.w	a5,a5
    80003cac:	0006861b          	sext.w	a2,a3
    80003cb0:	f8f674e3          	bgeu	a2,a5,80003c38 <writei+0x4c>
    80003cb4:	89b6                	mv	s3,a3
    80003cb6:	b749                	j	80003c38 <writei+0x4c>
      brelse(bp);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4b4080e7          	jalr	1204(ra) # 8000316e <brelse>
      n = -1;
    80003cc2:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003cc4:	04cba783          	lw	a5,76(s7)
    80003cc8:	0127f463          	bgeu	a5,s2,80003cd0 <writei+0xe4>
      ip->size = off;
    80003ccc:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cd0:	855e                	mv	a0,s7
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	aa4080e7          	jalr	-1372(ra) # 80003776 <iupdate>
  }

  return n;
    80003cda:	000b051b          	sext.w	a0,s6
}
    80003cde:	70a6                	ld	ra,104(sp)
    80003ce0:	7406                	ld	s0,96(sp)
    80003ce2:	64e6                	ld	s1,88(sp)
    80003ce4:	6946                	ld	s2,80(sp)
    80003ce6:	69a6                	ld	s3,72(sp)
    80003ce8:	6a06                	ld	s4,64(sp)
    80003cea:	7ae2                	ld	s5,56(sp)
    80003cec:	7b42                	ld	s6,48(sp)
    80003cee:	7ba2                	ld	s7,40(sp)
    80003cf0:	7c02                	ld	s8,32(sp)
    80003cf2:	6ce2                	ld	s9,24(sp)
    80003cf4:	6d42                	ld	s10,16(sp)
    80003cf6:	6da2                	ld	s11,8(sp)
    80003cf8:	6165                	addi	sp,sp,112
    80003cfa:	8082                	ret
    return -1;
    80003cfc:	557d                	li	a0,-1
}
    80003cfe:	8082                	ret
    return -1;
    80003d00:	557d                	li	a0,-1
    80003d02:	bff1                	j	80003cde <writei+0xf2>
    return -1;
    80003d04:	557d                	li	a0,-1
    80003d06:	bfe1                	j	80003cde <writei+0xf2>

0000000080003d08 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d08:	1141                	addi	sp,sp,-16
    80003d0a:	e406                	sd	ra,8(sp)
    80003d0c:	e022                	sd	s0,0(sp)
    80003d0e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d10:	4639                	li	a2,14
    80003d12:	ffffd097          	auipc	ra,0xffffd
    80003d16:	0e4080e7          	jalr	228(ra) # 80000df6 <strncmp>
}
    80003d1a:	60a2                	ld	ra,8(sp)
    80003d1c:	6402                	ld	s0,0(sp)
    80003d1e:	0141                	addi	sp,sp,16
    80003d20:	8082                	ret

0000000080003d22 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d22:	7139                	addi	sp,sp,-64
    80003d24:	fc06                	sd	ra,56(sp)
    80003d26:	f822                	sd	s0,48(sp)
    80003d28:	f426                	sd	s1,40(sp)
    80003d2a:	f04a                	sd	s2,32(sp)
    80003d2c:	ec4e                	sd	s3,24(sp)
    80003d2e:	e852                	sd	s4,16(sp)
    80003d30:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d32:	04451703          	lh	a4,68(a0)
    80003d36:	4785                	li	a5,1
    80003d38:	00f71a63          	bne	a4,a5,80003d4c <dirlookup+0x2a>
    80003d3c:	892a                	mv	s2,a0
    80003d3e:	89ae                	mv	s3,a1
    80003d40:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d42:	457c                	lw	a5,76(a0)
    80003d44:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d46:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d48:	e79d                	bnez	a5,80003d76 <dirlookup+0x54>
    80003d4a:	a8a5                	j	80003dc2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d4c:	00005517          	auipc	a0,0x5
    80003d50:	88c50513          	addi	a0,a0,-1908 # 800085d8 <syscalls+0x1a0>
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	802080e7          	jalr	-2046(ra) # 80000556 <panic>
      panic("dirlookup read");
    80003d5c:	00005517          	auipc	a0,0x5
    80003d60:	89450513          	addi	a0,a0,-1900 # 800085f0 <syscalls+0x1b8>
    80003d64:	ffffc097          	auipc	ra,0xffffc
    80003d68:	7f2080e7          	jalr	2034(ra) # 80000556 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d6c:	24c1                	addiw	s1,s1,16
    80003d6e:	04c92783          	lw	a5,76(s2)
    80003d72:	04f4f763          	bgeu	s1,a5,80003dc0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d76:	4741                	li	a4,16
    80003d78:	86a6                	mv	a3,s1
    80003d7a:	fc040613          	addi	a2,s0,-64
    80003d7e:	4581                	li	a1,0
    80003d80:	854a                	mv	a0,s2
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	d72080e7          	jalr	-654(ra) # 80003af4 <readi>
    80003d8a:	47c1                	li	a5,16
    80003d8c:	fcf518e3          	bne	a0,a5,80003d5c <dirlookup+0x3a>
    if(de.inum == 0)
    80003d90:	fc045783          	lhu	a5,-64(s0)
    80003d94:	dfe1                	beqz	a5,80003d6c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d96:	fc240593          	addi	a1,s0,-62
    80003d9a:	854e                	mv	a0,s3
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	f6c080e7          	jalr	-148(ra) # 80003d08 <namecmp>
    80003da4:	f561                	bnez	a0,80003d6c <dirlookup+0x4a>
      if(poff)
    80003da6:	000a0463          	beqz	s4,80003dae <dirlookup+0x8c>
        *poff = off;
    80003daa:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003dae:	fc045583          	lhu	a1,-64(s0)
    80003db2:	00092503          	lw	a0,0(s2)
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	756080e7          	jalr	1878(ra) # 8000350c <iget>
    80003dbe:	a011                	j	80003dc2 <dirlookup+0xa0>
  return 0;
    80003dc0:	4501                	li	a0,0
}
    80003dc2:	70e2                	ld	ra,56(sp)
    80003dc4:	7442                	ld	s0,48(sp)
    80003dc6:	74a2                	ld	s1,40(sp)
    80003dc8:	7902                	ld	s2,32(sp)
    80003dca:	69e2                	ld	s3,24(sp)
    80003dcc:	6a42                	ld	s4,16(sp)
    80003dce:	6121                	addi	sp,sp,64
    80003dd0:	8082                	ret

0000000080003dd2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dd2:	711d                	addi	sp,sp,-96
    80003dd4:	ec86                	sd	ra,88(sp)
    80003dd6:	e8a2                	sd	s0,80(sp)
    80003dd8:	e4a6                	sd	s1,72(sp)
    80003dda:	e0ca                	sd	s2,64(sp)
    80003ddc:	fc4e                	sd	s3,56(sp)
    80003dde:	f852                	sd	s4,48(sp)
    80003de0:	f456                	sd	s5,40(sp)
    80003de2:	f05a                	sd	s6,32(sp)
    80003de4:	ec5e                	sd	s7,24(sp)
    80003de6:	e862                	sd	s8,16(sp)
    80003de8:	e466                	sd	s9,8(sp)
    80003dea:	1080                	addi	s0,sp,96
    80003dec:	84aa                	mv	s1,a0
    80003dee:	8b2e                	mv	s6,a1
    80003df0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003df2:	00054703          	lbu	a4,0(a0)
    80003df6:	02f00793          	li	a5,47
    80003dfa:	02f70363          	beq	a4,a5,80003e20 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dfe:	ffffe097          	auipc	ra,0xffffe
    80003e02:	dc8080e7          	jalr	-568(ra) # 80001bc6 <myproc>
    80003e06:	15053503          	ld	a0,336(a0)
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	9f8080e7          	jalr	-1544(ra) # 80003802 <idup>
    80003e12:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e14:	02f00913          	li	s2,47
  len = path - s;
    80003e18:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e1a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e1c:	4c05                	li	s8,1
    80003e1e:	a865                	j	80003ed6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e20:	4585                	li	a1,1
    80003e22:	4505                	li	a0,1
    80003e24:	fffff097          	auipc	ra,0xfffff
    80003e28:	6e8080e7          	jalr	1768(ra) # 8000350c <iget>
    80003e2c:	89aa                	mv	s3,a0
    80003e2e:	b7dd                	j	80003e14 <namex+0x42>
      iunlockput(ip);
    80003e30:	854e                	mv	a0,s3
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	c70080e7          	jalr	-912(ra) # 80003aa2 <iunlockput>
      return 0;
    80003e3a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e3c:	854e                	mv	a0,s3
    80003e3e:	60e6                	ld	ra,88(sp)
    80003e40:	6446                	ld	s0,80(sp)
    80003e42:	64a6                	ld	s1,72(sp)
    80003e44:	6906                	ld	s2,64(sp)
    80003e46:	79e2                	ld	s3,56(sp)
    80003e48:	7a42                	ld	s4,48(sp)
    80003e4a:	7aa2                	ld	s5,40(sp)
    80003e4c:	7b02                	ld	s6,32(sp)
    80003e4e:	6be2                	ld	s7,24(sp)
    80003e50:	6c42                	ld	s8,16(sp)
    80003e52:	6ca2                	ld	s9,8(sp)
    80003e54:	6125                	addi	sp,sp,96
    80003e56:	8082                	ret
      iunlock(ip);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	aa8080e7          	jalr	-1368(ra) # 80003902 <iunlock>
      return ip;
    80003e62:	bfe9                	j	80003e3c <namex+0x6a>
      iunlockput(ip);
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	c3c080e7          	jalr	-964(ra) # 80003aa2 <iunlockput>
      return 0;
    80003e6e:	89d2                	mv	s3,s4
    80003e70:	b7f1                	j	80003e3c <namex+0x6a>
  len = path - s;
    80003e72:	40b48633          	sub	a2,s1,a1
    80003e76:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e7a:	094cd463          	bge	s9,s4,80003f02 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e7e:	4639                	li	a2,14
    80003e80:	8556                	mv	a0,s5
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	ef8080e7          	jalr	-264(ra) # 80000d7a <memmove>
  while(*path == '/')
    80003e8a:	0004c783          	lbu	a5,0(s1)
    80003e8e:	01279763          	bne	a5,s2,80003e9c <namex+0xca>
    path++;
    80003e92:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	ff278de3          	beq	a5,s2,80003e92 <namex+0xc0>
    ilock(ip);
    80003e9c:	854e                	mv	a0,s3
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	9a2080e7          	jalr	-1630(ra) # 80003840 <ilock>
    if(ip->type != T_DIR){
    80003ea6:	04499783          	lh	a5,68(s3)
    80003eaa:	f98793e3          	bne	a5,s8,80003e30 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eae:	000b0563          	beqz	s6,80003eb8 <namex+0xe6>
    80003eb2:	0004c783          	lbu	a5,0(s1)
    80003eb6:	d3cd                	beqz	a5,80003e58 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eb8:	865e                	mv	a2,s7
    80003eba:	85d6                	mv	a1,s5
    80003ebc:	854e                	mv	a0,s3
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	e64080e7          	jalr	-412(ra) # 80003d22 <dirlookup>
    80003ec6:	8a2a                	mv	s4,a0
    80003ec8:	dd51                	beqz	a0,80003e64 <namex+0x92>
    iunlockput(ip);
    80003eca:	854e                	mv	a0,s3
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	bd6080e7          	jalr	-1066(ra) # 80003aa2 <iunlockput>
    ip = next;
    80003ed4:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ed6:	0004c783          	lbu	a5,0(s1)
    80003eda:	05279763          	bne	a5,s2,80003f28 <namex+0x156>
    path++;
    80003ede:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ee0:	0004c783          	lbu	a5,0(s1)
    80003ee4:	ff278de3          	beq	a5,s2,80003ede <namex+0x10c>
  if(*path == 0)
    80003ee8:	c79d                	beqz	a5,80003f16 <namex+0x144>
    path++;
    80003eea:	85a6                	mv	a1,s1
  len = path - s;
    80003eec:	8a5e                	mv	s4,s7
    80003eee:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ef0:	01278963          	beq	a5,s2,80003f02 <namex+0x130>
    80003ef4:	dfbd                	beqz	a5,80003e72 <namex+0xa0>
    path++;
    80003ef6:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ef8:	0004c783          	lbu	a5,0(s1)
    80003efc:	ff279ce3          	bne	a5,s2,80003ef4 <namex+0x122>
    80003f00:	bf8d                	j	80003e72 <namex+0xa0>
    memmove(name, s, len);
    80003f02:	2601                	sext.w	a2,a2
    80003f04:	8556                	mv	a0,s5
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	e74080e7          	jalr	-396(ra) # 80000d7a <memmove>
    name[len] = 0;
    80003f0e:	9a56                	add	s4,s4,s5
    80003f10:	000a0023          	sb	zero,0(s4)
    80003f14:	bf9d                	j	80003e8a <namex+0xb8>
  if(nameiparent){
    80003f16:	f20b03e3          	beqz	s6,80003e3c <namex+0x6a>
    iput(ip);
    80003f1a:	854e                	mv	a0,s3
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	ade080e7          	jalr	-1314(ra) # 800039fa <iput>
    return 0;
    80003f24:	4981                	li	s3,0
    80003f26:	bf19                	j	80003e3c <namex+0x6a>
  if(*path == 0)
    80003f28:	d7fd                	beqz	a5,80003f16 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	85a6                	mv	a1,s1
    80003f30:	b7d1                	j	80003ef4 <namex+0x122>

0000000080003f32 <dirlink>:
{
    80003f32:	7139                	addi	sp,sp,-64
    80003f34:	fc06                	sd	ra,56(sp)
    80003f36:	f822                	sd	s0,48(sp)
    80003f38:	f426                	sd	s1,40(sp)
    80003f3a:	f04a                	sd	s2,32(sp)
    80003f3c:	ec4e                	sd	s3,24(sp)
    80003f3e:	e852                	sd	s4,16(sp)
    80003f40:	0080                	addi	s0,sp,64
    80003f42:	892a                	mv	s2,a0
    80003f44:	8a2e                	mv	s4,a1
    80003f46:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f48:	4601                	li	a2,0
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	dd8080e7          	jalr	-552(ra) # 80003d22 <dirlookup>
    80003f52:	e93d                	bnez	a0,80003fc8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f54:	04c92483          	lw	s1,76(s2)
    80003f58:	c49d                	beqz	s1,80003f86 <dirlink+0x54>
    80003f5a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f5c:	4741                	li	a4,16
    80003f5e:	86a6                	mv	a3,s1
    80003f60:	fc040613          	addi	a2,s0,-64
    80003f64:	4581                	li	a1,0
    80003f66:	854a                	mv	a0,s2
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	b8c080e7          	jalr	-1140(ra) # 80003af4 <readi>
    80003f70:	47c1                	li	a5,16
    80003f72:	06f51163          	bne	a0,a5,80003fd4 <dirlink+0xa2>
    if(de.inum == 0)
    80003f76:	fc045783          	lhu	a5,-64(s0)
    80003f7a:	c791                	beqz	a5,80003f86 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f7c:	24c1                	addiw	s1,s1,16
    80003f7e:	04c92783          	lw	a5,76(s2)
    80003f82:	fcf4ede3          	bltu	s1,a5,80003f5c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f86:	4639                	li	a2,14
    80003f88:	85d2                	mv	a1,s4
    80003f8a:	fc240513          	addi	a0,s0,-62
    80003f8e:	ffffd097          	auipc	ra,0xffffd
    80003f92:	ea4080e7          	jalr	-348(ra) # 80000e32 <strncpy>
  de.inum = inum;
    80003f96:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9a:	4741                	li	a4,16
    80003f9c:	86a6                	mv	a3,s1
    80003f9e:	fc040613          	addi	a2,s0,-64
    80003fa2:	4581                	li	a1,0
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	c46080e7          	jalr	-954(ra) # 80003bec <writei>
    80003fae:	872a                	mv	a4,a0
    80003fb0:	47c1                	li	a5,16
  return 0;
    80003fb2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fb4:	02f71863          	bne	a4,a5,80003fe4 <dirlink+0xb2>
}
    80003fb8:	70e2                	ld	ra,56(sp)
    80003fba:	7442                	ld	s0,48(sp)
    80003fbc:	74a2                	ld	s1,40(sp)
    80003fbe:	7902                	ld	s2,32(sp)
    80003fc0:	69e2                	ld	s3,24(sp)
    80003fc2:	6a42                	ld	s4,16(sp)
    80003fc4:	6121                	addi	sp,sp,64
    80003fc6:	8082                	ret
    iput(ip);
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	a32080e7          	jalr	-1486(ra) # 800039fa <iput>
    return -1;
    80003fd0:	557d                	li	a0,-1
    80003fd2:	b7dd                	j	80003fb8 <dirlink+0x86>
      panic("dirlink read");
    80003fd4:	00004517          	auipc	a0,0x4
    80003fd8:	62c50513          	addi	a0,a0,1580 # 80008600 <syscalls+0x1c8>
    80003fdc:	ffffc097          	auipc	ra,0xffffc
    80003fe0:	57a080e7          	jalr	1402(ra) # 80000556 <panic>
    panic("dirlink");
    80003fe4:	00004517          	auipc	a0,0x4
    80003fe8:	73450513          	addi	a0,a0,1844 # 80008718 <syscalls+0x2e0>
    80003fec:	ffffc097          	auipc	ra,0xffffc
    80003ff0:	56a080e7          	jalr	1386(ra) # 80000556 <panic>

0000000080003ff4 <namei>:

struct inode*
namei(char *path)
{
    80003ff4:	1101                	addi	sp,sp,-32
    80003ff6:	ec06                	sd	ra,24(sp)
    80003ff8:	e822                	sd	s0,16(sp)
    80003ffa:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ffc:	fe040613          	addi	a2,s0,-32
    80004000:	4581                	li	a1,0
    80004002:	00000097          	auipc	ra,0x0
    80004006:	dd0080e7          	jalr	-560(ra) # 80003dd2 <namex>
}
    8000400a:	60e2                	ld	ra,24(sp)
    8000400c:	6442                	ld	s0,16(sp)
    8000400e:	6105                	addi	sp,sp,32
    80004010:	8082                	ret

0000000080004012 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004012:	1141                	addi	sp,sp,-16
    80004014:	e406                	sd	ra,8(sp)
    80004016:	e022                	sd	s0,0(sp)
    80004018:	0800                	addi	s0,sp,16
    8000401a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000401c:	4585                	li	a1,1
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	db4080e7          	jalr	-588(ra) # 80003dd2 <namex>
}
    80004026:	60a2                	ld	ra,8(sp)
    80004028:	6402                	ld	s0,0(sp)
    8000402a:	0141                	addi	sp,sp,16
    8000402c:	8082                	ret

000000008000402e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000402e:	1101                	addi	sp,sp,-32
    80004030:	ec06                	sd	ra,24(sp)
    80004032:	e822                	sd	s0,16(sp)
    80004034:	e426                	sd	s1,8(sp)
    80004036:	e04a                	sd	s2,0(sp)
    80004038:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000403a:	0001e917          	auipc	s2,0x1e
    8000403e:	8ce90913          	addi	s2,s2,-1842 # 80021908 <log>
    80004042:	01892583          	lw	a1,24(s2)
    80004046:	02892503          	lw	a0,40(s2)
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	ff4080e7          	jalr	-12(ra) # 8000303e <bread>
    80004052:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004054:	02c92683          	lw	a3,44(s2)
    80004058:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000405a:	02d05763          	blez	a3,80004088 <write_head+0x5a>
    8000405e:	0001e797          	auipc	a5,0x1e
    80004062:	8da78793          	addi	a5,a5,-1830 # 80021938 <log+0x30>
    80004066:	05c50713          	addi	a4,a0,92
    8000406a:	36fd                	addiw	a3,a3,-1
    8000406c:	1682                	slli	a3,a3,0x20
    8000406e:	9281                	srli	a3,a3,0x20
    80004070:	068a                	slli	a3,a3,0x2
    80004072:	0001e617          	auipc	a2,0x1e
    80004076:	8ca60613          	addi	a2,a2,-1846 # 8002193c <log+0x34>
    8000407a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000407c:	4390                	lw	a2,0(a5)
    8000407e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004080:	0791                	addi	a5,a5,4
    80004082:	0711                	addi	a4,a4,4
    80004084:	fed79ce3          	bne	a5,a3,8000407c <write_head+0x4e>
  }
  bwrite(buf);
    80004088:	8526                	mv	a0,s1
    8000408a:	fffff097          	auipc	ra,0xfffff
    8000408e:	0a6080e7          	jalr	166(ra) # 80003130 <bwrite>
  brelse(buf);
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	0da080e7          	jalr	218(ra) # 8000316e <brelse>
}
    8000409c:	60e2                	ld	ra,24(sp)
    8000409e:	6442                	ld	s0,16(sp)
    800040a0:	64a2                	ld	s1,8(sp)
    800040a2:	6902                	ld	s2,0(sp)
    800040a4:	6105                	addi	sp,sp,32
    800040a6:	8082                	ret

00000000800040a8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a8:	0001e797          	auipc	a5,0x1e
    800040ac:	88c7a783          	lw	a5,-1908(a5) # 80021934 <log+0x2c>
    800040b0:	0af05663          	blez	a5,8000415c <install_trans+0xb4>
{
    800040b4:	7139                	addi	sp,sp,-64
    800040b6:	fc06                	sd	ra,56(sp)
    800040b8:	f822                	sd	s0,48(sp)
    800040ba:	f426                	sd	s1,40(sp)
    800040bc:	f04a                	sd	s2,32(sp)
    800040be:	ec4e                	sd	s3,24(sp)
    800040c0:	e852                	sd	s4,16(sp)
    800040c2:	e456                	sd	s5,8(sp)
    800040c4:	0080                	addi	s0,sp,64
    800040c6:	0001ea97          	auipc	s5,0x1e
    800040ca:	872a8a93          	addi	s5,s5,-1934 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ce:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040d0:	0001e997          	auipc	s3,0x1e
    800040d4:	83898993          	addi	s3,s3,-1992 # 80021908 <log>
    800040d8:	0189a583          	lw	a1,24(s3)
    800040dc:	014585bb          	addw	a1,a1,s4
    800040e0:	2585                	addiw	a1,a1,1
    800040e2:	0289a503          	lw	a0,40(s3)
    800040e6:	fffff097          	auipc	ra,0xfffff
    800040ea:	f58080e7          	jalr	-168(ra) # 8000303e <bread>
    800040ee:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040f0:	000aa583          	lw	a1,0(s5)
    800040f4:	0289a503          	lw	a0,40(s3)
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	f46080e7          	jalr	-186(ra) # 8000303e <bread>
    80004100:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004102:	40000613          	li	a2,1024
    80004106:	05890593          	addi	a1,s2,88
    8000410a:	05850513          	addi	a0,a0,88
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	c6c080e7          	jalr	-916(ra) # 80000d7a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	018080e7          	jalr	24(ra) # 80003130 <bwrite>
    bunpin(dbuf);
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	126080e7          	jalr	294(ra) # 80003248 <bunpin>
    brelse(lbuf);
    8000412a:	854a                	mv	a0,s2
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	042080e7          	jalr	66(ra) # 8000316e <brelse>
    brelse(dbuf);
    80004134:	8526                	mv	a0,s1
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	038080e7          	jalr	56(ra) # 8000316e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000413e:	2a05                	addiw	s4,s4,1
    80004140:	0a91                	addi	s5,s5,4
    80004142:	02c9a783          	lw	a5,44(s3)
    80004146:	f8fa49e3          	blt	s4,a5,800040d8 <install_trans+0x30>
}
    8000414a:	70e2                	ld	ra,56(sp)
    8000414c:	7442                	ld	s0,48(sp)
    8000414e:	74a2                	ld	s1,40(sp)
    80004150:	7902                	ld	s2,32(sp)
    80004152:	69e2                	ld	s3,24(sp)
    80004154:	6a42                	ld	s4,16(sp)
    80004156:	6aa2                	ld	s5,8(sp)
    80004158:	6121                	addi	sp,sp,64
    8000415a:	8082                	ret
    8000415c:	8082                	ret

000000008000415e <initlog>:
{
    8000415e:	7179                	addi	sp,sp,-48
    80004160:	f406                	sd	ra,40(sp)
    80004162:	f022                	sd	s0,32(sp)
    80004164:	ec26                	sd	s1,24(sp)
    80004166:	e84a                	sd	s2,16(sp)
    80004168:	e44e                	sd	s3,8(sp)
    8000416a:	1800                	addi	s0,sp,48
    8000416c:	892a                	mv	s2,a0
    8000416e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004170:	0001d497          	auipc	s1,0x1d
    80004174:	79848493          	addi	s1,s1,1944 # 80021908 <log>
    80004178:	00004597          	auipc	a1,0x4
    8000417c:	49858593          	addi	a1,a1,1176 # 80008610 <syscalls+0x1d8>
    80004180:	8526                	mv	a0,s1
    80004182:	ffffd097          	auipc	ra,0xffffd
    80004186:	a0c080e7          	jalr	-1524(ra) # 80000b8e <initlock>
  log.start = sb->logstart;
    8000418a:	0149a583          	lw	a1,20(s3)
    8000418e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004190:	0109a783          	lw	a5,16(s3)
    80004194:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004196:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000419a:	854a                	mv	a0,s2
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	ea2080e7          	jalr	-350(ra) # 8000303e <bread>
  log.lh.n = lh->n;
    800041a4:	4d3c                	lw	a5,88(a0)
    800041a6:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041a8:	02f05563          	blez	a5,800041d2 <initlog+0x74>
    800041ac:	05c50713          	addi	a4,a0,92
    800041b0:	0001d697          	auipc	a3,0x1d
    800041b4:	78868693          	addi	a3,a3,1928 # 80021938 <log+0x30>
    800041b8:	37fd                	addiw	a5,a5,-1
    800041ba:	1782                	slli	a5,a5,0x20
    800041bc:	9381                	srli	a5,a5,0x20
    800041be:	078a                	slli	a5,a5,0x2
    800041c0:	06050613          	addi	a2,a0,96
    800041c4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041c6:	4310                	lw	a2,0(a4)
    800041c8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041ca:	0711                	addi	a4,a4,4
    800041cc:	0691                	addi	a3,a3,4
    800041ce:	fef71ce3          	bne	a4,a5,800041c6 <initlog+0x68>
  brelse(buf);
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	f9c080e7          	jalr	-100(ra) # 8000316e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041da:	00000097          	auipc	ra,0x0
    800041de:	ece080e7          	jalr	-306(ra) # 800040a8 <install_trans>
  log.lh.n = 0;
    800041e2:	0001d797          	auipc	a5,0x1d
    800041e6:	7407a923          	sw	zero,1874(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	e44080e7          	jalr	-444(ra) # 8000402e <write_head>
}
    800041f2:	70a2                	ld	ra,40(sp)
    800041f4:	7402                	ld	s0,32(sp)
    800041f6:	64e2                	ld	s1,24(sp)
    800041f8:	6942                	ld	s2,16(sp)
    800041fa:	69a2                	ld	s3,8(sp)
    800041fc:	6145                	addi	sp,sp,48
    800041fe:	8082                	ret

0000000080004200 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004200:	1101                	addi	sp,sp,-32
    80004202:	ec06                	sd	ra,24(sp)
    80004204:	e822                	sd	s0,16(sp)
    80004206:	e426                	sd	s1,8(sp)
    80004208:	e04a                	sd	s2,0(sp)
    8000420a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000420c:	0001d517          	auipc	a0,0x1d
    80004210:	6fc50513          	addi	a0,a0,1788 # 80021908 <log>
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	a0a080e7          	jalr	-1526(ra) # 80000c1e <acquire>
  while(1){
    if(log.committing){
    8000421c:	0001d497          	auipc	s1,0x1d
    80004220:	6ec48493          	addi	s1,s1,1772 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004224:	4979                	li	s2,30
    80004226:	a039                	j	80004234 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004228:	85a6                	mv	a1,s1
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffe097          	auipc	ra,0xffffe
    80004230:	1aa080e7          	jalr	426(ra) # 800023d6 <sleep>
    if(log.committing){
    80004234:	50dc                	lw	a5,36(s1)
    80004236:	fbed                	bnez	a5,80004228 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004238:	509c                	lw	a5,32(s1)
    8000423a:	0017871b          	addiw	a4,a5,1
    8000423e:	0007069b          	sext.w	a3,a4
    80004242:	0027179b          	slliw	a5,a4,0x2
    80004246:	9fb9                	addw	a5,a5,a4
    80004248:	0017979b          	slliw	a5,a5,0x1
    8000424c:	54d8                	lw	a4,44(s1)
    8000424e:	9fb9                	addw	a5,a5,a4
    80004250:	00f95963          	bge	s2,a5,80004262 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004254:	85a6                	mv	a1,s1
    80004256:	8526                	mv	a0,s1
    80004258:	ffffe097          	auipc	ra,0xffffe
    8000425c:	17e080e7          	jalr	382(ra) # 800023d6 <sleep>
    80004260:	bfd1                	j	80004234 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004262:	0001d517          	auipc	a0,0x1d
    80004266:	6a650513          	addi	a0,a0,1702 # 80021908 <log>
    8000426a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	a66080e7          	jalr	-1434(ra) # 80000cd2 <release>
      break;
    }
  }
}
    80004274:	60e2                	ld	ra,24(sp)
    80004276:	6442                	ld	s0,16(sp)
    80004278:	64a2                	ld	s1,8(sp)
    8000427a:	6902                	ld	s2,0(sp)
    8000427c:	6105                	addi	sp,sp,32
    8000427e:	8082                	ret

0000000080004280 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004280:	7139                	addi	sp,sp,-64
    80004282:	fc06                	sd	ra,56(sp)
    80004284:	f822                	sd	s0,48(sp)
    80004286:	f426                	sd	s1,40(sp)
    80004288:	f04a                	sd	s2,32(sp)
    8000428a:	ec4e                	sd	s3,24(sp)
    8000428c:	e852                	sd	s4,16(sp)
    8000428e:	e456                	sd	s5,8(sp)
    80004290:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004292:	0001d497          	auipc	s1,0x1d
    80004296:	67648493          	addi	s1,s1,1654 # 80021908 <log>
    8000429a:	8526                	mv	a0,s1
    8000429c:	ffffd097          	auipc	ra,0xffffd
    800042a0:	982080e7          	jalr	-1662(ra) # 80000c1e <acquire>
  log.outstanding -= 1;
    800042a4:	509c                	lw	a5,32(s1)
    800042a6:	37fd                	addiw	a5,a5,-1
    800042a8:	0007891b          	sext.w	s2,a5
    800042ac:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042ae:	50dc                	lw	a5,36(s1)
    800042b0:	efb9                	bnez	a5,8000430e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042b2:	06091663          	bnez	s2,8000431e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042b6:	0001d497          	auipc	s1,0x1d
    800042ba:	65248493          	addi	s1,s1,1618 # 80021908 <log>
    800042be:	4785                	li	a5,1
    800042c0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	a0e080e7          	jalr	-1522(ra) # 80000cd2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042cc:	54dc                	lw	a5,44(s1)
    800042ce:	06f04763          	bgtz	a5,8000433c <end_op+0xbc>
    acquire(&log.lock);
    800042d2:	0001d497          	auipc	s1,0x1d
    800042d6:	63648493          	addi	s1,s1,1590 # 80021908 <log>
    800042da:	8526                	mv	a0,s1
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	942080e7          	jalr	-1726(ra) # 80000c1e <acquire>
    log.committing = 0;
    800042e4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042e8:	8526                	mv	a0,s1
    800042ea:	ffffe097          	auipc	ra,0xffffe
    800042ee:	272080e7          	jalr	626(ra) # 8000255c <wakeup>
    release(&log.lock);
    800042f2:	8526                	mv	a0,s1
    800042f4:	ffffd097          	auipc	ra,0xffffd
    800042f8:	9de080e7          	jalr	-1570(ra) # 80000cd2 <release>
}
    800042fc:	70e2                	ld	ra,56(sp)
    800042fe:	7442                	ld	s0,48(sp)
    80004300:	74a2                	ld	s1,40(sp)
    80004302:	7902                	ld	s2,32(sp)
    80004304:	69e2                	ld	s3,24(sp)
    80004306:	6a42                	ld	s4,16(sp)
    80004308:	6aa2                	ld	s5,8(sp)
    8000430a:	6121                	addi	sp,sp,64
    8000430c:	8082                	ret
    panic("log.committing");
    8000430e:	00004517          	auipc	a0,0x4
    80004312:	30a50513          	addi	a0,a0,778 # 80008618 <syscalls+0x1e0>
    80004316:	ffffc097          	auipc	ra,0xffffc
    8000431a:	240080e7          	jalr	576(ra) # 80000556 <panic>
    wakeup(&log);
    8000431e:	0001d497          	auipc	s1,0x1d
    80004322:	5ea48493          	addi	s1,s1,1514 # 80021908 <log>
    80004326:	8526                	mv	a0,s1
    80004328:	ffffe097          	auipc	ra,0xffffe
    8000432c:	234080e7          	jalr	564(ra) # 8000255c <wakeup>
  release(&log.lock);
    80004330:	8526                	mv	a0,s1
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	9a0080e7          	jalr	-1632(ra) # 80000cd2 <release>
  if(do_commit){
    8000433a:	b7c9                	j	800042fc <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000433c:	0001da97          	auipc	s5,0x1d
    80004340:	5fca8a93          	addi	s5,s5,1532 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004344:	0001da17          	auipc	s4,0x1d
    80004348:	5c4a0a13          	addi	s4,s4,1476 # 80021908 <log>
    8000434c:	018a2583          	lw	a1,24(s4)
    80004350:	012585bb          	addw	a1,a1,s2
    80004354:	2585                	addiw	a1,a1,1
    80004356:	028a2503          	lw	a0,40(s4)
    8000435a:	fffff097          	auipc	ra,0xfffff
    8000435e:	ce4080e7          	jalr	-796(ra) # 8000303e <bread>
    80004362:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004364:	000aa583          	lw	a1,0(s5)
    80004368:	028a2503          	lw	a0,40(s4)
    8000436c:	fffff097          	auipc	ra,0xfffff
    80004370:	cd2080e7          	jalr	-814(ra) # 8000303e <bread>
    80004374:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004376:	40000613          	li	a2,1024
    8000437a:	05850593          	addi	a1,a0,88
    8000437e:	05848513          	addi	a0,s1,88
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	9f8080e7          	jalr	-1544(ra) # 80000d7a <memmove>
    bwrite(to);  // write the log
    8000438a:	8526                	mv	a0,s1
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	da4080e7          	jalr	-604(ra) # 80003130 <bwrite>
    brelse(from);
    80004394:	854e                	mv	a0,s3
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	dd8080e7          	jalr	-552(ra) # 8000316e <brelse>
    brelse(to);
    8000439e:	8526                	mv	a0,s1
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	dce080e7          	jalr	-562(ra) # 8000316e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a8:	2905                	addiw	s2,s2,1
    800043aa:	0a91                	addi	s5,s5,4
    800043ac:	02ca2783          	lw	a5,44(s4)
    800043b0:	f8f94ee3          	blt	s2,a5,8000434c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043b4:	00000097          	auipc	ra,0x0
    800043b8:	c7a080e7          	jalr	-902(ra) # 8000402e <write_head>
    install_trans(); // Now install writes to home locations
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	cec080e7          	jalr	-788(ra) # 800040a8 <install_trans>
    log.lh.n = 0;
    800043c4:	0001d797          	auipc	a5,0x1d
    800043c8:	5607a823          	sw	zero,1392(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	c62080e7          	jalr	-926(ra) # 8000402e <write_head>
    800043d4:	bdfd                	j	800042d2 <end_op+0x52>

00000000800043d6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043d6:	1101                	addi	sp,sp,-32
    800043d8:	ec06                	sd	ra,24(sp)
    800043da:	e822                	sd	s0,16(sp)
    800043dc:	e426                	sd	s1,8(sp)
    800043de:	e04a                	sd	s2,0(sp)
    800043e0:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043e2:	0001d717          	auipc	a4,0x1d
    800043e6:	55272703          	lw	a4,1362(a4) # 80021934 <log+0x2c>
    800043ea:	47f5                	li	a5,29
    800043ec:	08e7c063          	blt	a5,a4,8000446c <log_write+0x96>
    800043f0:	84aa                	mv	s1,a0
    800043f2:	0001d797          	auipc	a5,0x1d
    800043f6:	5327a783          	lw	a5,1330(a5) # 80021924 <log+0x1c>
    800043fa:	37fd                	addiw	a5,a5,-1
    800043fc:	06f75863          	bge	a4,a5,8000446c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004400:	0001d797          	auipc	a5,0x1d
    80004404:	5287a783          	lw	a5,1320(a5) # 80021928 <log+0x20>
    80004408:	06f05a63          	blez	a5,8000447c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000440c:	0001d917          	auipc	s2,0x1d
    80004410:	4fc90913          	addi	s2,s2,1276 # 80021908 <log>
    80004414:	854a                	mv	a0,s2
    80004416:	ffffd097          	auipc	ra,0xffffd
    8000441a:	808080e7          	jalr	-2040(ra) # 80000c1e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000441e:	02c92603          	lw	a2,44(s2)
    80004422:	06c05563          	blez	a2,8000448c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004426:	44cc                	lw	a1,12(s1)
    80004428:	0001d717          	auipc	a4,0x1d
    8000442c:	51070713          	addi	a4,a4,1296 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004430:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004432:	4314                	lw	a3,0(a4)
    80004434:	04b68d63          	beq	a3,a1,8000448e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004438:	2785                	addiw	a5,a5,1
    8000443a:	0711                	addi	a4,a4,4
    8000443c:	fec79be3          	bne	a5,a2,80004432 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004440:	0621                	addi	a2,a2,8
    80004442:	060a                	slli	a2,a2,0x2
    80004444:	0001d797          	auipc	a5,0x1d
    80004448:	4c478793          	addi	a5,a5,1220 # 80021908 <log>
    8000444c:	963e                	add	a2,a2,a5
    8000444e:	44dc                	lw	a5,12(s1)
    80004450:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004452:	8526                	mv	a0,s1
    80004454:	fffff097          	auipc	ra,0xfffff
    80004458:	db8080e7          	jalr	-584(ra) # 8000320c <bpin>
    log.lh.n++;
    8000445c:	0001d717          	auipc	a4,0x1d
    80004460:	4ac70713          	addi	a4,a4,1196 # 80021908 <log>
    80004464:	575c                	lw	a5,44(a4)
    80004466:	2785                	addiw	a5,a5,1
    80004468:	d75c                	sw	a5,44(a4)
    8000446a:	a83d                	j	800044a8 <log_write+0xd2>
    panic("too big a transaction");
    8000446c:	00004517          	auipc	a0,0x4
    80004470:	1bc50513          	addi	a0,a0,444 # 80008628 <syscalls+0x1f0>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	0e2080e7          	jalr	226(ra) # 80000556 <panic>
    panic("log_write outside of trans");
    8000447c:	00004517          	auipc	a0,0x4
    80004480:	1c450513          	addi	a0,a0,452 # 80008640 <syscalls+0x208>
    80004484:	ffffc097          	auipc	ra,0xffffc
    80004488:	0d2080e7          	jalr	210(ra) # 80000556 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000448c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000448e:	00878713          	addi	a4,a5,8
    80004492:	00271693          	slli	a3,a4,0x2
    80004496:	0001d717          	auipc	a4,0x1d
    8000449a:	47270713          	addi	a4,a4,1138 # 80021908 <log>
    8000449e:	9736                	add	a4,a4,a3
    800044a0:	44d4                	lw	a3,12(s1)
    800044a2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044a4:	faf607e3          	beq	a2,a5,80004452 <log_write+0x7c>
  }
  release(&log.lock);
    800044a8:	0001d517          	auipc	a0,0x1d
    800044ac:	46050513          	addi	a0,a0,1120 # 80021908 <log>
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	822080e7          	jalr	-2014(ra) # 80000cd2 <release>
}
    800044b8:	60e2                	ld	ra,24(sp)
    800044ba:	6442                	ld	s0,16(sp)
    800044bc:	64a2                	ld	s1,8(sp)
    800044be:	6902                	ld	s2,0(sp)
    800044c0:	6105                	addi	sp,sp,32
    800044c2:	8082                	ret

00000000800044c4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	e04a                	sd	s2,0(sp)
    800044ce:	1000                	addi	s0,sp,32
    800044d0:	84aa                	mv	s1,a0
    800044d2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044d4:	00004597          	auipc	a1,0x4
    800044d8:	18c58593          	addi	a1,a1,396 # 80008660 <syscalls+0x228>
    800044dc:	0521                	addi	a0,a0,8
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	6b0080e7          	jalr	1712(ra) # 80000b8e <initlock>
  lk->name = name;
    800044e6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044ea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ee:	0204a423          	sw	zero,40(s1)
}
    800044f2:	60e2                	ld	ra,24(sp)
    800044f4:	6442                	ld	s0,16(sp)
    800044f6:	64a2                	ld	s1,8(sp)
    800044f8:	6902                	ld	s2,0(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret

00000000800044fe <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044fe:	1101                	addi	sp,sp,-32
    80004500:	ec06                	sd	ra,24(sp)
    80004502:	e822                	sd	s0,16(sp)
    80004504:	e426                	sd	s1,8(sp)
    80004506:	e04a                	sd	s2,0(sp)
    80004508:	1000                	addi	s0,sp,32
    8000450a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000450c:	00850913          	addi	s2,a0,8
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	70c080e7          	jalr	1804(ra) # 80000c1e <acquire>
  while (lk->locked) {
    8000451a:	409c                	lw	a5,0(s1)
    8000451c:	cb89                	beqz	a5,8000452e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000451e:	85ca                	mv	a1,s2
    80004520:	8526                	mv	a0,s1
    80004522:	ffffe097          	auipc	ra,0xffffe
    80004526:	eb4080e7          	jalr	-332(ra) # 800023d6 <sleep>
  while (lk->locked) {
    8000452a:	409c                	lw	a5,0(s1)
    8000452c:	fbed                	bnez	a5,8000451e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000452e:	4785                	li	a5,1
    80004530:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004532:	ffffd097          	auipc	ra,0xffffd
    80004536:	694080e7          	jalr	1684(ra) # 80001bc6 <myproc>
    8000453a:	5d1c                	lw	a5,56(a0)
    8000453c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000453e:	854a                	mv	a0,s2
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	792080e7          	jalr	1938(ra) # 80000cd2 <release>
}
    80004548:	60e2                	ld	ra,24(sp)
    8000454a:	6442                	ld	s0,16(sp)
    8000454c:	64a2                	ld	s1,8(sp)
    8000454e:	6902                	ld	s2,0(sp)
    80004550:	6105                	addi	sp,sp,32
    80004552:	8082                	ret

0000000080004554 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004554:	1101                	addi	sp,sp,-32
    80004556:	ec06                	sd	ra,24(sp)
    80004558:	e822                	sd	s0,16(sp)
    8000455a:	e426                	sd	s1,8(sp)
    8000455c:	e04a                	sd	s2,0(sp)
    8000455e:	1000                	addi	s0,sp,32
    80004560:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004562:	00850913          	addi	s2,a0,8
    80004566:	854a                	mv	a0,s2
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	6b6080e7          	jalr	1718(ra) # 80000c1e <acquire>
  lk->locked = 0;
    80004570:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004574:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffe097          	auipc	ra,0xffffe
    8000457e:	fe2080e7          	jalr	-30(ra) # 8000255c <wakeup>
  release(&lk->lk);
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	74e080e7          	jalr	1870(ra) # 80000cd2 <release>
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004598:	7179                	addi	sp,sp,-48
    8000459a:	f406                	sd	ra,40(sp)
    8000459c:	f022                	sd	s0,32(sp)
    8000459e:	ec26                	sd	s1,24(sp)
    800045a0:	e84a                	sd	s2,16(sp)
    800045a2:	e44e                	sd	s3,8(sp)
    800045a4:	1800                	addi	s0,sp,48
    800045a6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045a8:	00850913          	addi	s2,a0,8
    800045ac:	854a                	mv	a0,s2
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	670080e7          	jalr	1648(ra) # 80000c1e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b6:	409c                	lw	a5,0(s1)
    800045b8:	ef99                	bnez	a5,800045d6 <holdingsleep+0x3e>
    800045ba:	4481                	li	s1,0
  release(&lk->lk);
    800045bc:	854a                	mv	a0,s2
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	714080e7          	jalr	1812(ra) # 80000cd2 <release>
  return r;
}
    800045c6:	8526                	mv	a0,s1
    800045c8:	70a2                	ld	ra,40(sp)
    800045ca:	7402                	ld	s0,32(sp)
    800045cc:	64e2                	ld	s1,24(sp)
    800045ce:	6942                	ld	s2,16(sp)
    800045d0:	69a2                	ld	s3,8(sp)
    800045d2:	6145                	addi	sp,sp,48
    800045d4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045d6:	0284a983          	lw	s3,40(s1)
    800045da:	ffffd097          	auipc	ra,0xffffd
    800045de:	5ec080e7          	jalr	1516(ra) # 80001bc6 <myproc>
    800045e2:	5d04                	lw	s1,56(a0)
    800045e4:	413484b3          	sub	s1,s1,s3
    800045e8:	0014b493          	seqz	s1,s1
    800045ec:	bfc1                	j	800045bc <holdingsleep+0x24>

00000000800045ee <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045ee:	1141                	addi	sp,sp,-16
    800045f0:	e406                	sd	ra,8(sp)
    800045f2:	e022                	sd	s0,0(sp)
    800045f4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045f6:	00004597          	auipc	a1,0x4
    800045fa:	07a58593          	addi	a1,a1,122 # 80008670 <syscalls+0x238>
    800045fe:	0001d517          	auipc	a0,0x1d
    80004602:	45250513          	addi	a0,a0,1106 # 80021a50 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	588080e7          	jalr	1416(ra) # 80000b8e <initlock>
}
    8000460e:	60a2                	ld	ra,8(sp)
    80004610:	6402                	ld	s0,0(sp)
    80004612:	0141                	addi	sp,sp,16
    80004614:	8082                	ret

0000000080004616 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004616:	1101                	addi	sp,sp,-32
    80004618:	ec06                	sd	ra,24(sp)
    8000461a:	e822                	sd	s0,16(sp)
    8000461c:	e426                	sd	s1,8(sp)
    8000461e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004620:	0001d517          	auipc	a0,0x1d
    80004624:	43050513          	addi	a0,a0,1072 # 80021a50 <ftable>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	5f6080e7          	jalr	1526(ra) # 80000c1e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004630:	0001d497          	auipc	s1,0x1d
    80004634:	43848493          	addi	s1,s1,1080 # 80021a68 <ftable+0x18>
    80004638:	0001e717          	auipc	a4,0x1e
    8000463c:	3d070713          	addi	a4,a4,976 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004640:	40dc                	lw	a5,4(s1)
    80004642:	cf99                	beqz	a5,80004660 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004644:	02848493          	addi	s1,s1,40
    80004648:	fee49ce3          	bne	s1,a4,80004640 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000464c:	0001d517          	auipc	a0,0x1d
    80004650:	40450513          	addi	a0,a0,1028 # 80021a50 <ftable>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	67e080e7          	jalr	1662(ra) # 80000cd2 <release>
  return 0;
    8000465c:	4481                	li	s1,0
    8000465e:	a819                	j	80004674 <filealloc+0x5e>
      f->ref = 1;
    80004660:	4785                	li	a5,1
    80004662:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	3ec50513          	addi	a0,a0,1004 # 80021a50 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	666080e7          	jalr	1638(ra) # 80000cd2 <release>
}
    80004674:	8526                	mv	a0,s1
    80004676:	60e2                	ld	ra,24(sp)
    80004678:	6442                	ld	s0,16(sp)
    8000467a:	64a2                	ld	s1,8(sp)
    8000467c:	6105                	addi	sp,sp,32
    8000467e:	8082                	ret

0000000080004680 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004680:	1101                	addi	sp,sp,-32
    80004682:	ec06                	sd	ra,24(sp)
    80004684:	e822                	sd	s0,16(sp)
    80004686:	e426                	sd	s1,8(sp)
    80004688:	1000                	addi	s0,sp,32
    8000468a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000468c:	0001d517          	auipc	a0,0x1d
    80004690:	3c450513          	addi	a0,a0,964 # 80021a50 <ftable>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	58a080e7          	jalr	1418(ra) # 80000c1e <acquire>
  if(f->ref < 1)
    8000469c:	40dc                	lw	a5,4(s1)
    8000469e:	02f05263          	blez	a5,800046c2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046a2:	2785                	addiw	a5,a5,1
    800046a4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046a6:	0001d517          	auipc	a0,0x1d
    800046aa:	3aa50513          	addi	a0,a0,938 # 80021a50 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	624080e7          	jalr	1572(ra) # 80000cd2 <release>
  return f;
}
    800046b6:	8526                	mv	a0,s1
    800046b8:	60e2                	ld	ra,24(sp)
    800046ba:	6442                	ld	s0,16(sp)
    800046bc:	64a2                	ld	s1,8(sp)
    800046be:	6105                	addi	sp,sp,32
    800046c0:	8082                	ret
    panic("filedup");
    800046c2:	00004517          	auipc	a0,0x4
    800046c6:	fb650513          	addi	a0,a0,-74 # 80008678 <syscalls+0x240>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	e8c080e7          	jalr	-372(ra) # 80000556 <panic>

00000000800046d2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046d2:	7139                	addi	sp,sp,-64
    800046d4:	fc06                	sd	ra,56(sp)
    800046d6:	f822                	sd	s0,48(sp)
    800046d8:	f426                	sd	s1,40(sp)
    800046da:	f04a                	sd	s2,32(sp)
    800046dc:	ec4e                	sd	s3,24(sp)
    800046de:	e852                	sd	s4,16(sp)
    800046e0:	e456                	sd	s5,8(sp)
    800046e2:	0080                	addi	s0,sp,64
    800046e4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046e6:	0001d517          	auipc	a0,0x1d
    800046ea:	36a50513          	addi	a0,a0,874 # 80021a50 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	530080e7          	jalr	1328(ra) # 80000c1e <acquire>
  if(f->ref < 1)
    800046f6:	40dc                	lw	a5,4(s1)
    800046f8:	06f05163          	blez	a5,8000475a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046fc:	37fd                	addiw	a5,a5,-1
    800046fe:	0007871b          	sext.w	a4,a5
    80004702:	c0dc                	sw	a5,4(s1)
    80004704:	06e04363          	bgtz	a4,8000476a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004708:	0004a903          	lw	s2,0(s1)
    8000470c:	0094ca83          	lbu	s5,9(s1)
    80004710:	0104ba03          	ld	s4,16(s1)
    80004714:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004718:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000471c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004720:	0001d517          	auipc	a0,0x1d
    80004724:	33050513          	addi	a0,a0,816 # 80021a50 <ftable>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	5aa080e7          	jalr	1450(ra) # 80000cd2 <release>

  if(ff.type == FD_PIPE){
    80004730:	4785                	li	a5,1
    80004732:	04f90d63          	beq	s2,a5,8000478c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004736:	3979                	addiw	s2,s2,-2
    80004738:	4785                	li	a5,1
    8000473a:	0527e063          	bltu	a5,s2,8000477a <fileclose+0xa8>
    begin_op();
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	ac2080e7          	jalr	-1342(ra) # 80004200 <begin_op>
    iput(ff.ip);
    80004746:	854e                	mv	a0,s3
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2b2080e7          	jalr	690(ra) # 800039fa <iput>
    end_op();
    80004750:	00000097          	auipc	ra,0x0
    80004754:	b30080e7          	jalr	-1232(ra) # 80004280 <end_op>
    80004758:	a00d                	j	8000477a <fileclose+0xa8>
    panic("fileclose");
    8000475a:	00004517          	auipc	a0,0x4
    8000475e:	f2650513          	addi	a0,a0,-218 # 80008680 <syscalls+0x248>
    80004762:	ffffc097          	auipc	ra,0xffffc
    80004766:	df4080e7          	jalr	-524(ra) # 80000556 <panic>
    release(&ftable.lock);
    8000476a:	0001d517          	auipc	a0,0x1d
    8000476e:	2e650513          	addi	a0,a0,742 # 80021a50 <ftable>
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	560080e7          	jalr	1376(ra) # 80000cd2 <release>
  }
}
    8000477a:	70e2                	ld	ra,56(sp)
    8000477c:	7442                	ld	s0,48(sp)
    8000477e:	74a2                	ld	s1,40(sp)
    80004780:	7902                	ld	s2,32(sp)
    80004782:	69e2                	ld	s3,24(sp)
    80004784:	6a42                	ld	s4,16(sp)
    80004786:	6aa2                	ld	s5,8(sp)
    80004788:	6121                	addi	sp,sp,64
    8000478a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000478c:	85d6                	mv	a1,s5
    8000478e:	8552                	mv	a0,s4
    80004790:	00000097          	auipc	ra,0x0
    80004794:	372080e7          	jalr	882(ra) # 80004b02 <pipeclose>
    80004798:	b7cd                	j	8000477a <fileclose+0xa8>

000000008000479a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000479a:	715d                	addi	sp,sp,-80
    8000479c:	e486                	sd	ra,72(sp)
    8000479e:	e0a2                	sd	s0,64(sp)
    800047a0:	fc26                	sd	s1,56(sp)
    800047a2:	f84a                	sd	s2,48(sp)
    800047a4:	f44e                	sd	s3,40(sp)
    800047a6:	0880                	addi	s0,sp,80
    800047a8:	84aa                	mv	s1,a0
    800047aa:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ac:	ffffd097          	auipc	ra,0xffffd
    800047b0:	41a080e7          	jalr	1050(ra) # 80001bc6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047b4:	409c                	lw	a5,0(s1)
    800047b6:	37f9                	addiw	a5,a5,-2
    800047b8:	4705                	li	a4,1
    800047ba:	04f76763          	bltu	a4,a5,80004808 <filestat+0x6e>
    800047be:	892a                	mv	s2,a0
    ilock(f->ip);
    800047c0:	6c88                	ld	a0,24(s1)
    800047c2:	fffff097          	auipc	ra,0xfffff
    800047c6:	07e080e7          	jalr	126(ra) # 80003840 <ilock>
    stati(f->ip, &st);
    800047ca:	fb840593          	addi	a1,s0,-72
    800047ce:	6c88                	ld	a0,24(s1)
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	2fa080e7          	jalr	762(ra) # 80003aca <stati>
    iunlock(f->ip);
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	128080e7          	jalr	296(ra) # 80003902 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047e2:	46e1                	li	a3,24
    800047e4:	fb840613          	addi	a2,s0,-72
    800047e8:	85ce                	mv	a1,s3
    800047ea:	05093503          	ld	a0,80(s2)
    800047ee:	ffffd097          	auipc	ra,0xffffd
    800047f2:	14c080e7          	jalr	332(ra) # 8000193a <copyout>
    800047f6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047fa:	60a6                	ld	ra,72(sp)
    800047fc:	6406                	ld	s0,64(sp)
    800047fe:	74e2                	ld	s1,56(sp)
    80004800:	7942                	ld	s2,48(sp)
    80004802:	79a2                	ld	s3,40(sp)
    80004804:	6161                	addi	sp,sp,80
    80004806:	8082                	ret
  return -1;
    80004808:	557d                	li	a0,-1
    8000480a:	bfc5                	j	800047fa <filestat+0x60>

000000008000480c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000480c:	7179                	addi	sp,sp,-48
    8000480e:	f406                	sd	ra,40(sp)
    80004810:	f022                	sd	s0,32(sp)
    80004812:	ec26                	sd	s1,24(sp)
    80004814:	e84a                	sd	s2,16(sp)
    80004816:	e44e                	sd	s3,8(sp)
    80004818:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000481a:	00854783          	lbu	a5,8(a0)
    8000481e:	c3d5                	beqz	a5,800048c2 <fileread+0xb6>
    80004820:	84aa                	mv	s1,a0
    80004822:	89ae                	mv	s3,a1
    80004824:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004826:	411c                	lw	a5,0(a0)
    80004828:	4705                	li	a4,1
    8000482a:	04e78963          	beq	a5,a4,8000487c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000482e:	470d                	li	a4,3
    80004830:	04e78d63          	beq	a5,a4,8000488a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004834:	4709                	li	a4,2
    80004836:	06e79e63          	bne	a5,a4,800048b2 <fileread+0xa6>
    ilock(f->ip);
    8000483a:	6d08                	ld	a0,24(a0)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	004080e7          	jalr	4(ra) # 80003840 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004844:	874a                	mv	a4,s2
    80004846:	5094                	lw	a3,32(s1)
    80004848:	864e                	mv	a2,s3
    8000484a:	4585                	li	a1,1
    8000484c:	6c88                	ld	a0,24(s1)
    8000484e:	fffff097          	auipc	ra,0xfffff
    80004852:	2a6080e7          	jalr	678(ra) # 80003af4 <readi>
    80004856:	892a                	mv	s2,a0
    80004858:	00a05563          	blez	a0,80004862 <fileread+0x56>
      f->off += r;
    8000485c:	509c                	lw	a5,32(s1)
    8000485e:	9fa9                	addw	a5,a5,a0
    80004860:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004862:	6c88                	ld	a0,24(s1)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	09e080e7          	jalr	158(ra) # 80003902 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000486c:	854a                	mv	a0,s2
    8000486e:	70a2                	ld	ra,40(sp)
    80004870:	7402                	ld	s0,32(sp)
    80004872:	64e2                	ld	s1,24(sp)
    80004874:	6942                	ld	s2,16(sp)
    80004876:	69a2                	ld	s3,8(sp)
    80004878:	6145                	addi	sp,sp,48
    8000487a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000487c:	6908                	ld	a0,16(a0)
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	418080e7          	jalr	1048(ra) # 80004c96 <piperead>
    80004886:	892a                	mv	s2,a0
    80004888:	b7d5                	j	8000486c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000488a:	02451783          	lh	a5,36(a0)
    8000488e:	03079693          	slli	a3,a5,0x30
    80004892:	92c1                	srli	a3,a3,0x30
    80004894:	4725                	li	a4,9
    80004896:	02d76863          	bltu	a4,a3,800048c6 <fileread+0xba>
    8000489a:	0792                	slli	a5,a5,0x4
    8000489c:	0001d717          	auipc	a4,0x1d
    800048a0:	11470713          	addi	a4,a4,276 # 800219b0 <devsw>
    800048a4:	97ba                	add	a5,a5,a4
    800048a6:	639c                	ld	a5,0(a5)
    800048a8:	c38d                	beqz	a5,800048ca <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048aa:	4505                	li	a0,1
    800048ac:	9782                	jalr	a5
    800048ae:	892a                	mv	s2,a0
    800048b0:	bf75                	j	8000486c <fileread+0x60>
    panic("fileread");
    800048b2:	00004517          	auipc	a0,0x4
    800048b6:	dde50513          	addi	a0,a0,-546 # 80008690 <syscalls+0x258>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	c9c080e7          	jalr	-868(ra) # 80000556 <panic>
    return -1;
    800048c2:	597d                	li	s2,-1
    800048c4:	b765                	j	8000486c <fileread+0x60>
      return -1;
    800048c6:	597d                	li	s2,-1
    800048c8:	b755                	j	8000486c <fileread+0x60>
    800048ca:	597d                	li	s2,-1
    800048cc:	b745                	j	8000486c <fileread+0x60>

00000000800048ce <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048ce:	00954783          	lbu	a5,9(a0)
    800048d2:	14078563          	beqz	a5,80004a1c <filewrite+0x14e>
{
    800048d6:	715d                	addi	sp,sp,-80
    800048d8:	e486                	sd	ra,72(sp)
    800048da:	e0a2                	sd	s0,64(sp)
    800048dc:	fc26                	sd	s1,56(sp)
    800048de:	f84a                	sd	s2,48(sp)
    800048e0:	f44e                	sd	s3,40(sp)
    800048e2:	f052                	sd	s4,32(sp)
    800048e4:	ec56                	sd	s5,24(sp)
    800048e6:	e85a                	sd	s6,16(sp)
    800048e8:	e45e                	sd	s7,8(sp)
    800048ea:	e062                	sd	s8,0(sp)
    800048ec:	0880                	addi	s0,sp,80
    800048ee:	892a                	mv	s2,a0
    800048f0:	8aae                	mv	s5,a1
    800048f2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048f4:	411c                	lw	a5,0(a0)
    800048f6:	4705                	li	a4,1
    800048f8:	02e78263          	beq	a5,a4,8000491c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048fc:	470d                	li	a4,3
    800048fe:	02e78563          	beq	a5,a4,80004928 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004902:	4709                	li	a4,2
    80004904:	10e79463          	bne	a5,a4,80004a0c <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004908:	0ec05e63          	blez	a2,80004a04 <filewrite+0x136>
    int i = 0;
    8000490c:	4981                	li	s3,0
    8000490e:	6b05                	lui	s6,0x1
    80004910:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004914:	6b85                	lui	s7,0x1
    80004916:	c00b8b9b          	addiw	s7,s7,-1024
    8000491a:	a851                	j	800049ae <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000491c:	6908                	ld	a0,16(a0)
    8000491e:	00000097          	auipc	ra,0x0
    80004922:	254080e7          	jalr	596(ra) # 80004b72 <pipewrite>
    80004926:	a85d                	j	800049dc <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004928:	02451783          	lh	a5,36(a0)
    8000492c:	03079693          	slli	a3,a5,0x30
    80004930:	92c1                	srli	a3,a3,0x30
    80004932:	4725                	li	a4,9
    80004934:	0ed76663          	bltu	a4,a3,80004a20 <filewrite+0x152>
    80004938:	0792                	slli	a5,a5,0x4
    8000493a:	0001d717          	auipc	a4,0x1d
    8000493e:	07670713          	addi	a4,a4,118 # 800219b0 <devsw>
    80004942:	97ba                	add	a5,a5,a4
    80004944:	679c                	ld	a5,8(a5)
    80004946:	cff9                	beqz	a5,80004a24 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004948:	4505                	li	a0,1
    8000494a:	9782                	jalr	a5
    8000494c:	a841                	j	800049dc <filewrite+0x10e>
    8000494e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004952:	00000097          	auipc	ra,0x0
    80004956:	8ae080e7          	jalr	-1874(ra) # 80004200 <begin_op>
      ilock(f->ip);
    8000495a:	01893503          	ld	a0,24(s2)
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	ee2080e7          	jalr	-286(ra) # 80003840 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004966:	8762                	mv	a4,s8
    80004968:	02092683          	lw	a3,32(s2)
    8000496c:	01598633          	add	a2,s3,s5
    80004970:	4585                	li	a1,1
    80004972:	01893503          	ld	a0,24(s2)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	276080e7          	jalr	630(ra) # 80003bec <writei>
    8000497e:	84aa                	mv	s1,a0
    80004980:	02a05f63          	blez	a0,800049be <filewrite+0xf0>
        f->off += r;
    80004984:	02092783          	lw	a5,32(s2)
    80004988:	9fa9                	addw	a5,a5,a0
    8000498a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000498e:	01893503          	ld	a0,24(s2)
    80004992:	fffff097          	auipc	ra,0xfffff
    80004996:	f70080e7          	jalr	-144(ra) # 80003902 <iunlock>
      end_op();
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	8e6080e7          	jalr	-1818(ra) # 80004280 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049a2:	049c1963          	bne	s8,s1,800049f4 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049a6:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049aa:	0349d663          	bge	s3,s4,800049d6 <filewrite+0x108>
      int n1 = n - i;
    800049ae:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049b2:	84be                	mv	s1,a5
    800049b4:	2781                	sext.w	a5,a5
    800049b6:	f8fb5ce3          	bge	s6,a5,8000494e <filewrite+0x80>
    800049ba:	84de                	mv	s1,s7
    800049bc:	bf49                	j	8000494e <filewrite+0x80>
      iunlock(f->ip);
    800049be:	01893503          	ld	a0,24(s2)
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	f40080e7          	jalr	-192(ra) # 80003902 <iunlock>
      end_op();
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	8b6080e7          	jalr	-1866(ra) # 80004280 <end_op>
      if(r < 0)
    800049d2:	fc04d8e3          	bgez	s1,800049a2 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049d6:	8552                	mv	a0,s4
    800049d8:	033a1863          	bne	s4,s3,80004a08 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049dc:	60a6                	ld	ra,72(sp)
    800049de:	6406                	ld	s0,64(sp)
    800049e0:	74e2                	ld	s1,56(sp)
    800049e2:	7942                	ld	s2,48(sp)
    800049e4:	79a2                	ld	s3,40(sp)
    800049e6:	7a02                	ld	s4,32(sp)
    800049e8:	6ae2                	ld	s5,24(sp)
    800049ea:	6b42                	ld	s6,16(sp)
    800049ec:	6ba2                	ld	s7,8(sp)
    800049ee:	6c02                	ld	s8,0(sp)
    800049f0:	6161                	addi	sp,sp,80
    800049f2:	8082                	ret
        panic("short filewrite");
    800049f4:	00004517          	auipc	a0,0x4
    800049f8:	cac50513          	addi	a0,a0,-852 # 800086a0 <syscalls+0x268>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	b5a080e7          	jalr	-1190(ra) # 80000556 <panic>
    int i = 0;
    80004a04:	4981                	li	s3,0
    80004a06:	bfc1                	j	800049d6 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a08:	557d                	li	a0,-1
    80004a0a:	bfc9                	j	800049dc <filewrite+0x10e>
    panic("filewrite");
    80004a0c:	00004517          	auipc	a0,0x4
    80004a10:	ca450513          	addi	a0,a0,-860 # 800086b0 <syscalls+0x278>
    80004a14:	ffffc097          	auipc	ra,0xffffc
    80004a18:	b42080e7          	jalr	-1214(ra) # 80000556 <panic>
    return -1;
    80004a1c:	557d                	li	a0,-1
}
    80004a1e:	8082                	ret
      return -1;
    80004a20:	557d                	li	a0,-1
    80004a22:	bf6d                	j	800049dc <filewrite+0x10e>
    80004a24:	557d                	li	a0,-1
    80004a26:	bf5d                	j	800049dc <filewrite+0x10e>

0000000080004a28 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a28:	7179                	addi	sp,sp,-48
    80004a2a:	f406                	sd	ra,40(sp)
    80004a2c:	f022                	sd	s0,32(sp)
    80004a2e:	ec26                	sd	s1,24(sp)
    80004a30:	e84a                	sd	s2,16(sp)
    80004a32:	e44e                	sd	s3,8(sp)
    80004a34:	e052                	sd	s4,0(sp)
    80004a36:	1800                	addi	s0,sp,48
    80004a38:	84aa                	mv	s1,a0
    80004a3a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a3c:	0005b023          	sd	zero,0(a1)
    80004a40:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a44:	00000097          	auipc	ra,0x0
    80004a48:	bd2080e7          	jalr	-1070(ra) # 80004616 <filealloc>
    80004a4c:	e088                	sd	a0,0(s1)
    80004a4e:	c551                	beqz	a0,80004ada <pipealloc+0xb2>
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	bc6080e7          	jalr	-1082(ra) # 80004616 <filealloc>
    80004a58:	00aa3023          	sd	a0,0(s4)
    80004a5c:	c92d                	beqz	a0,80004ace <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	0d0080e7          	jalr	208(ra) # 80000b2e <kalloc>
    80004a66:	892a                	mv	s2,a0
    80004a68:	c125                	beqz	a0,80004ac8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a6a:	4985                	li	s3,1
    80004a6c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a70:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a74:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a78:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a7c:	00004597          	auipc	a1,0x4
    80004a80:	c4458593          	addi	a1,a1,-956 # 800086c0 <syscalls+0x288>
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	10a080e7          	jalr	266(ra) # 80000b8e <initlock>
  (*f0)->type = FD_PIPE;
    80004a8c:	609c                	ld	a5,0(s1)
    80004a8e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a92:	609c                	ld	a5,0(s1)
    80004a94:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a98:	609c                	ld	a5,0(s1)
    80004a9a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a9e:	609c                	ld	a5,0(s1)
    80004aa0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aa4:	000a3783          	ld	a5,0(s4)
    80004aa8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aac:	000a3783          	ld	a5,0(s4)
    80004ab0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ab4:	000a3783          	ld	a5,0(s4)
    80004ab8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004abc:	000a3783          	ld	a5,0(s4)
    80004ac0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ac4:	4501                	li	a0,0
    80004ac6:	a025                	j	80004aee <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ac8:	6088                	ld	a0,0(s1)
    80004aca:	e501                	bnez	a0,80004ad2 <pipealloc+0xaa>
    80004acc:	a039                	j	80004ada <pipealloc+0xb2>
    80004ace:	6088                	ld	a0,0(s1)
    80004ad0:	c51d                	beqz	a0,80004afe <pipealloc+0xd6>
    fileclose(*f0);
    80004ad2:	00000097          	auipc	ra,0x0
    80004ad6:	c00080e7          	jalr	-1024(ra) # 800046d2 <fileclose>
  if(*f1)
    80004ada:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ade:	557d                	li	a0,-1
  if(*f1)
    80004ae0:	c799                	beqz	a5,80004aee <pipealloc+0xc6>
    fileclose(*f1);
    80004ae2:	853e                	mv	a0,a5
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	bee080e7          	jalr	-1042(ra) # 800046d2 <fileclose>
  return -1;
    80004aec:	557d                	li	a0,-1
}
    80004aee:	70a2                	ld	ra,40(sp)
    80004af0:	7402                	ld	s0,32(sp)
    80004af2:	64e2                	ld	s1,24(sp)
    80004af4:	6942                	ld	s2,16(sp)
    80004af6:	69a2                	ld	s3,8(sp)
    80004af8:	6a02                	ld	s4,0(sp)
    80004afa:	6145                	addi	sp,sp,48
    80004afc:	8082                	ret
  return -1;
    80004afe:	557d                	li	a0,-1
    80004b00:	b7fd                	j	80004aee <pipealloc+0xc6>

0000000080004b02 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b02:	1101                	addi	sp,sp,-32
    80004b04:	ec06                	sd	ra,24(sp)
    80004b06:	e822                	sd	s0,16(sp)
    80004b08:	e426                	sd	s1,8(sp)
    80004b0a:	e04a                	sd	s2,0(sp)
    80004b0c:	1000                	addi	s0,sp,32
    80004b0e:	84aa                	mv	s1,a0
    80004b10:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	10c080e7          	jalr	268(ra) # 80000c1e <acquire>
  if(writable){
    80004b1a:	02090d63          	beqz	s2,80004b54 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b1e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b22:	21848513          	addi	a0,s1,536
    80004b26:	ffffe097          	auipc	ra,0xffffe
    80004b2a:	a36080e7          	jalr	-1482(ra) # 8000255c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b2e:	2204b783          	ld	a5,544(s1)
    80004b32:	eb95                	bnez	a5,80004b66 <pipeclose+0x64>
    release(&pi->lock);
    80004b34:	8526                	mv	a0,s1
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	19c080e7          	jalr	412(ra) # 80000cd2 <release>
    kfree((char*)pi);
    80004b3e:	8526                	mv	a0,s1
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	ef2080e7          	jalr	-270(ra) # 80000a32 <kfree>
  } else
    release(&pi->lock);
}
    80004b48:	60e2                	ld	ra,24(sp)
    80004b4a:	6442                	ld	s0,16(sp)
    80004b4c:	64a2                	ld	s1,8(sp)
    80004b4e:	6902                	ld	s2,0(sp)
    80004b50:	6105                	addi	sp,sp,32
    80004b52:	8082                	ret
    pi->readopen = 0;
    80004b54:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b58:	21c48513          	addi	a0,s1,540
    80004b5c:	ffffe097          	auipc	ra,0xffffe
    80004b60:	a00080e7          	jalr	-1536(ra) # 8000255c <wakeup>
    80004b64:	b7e9                	j	80004b2e <pipeclose+0x2c>
    release(&pi->lock);
    80004b66:	8526                	mv	a0,s1
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	16a080e7          	jalr	362(ra) # 80000cd2 <release>
}
    80004b70:	bfe1                	j	80004b48 <pipeclose+0x46>

0000000080004b72 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b72:	7119                	addi	sp,sp,-128
    80004b74:	fc86                	sd	ra,120(sp)
    80004b76:	f8a2                	sd	s0,112(sp)
    80004b78:	f4a6                	sd	s1,104(sp)
    80004b7a:	f0ca                	sd	s2,96(sp)
    80004b7c:	ecce                	sd	s3,88(sp)
    80004b7e:	e8d2                	sd	s4,80(sp)
    80004b80:	e4d6                	sd	s5,72(sp)
    80004b82:	e0da                	sd	s6,64(sp)
    80004b84:	fc5e                	sd	s7,56(sp)
    80004b86:	f862                	sd	s8,48(sp)
    80004b88:	f466                	sd	s9,40(sp)
    80004b8a:	f06a                	sd	s10,32(sp)
    80004b8c:	ec6e                	sd	s11,24(sp)
    80004b8e:	0100                	addi	s0,sp,128
    80004b90:	84aa                	mv	s1,a0
    80004b92:	8cae                	mv	s9,a1
    80004b94:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	030080e7          	jalr	48(ra) # 80001bc6 <myproc>
    80004b9e:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	07c080e7          	jalr	124(ra) # 80000c1e <acquire>
  for(i = 0; i < n; i++){
    80004baa:	0d605963          	blez	s6,80004c7c <pipewrite+0x10a>
    80004bae:	89a6                	mv	s3,s1
    80004bb0:	3b7d                	addiw	s6,s6,-1
    80004bb2:	1b02                	slli	s6,s6,0x20
    80004bb4:	020b5b13          	srli	s6,s6,0x20
    80004bb8:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004bba:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bbe:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bc2:	5dfd                	li	s11,-1
    80004bc4:	000b8d1b          	sext.w	s10,s7
    80004bc8:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bca:	2184a783          	lw	a5,536(s1)
    80004bce:	21c4a703          	lw	a4,540(s1)
    80004bd2:	2007879b          	addiw	a5,a5,512
    80004bd6:	02f71b63          	bne	a4,a5,80004c0c <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004bda:	2204a783          	lw	a5,544(s1)
    80004bde:	cbad                	beqz	a5,80004c50 <pipewrite+0xde>
    80004be0:	03092783          	lw	a5,48(s2)
    80004be4:	e7b5                	bnez	a5,80004c50 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004be6:	8556                	mv	a0,s5
    80004be8:	ffffe097          	auipc	ra,0xffffe
    80004bec:	974080e7          	jalr	-1676(ra) # 8000255c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bf0:	85ce                	mv	a1,s3
    80004bf2:	8552                	mv	a0,s4
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	7e2080e7          	jalr	2018(ra) # 800023d6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bfc:	2184a783          	lw	a5,536(s1)
    80004c00:	21c4a703          	lw	a4,540(s1)
    80004c04:	2007879b          	addiw	a5,a5,512
    80004c08:	fcf709e3          	beq	a4,a5,80004bda <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c0c:	4685                	li	a3,1
    80004c0e:	019b8633          	add	a2,s7,s9
    80004c12:	f8f40593          	addi	a1,s0,-113
    80004c16:	05093503          	ld	a0,80(s2)
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	dc6080e7          	jalr	-570(ra) # 800019e0 <copyin>
    80004c22:	05b50e63          	beq	a0,s11,80004c7e <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c26:	21c4a783          	lw	a5,540(s1)
    80004c2a:	0017871b          	addiw	a4,a5,1
    80004c2e:	20e4ae23          	sw	a4,540(s1)
    80004c32:	1ff7f793          	andi	a5,a5,511
    80004c36:	97a6                	add	a5,a5,s1
    80004c38:	f8f44703          	lbu	a4,-113(s0)
    80004c3c:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c40:	001d0c1b          	addiw	s8,s10,1
    80004c44:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c48:	036b8b63          	beq	s7,s6,80004c7e <pipewrite+0x10c>
    80004c4c:	8bbe                	mv	s7,a5
    80004c4e:	bf9d                	j	80004bc4 <pipewrite+0x52>
        release(&pi->lock);
    80004c50:	8526                	mv	a0,s1
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	080080e7          	jalr	128(ra) # 80000cd2 <release>
        return -1;
    80004c5a:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c5c:	8562                	mv	a0,s8
    80004c5e:	70e6                	ld	ra,120(sp)
    80004c60:	7446                	ld	s0,112(sp)
    80004c62:	74a6                	ld	s1,104(sp)
    80004c64:	7906                	ld	s2,96(sp)
    80004c66:	69e6                	ld	s3,88(sp)
    80004c68:	6a46                	ld	s4,80(sp)
    80004c6a:	6aa6                	ld	s5,72(sp)
    80004c6c:	6b06                	ld	s6,64(sp)
    80004c6e:	7be2                	ld	s7,56(sp)
    80004c70:	7c42                	ld	s8,48(sp)
    80004c72:	7ca2                	ld	s9,40(sp)
    80004c74:	7d02                	ld	s10,32(sp)
    80004c76:	6de2                	ld	s11,24(sp)
    80004c78:	6109                	addi	sp,sp,128
    80004c7a:	8082                	ret
  for(i = 0; i < n; i++){
    80004c7c:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c7e:	21848513          	addi	a0,s1,536
    80004c82:	ffffe097          	auipc	ra,0xffffe
    80004c86:	8da080e7          	jalr	-1830(ra) # 8000255c <wakeup>
  release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	046080e7          	jalr	70(ra) # 80000cd2 <release>
  return i;
    80004c94:	b7e1                	j	80004c5c <pipewrite+0xea>

0000000080004c96 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c96:	715d                	addi	sp,sp,-80
    80004c98:	e486                	sd	ra,72(sp)
    80004c9a:	e0a2                	sd	s0,64(sp)
    80004c9c:	fc26                	sd	s1,56(sp)
    80004c9e:	f84a                	sd	s2,48(sp)
    80004ca0:	f44e                	sd	s3,40(sp)
    80004ca2:	f052                	sd	s4,32(sp)
    80004ca4:	ec56                	sd	s5,24(sp)
    80004ca6:	e85a                	sd	s6,16(sp)
    80004ca8:	0880                	addi	s0,sp,80
    80004caa:	84aa                	mv	s1,a0
    80004cac:	892e                	mv	s2,a1
    80004cae:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cb0:	ffffd097          	auipc	ra,0xffffd
    80004cb4:	f16080e7          	jalr	-234(ra) # 80001bc6 <myproc>
    80004cb8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cba:	8b26                	mv	s6,s1
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	ffffc097          	auipc	ra,0xffffc
    80004cc2:	f60080e7          	jalr	-160(ra) # 80000c1e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc6:	2184a703          	lw	a4,536(s1)
    80004cca:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cce:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd2:	02f71463          	bne	a4,a5,80004cfa <piperead+0x64>
    80004cd6:	2244a783          	lw	a5,548(s1)
    80004cda:	c385                	beqz	a5,80004cfa <piperead+0x64>
    if(pr->killed){
    80004cdc:	030a2783          	lw	a5,48(s4)
    80004ce0:	ebc1                	bnez	a5,80004d70 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce2:	85da                	mv	a1,s6
    80004ce4:	854e                	mv	a0,s3
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	6f0080e7          	jalr	1776(ra) # 800023d6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cee:	2184a703          	lw	a4,536(s1)
    80004cf2:	21c4a783          	lw	a5,540(s1)
    80004cf6:	fef700e3          	beq	a4,a5,80004cd6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfa:	09505263          	blez	s5,80004d7e <piperead+0xe8>
    80004cfe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d00:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d02:	2184a783          	lw	a5,536(s1)
    80004d06:	21c4a703          	lw	a4,540(s1)
    80004d0a:	02f70d63          	beq	a4,a5,80004d44 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ac23          	sw	a4,536(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	0187c783          	lbu	a5,24(a5)
    80004d20:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d24:	4685                	li	a3,1
    80004d26:	fbf40613          	addi	a2,s0,-65
    80004d2a:	85ca                	mv	a1,s2
    80004d2c:	050a3503          	ld	a0,80(s4)
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	c0a080e7          	jalr	-1014(ra) # 8000193a <copyout>
    80004d38:	01650663          	beq	a0,s6,80004d44 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3c:	2985                	addiw	s3,s3,1
    80004d3e:	0905                	addi	s2,s2,1
    80004d40:	fd3a91e3          	bne	s5,s3,80004d02 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d44:	21c48513          	addi	a0,s1,540
    80004d48:	ffffe097          	auipc	ra,0xffffe
    80004d4c:	814080e7          	jalr	-2028(ra) # 8000255c <wakeup>
  release(&pi->lock);
    80004d50:	8526                	mv	a0,s1
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	f80080e7          	jalr	-128(ra) # 80000cd2 <release>
  return i;
}
    80004d5a:	854e                	mv	a0,s3
    80004d5c:	60a6                	ld	ra,72(sp)
    80004d5e:	6406                	ld	s0,64(sp)
    80004d60:	74e2                	ld	s1,56(sp)
    80004d62:	7942                	ld	s2,48(sp)
    80004d64:	79a2                	ld	s3,40(sp)
    80004d66:	7a02                	ld	s4,32(sp)
    80004d68:	6ae2                	ld	s5,24(sp)
    80004d6a:	6b42                	ld	s6,16(sp)
    80004d6c:	6161                	addi	sp,sp,80
    80004d6e:	8082                	ret
      release(&pi->lock);
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	f60080e7          	jalr	-160(ra) # 80000cd2 <release>
      return -1;
    80004d7a:	59fd                	li	s3,-1
    80004d7c:	bff9                	j	80004d5a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7e:	4981                	li	s3,0
    80004d80:	b7d1                	j	80004d44 <piperead+0xae>

0000000080004d82 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d82:	df010113          	addi	sp,sp,-528
    80004d86:	20113423          	sd	ra,520(sp)
    80004d8a:	20813023          	sd	s0,512(sp)
    80004d8e:	ffa6                	sd	s1,504(sp)
    80004d90:	fbca                	sd	s2,496(sp)
    80004d92:	f7ce                	sd	s3,488(sp)
    80004d94:	f3d2                	sd	s4,480(sp)
    80004d96:	efd6                	sd	s5,472(sp)
    80004d98:	ebda                	sd	s6,464(sp)
    80004d9a:	e7de                	sd	s7,456(sp)
    80004d9c:	e3e2                	sd	s8,448(sp)
    80004d9e:	ff66                	sd	s9,440(sp)
    80004da0:	fb6a                	sd	s10,432(sp)
    80004da2:	f76e                	sd	s11,424(sp)
    80004da4:	0c00                	addi	s0,sp,528
    80004da6:	84aa                	mv	s1,a0
    80004da8:	dea43c23          	sd	a0,-520(s0)
    80004dac:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004db0:	ffffd097          	auipc	ra,0xffffd
    80004db4:	e16080e7          	jalr	-490(ra) # 80001bc6 <myproc>
    80004db8:	892a                	mv	s2,a0

  begin_op();
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	446080e7          	jalr	1094(ra) # 80004200 <begin_op>

  if((ip = namei(path)) == 0){
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	230080e7          	jalr	560(ra) # 80003ff4 <namei>
    80004dcc:	c92d                	beqz	a0,80004e3e <exec+0xbc>
    80004dce:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	a70080e7          	jalr	-1424(ra) # 80003840 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dd8:	04000713          	li	a4,64
    80004ddc:	4681                	li	a3,0
    80004dde:	e4840613          	addi	a2,s0,-440
    80004de2:	4581                	li	a1,0
    80004de4:	8526                	mv	a0,s1
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	d0e080e7          	jalr	-754(ra) # 80003af4 <readi>
    80004dee:	04000793          	li	a5,64
    80004df2:	00f51a63          	bne	a0,a5,80004e06 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004df6:	e4842703          	lw	a4,-440(s0)
    80004dfa:	464c47b7          	lui	a5,0x464c4
    80004dfe:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e02:	04f70463          	beq	a4,a5,80004e4a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e06:	8526                	mv	a0,s1
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	c9a080e7          	jalr	-870(ra) # 80003aa2 <iunlockput>
    end_op();
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	470080e7          	jalr	1136(ra) # 80004280 <end_op>
  }
  return -1;
    80004e18:	557d                	li	a0,-1
}
    80004e1a:	20813083          	ld	ra,520(sp)
    80004e1e:	20013403          	ld	s0,512(sp)
    80004e22:	74fe                	ld	s1,504(sp)
    80004e24:	795e                	ld	s2,496(sp)
    80004e26:	79be                	ld	s3,488(sp)
    80004e28:	7a1e                	ld	s4,480(sp)
    80004e2a:	6afe                	ld	s5,472(sp)
    80004e2c:	6b5e                	ld	s6,464(sp)
    80004e2e:	6bbe                	ld	s7,456(sp)
    80004e30:	6c1e                	ld	s8,448(sp)
    80004e32:	7cfa                	ld	s9,440(sp)
    80004e34:	7d5a                	ld	s10,432(sp)
    80004e36:	7dba                	ld	s11,424(sp)
    80004e38:	21010113          	addi	sp,sp,528
    80004e3c:	8082                	ret
    end_op();
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	442080e7          	jalr	1090(ra) # 80004280 <end_op>
    return -1;
    80004e46:	557d                	li	a0,-1
    80004e48:	bfc9                	j	80004e1a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e4a:	854a                	mv	a0,s2
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	e3e080e7          	jalr	-450(ra) # 80001c8a <proc_pagetable>
    80004e54:	8baa                	mv	s7,a0
    80004e56:	d945                	beqz	a0,80004e06 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e58:	e6842983          	lw	s3,-408(s0)
    80004e5c:	e8045783          	lhu	a5,-384(s0)
    80004e60:	c7ad                	beqz	a5,80004eca <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e62:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e64:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e66:	6c85                	lui	s9,0x1
    80004e68:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e6c:	def43823          	sd	a5,-528(s0)
    80004e70:	a42d                	j	8000509a <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e72:	00004517          	auipc	a0,0x4
    80004e76:	85650513          	addi	a0,a0,-1962 # 800086c8 <syscalls+0x290>
    80004e7a:	ffffb097          	auipc	ra,0xffffb
    80004e7e:	6dc080e7          	jalr	1756(ra) # 80000556 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e82:	8756                	mv	a4,s5
    80004e84:	012d86bb          	addw	a3,s11,s2
    80004e88:	4581                	li	a1,0
    80004e8a:	8526                	mv	a0,s1
    80004e8c:	fffff097          	auipc	ra,0xfffff
    80004e90:	c68080e7          	jalr	-920(ra) # 80003af4 <readi>
    80004e94:	2501                	sext.w	a0,a0
    80004e96:	1aaa9963          	bne	s5,a0,80005048 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e9a:	6785                	lui	a5,0x1
    80004e9c:	0127893b          	addw	s2,a5,s2
    80004ea0:	77fd                	lui	a5,0xfffff
    80004ea2:	01478a3b          	addw	s4,a5,s4
    80004ea6:	1f897163          	bgeu	s2,s8,80005088 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004eaa:	02091593          	slli	a1,s2,0x20
    80004eae:	9181                	srli	a1,a1,0x20
    80004eb0:	95ea                	add	a1,a1,s10
    80004eb2:	855e                	mv	a0,s7
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	1f8080e7          	jalr	504(ra) # 800010ac <walkaddr>
    80004ebc:	862a                	mv	a2,a0
    if(pa == 0)
    80004ebe:	d955                	beqz	a0,80004e72 <exec+0xf0>
      n = PGSIZE;
    80004ec0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ec2:	fd9a70e3          	bgeu	s4,s9,80004e82 <exec+0x100>
      n = sz - i;
    80004ec6:	8ad2                	mv	s5,s4
    80004ec8:	bf6d                	j	80004e82 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004eca:	4901                	li	s2,0
  iunlockput(ip);
    80004ecc:	8526                	mv	a0,s1
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	bd4080e7          	jalr	-1068(ra) # 80003aa2 <iunlockput>
  end_op();
    80004ed6:	fffff097          	auipc	ra,0xfffff
    80004eda:	3aa080e7          	jalr	938(ra) # 80004280 <end_op>
  p = myproc();
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	ce8080e7          	jalr	-792(ra) # 80001bc6 <myproc>
    80004ee6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ee8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eec:	6785                	lui	a5,0x1
    80004eee:	17fd                	addi	a5,a5,-1
    80004ef0:	993e                	add	s2,s2,a5
    80004ef2:	757d                	lui	a0,0xfffff
    80004ef4:	00a977b3          	and	a5,s2,a0
    80004ef8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004efc:	6609                	lui	a2,0x2
    80004efe:	963e                	add	a2,a2,a5
    80004f00:	85be                	mv	a1,a5
    80004f02:	855e                	mv	a0,s7
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	56e080e7          	jalr	1390(ra) # 80001472 <uvmalloc>
    80004f0c:	8b2a                	mv	s6,a0
  ip = 0;
    80004f0e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f10:	12050c63          	beqz	a0,80005048 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f14:	75f9                	lui	a1,0xffffe
    80004f16:	95aa                	add	a1,a1,a0
    80004f18:	855e                	mv	a0,s7
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	75a080e7          	jalr	1882(ra) # 80001674 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f22:	7c7d                	lui	s8,0xfffff
    80004f24:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f26:	e0043783          	ld	a5,-512(s0)
    80004f2a:	6388                	ld	a0,0(a5)
    80004f2c:	c535                	beqz	a0,80004f98 <exec+0x216>
    80004f2e:	e8840993          	addi	s3,s0,-376
    80004f32:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f36:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	f6a080e7          	jalr	-150(ra) # 80000ea2 <strlen>
    80004f40:	2505                	addiw	a0,a0,1
    80004f42:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f46:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f4a:	13896363          	bltu	s2,s8,80005070 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f4e:	e0043d83          	ld	s11,-512(s0)
    80004f52:	000dba03          	ld	s4,0(s11)
    80004f56:	8552                	mv	a0,s4
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	f4a080e7          	jalr	-182(ra) # 80000ea2 <strlen>
    80004f60:	0015069b          	addiw	a3,a0,1
    80004f64:	8652                	mv	a2,s4
    80004f66:	85ca                	mv	a1,s2
    80004f68:	855e                	mv	a0,s7
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	9d0080e7          	jalr	-1584(ra) # 8000193a <copyout>
    80004f72:	10054363          	bltz	a0,80005078 <exec+0x2f6>
    ustack[argc] = sp;
    80004f76:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f7a:	0485                	addi	s1,s1,1
    80004f7c:	008d8793          	addi	a5,s11,8
    80004f80:	e0f43023          	sd	a5,-512(s0)
    80004f84:	008db503          	ld	a0,8(s11)
    80004f88:	c911                	beqz	a0,80004f9c <exec+0x21a>
    if(argc >= MAXARG)
    80004f8a:	09a1                	addi	s3,s3,8
    80004f8c:	fb3c96e3          	bne	s9,s3,80004f38 <exec+0x1b6>
  sz = sz1;
    80004f90:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f94:	4481                	li	s1,0
    80004f96:	a84d                	j	80005048 <exec+0x2c6>
  sp = sz;
    80004f98:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f9a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f9c:	00349793          	slli	a5,s1,0x3
    80004fa0:	f9040713          	addi	a4,s0,-112
    80004fa4:	97ba                	add	a5,a5,a4
    80004fa6:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004faa:	00148693          	addi	a3,s1,1
    80004fae:	068e                	slli	a3,a3,0x3
    80004fb0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fb4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fb8:	01897663          	bgeu	s2,s8,80004fc4 <exec+0x242>
  sz = sz1;
    80004fbc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc0:	4481                	li	s1,0
    80004fc2:	a059                	j	80005048 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fc4:	e8840613          	addi	a2,s0,-376
    80004fc8:	85ca                	mv	a1,s2
    80004fca:	855e                	mv	a0,s7
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	96e080e7          	jalr	-1682(ra) # 8000193a <copyout>
    80004fd4:	0a054663          	bltz	a0,80005080 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fd8:	058ab783          	ld	a5,88(s5)
    80004fdc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fe0:	df843783          	ld	a5,-520(s0)
    80004fe4:	0007c703          	lbu	a4,0(a5)
    80004fe8:	cf11                	beqz	a4,80005004 <exec+0x282>
    80004fea:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fec:	02f00693          	li	a3,47
    80004ff0:	a029                	j	80004ffa <exec+0x278>
  for(last=s=path; *s; s++)
    80004ff2:	0785                	addi	a5,a5,1
    80004ff4:	fff7c703          	lbu	a4,-1(a5)
    80004ff8:	c711                	beqz	a4,80005004 <exec+0x282>
    if(*s == '/')
    80004ffa:	fed71ce3          	bne	a4,a3,80004ff2 <exec+0x270>
      last = s+1;
    80004ffe:	def43c23          	sd	a5,-520(s0)
    80005002:	bfc5                	j	80004ff2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005004:	4641                	li	a2,16
    80005006:	df843583          	ld	a1,-520(s0)
    8000500a:	158a8513          	addi	a0,s5,344
    8000500e:	ffffc097          	auipc	ra,0xffffc
    80005012:	e62080e7          	jalr	-414(ra) # 80000e70 <safestrcpy>
  oldpagetable = p->pagetable;
    80005016:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000501a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000501e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005022:	058ab783          	ld	a5,88(s5)
    80005026:	e6043703          	ld	a4,-416(s0)
    8000502a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000502c:	058ab783          	ld	a5,88(s5)
    80005030:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005034:	85ea                	mv	a1,s10
    80005036:	ffffd097          	auipc	ra,0xffffd
    8000503a:	cf0080e7          	jalr	-784(ra) # 80001d26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000503e:	0004851b          	sext.w	a0,s1
    80005042:	bbe1                	j	80004e1a <exec+0x98>
    80005044:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005048:	e0843583          	ld	a1,-504(s0)
    8000504c:	855e                	mv	a0,s7
    8000504e:	ffffd097          	auipc	ra,0xffffd
    80005052:	cd8080e7          	jalr	-808(ra) # 80001d26 <proc_freepagetable>
  if(ip){
    80005056:	da0498e3          	bnez	s1,80004e06 <exec+0x84>
  return -1;
    8000505a:	557d                	li	a0,-1
    8000505c:	bb7d                	j	80004e1a <exec+0x98>
    8000505e:	e1243423          	sd	s2,-504(s0)
    80005062:	b7dd                	j	80005048 <exec+0x2c6>
    80005064:	e1243423          	sd	s2,-504(s0)
    80005068:	b7c5                	j	80005048 <exec+0x2c6>
    8000506a:	e1243423          	sd	s2,-504(s0)
    8000506e:	bfe9                	j	80005048 <exec+0x2c6>
  sz = sz1;
    80005070:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005074:	4481                	li	s1,0
    80005076:	bfc9                	j	80005048 <exec+0x2c6>
  sz = sz1;
    80005078:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507c:	4481                	li	s1,0
    8000507e:	b7e9                	j	80005048 <exec+0x2c6>
  sz = sz1;
    80005080:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005084:	4481                	li	s1,0
    80005086:	b7c9                	j	80005048 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005088:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000508c:	2b05                	addiw	s6,s6,1
    8000508e:	0389899b          	addiw	s3,s3,56
    80005092:	e8045783          	lhu	a5,-384(s0)
    80005096:	e2fb5be3          	bge	s6,a5,80004ecc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000509a:	2981                	sext.w	s3,s3
    8000509c:	03800713          	li	a4,56
    800050a0:	86ce                	mv	a3,s3
    800050a2:	e1040613          	addi	a2,s0,-496
    800050a6:	4581                	li	a1,0
    800050a8:	8526                	mv	a0,s1
    800050aa:	fffff097          	auipc	ra,0xfffff
    800050ae:	a4a080e7          	jalr	-1462(ra) # 80003af4 <readi>
    800050b2:	03800793          	li	a5,56
    800050b6:	f8f517e3          	bne	a0,a5,80005044 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800050ba:	e1042783          	lw	a5,-496(s0)
    800050be:	4705                	li	a4,1
    800050c0:	fce796e3          	bne	a5,a4,8000508c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050c4:	e3843603          	ld	a2,-456(s0)
    800050c8:	e3043783          	ld	a5,-464(s0)
    800050cc:	f8f669e3          	bltu	a2,a5,8000505e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050d0:	e2043783          	ld	a5,-480(s0)
    800050d4:	963e                	add	a2,a2,a5
    800050d6:	f8f667e3          	bltu	a2,a5,80005064 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050da:	85ca                	mv	a1,s2
    800050dc:	855e                	mv	a0,s7
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	394080e7          	jalr	916(ra) # 80001472 <uvmalloc>
    800050e6:	e0a43423          	sd	a0,-504(s0)
    800050ea:	d141                	beqz	a0,8000506a <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800050ec:	e2043d03          	ld	s10,-480(s0)
    800050f0:	df043783          	ld	a5,-528(s0)
    800050f4:	00fd77b3          	and	a5,s10,a5
    800050f8:	fba1                	bnez	a5,80005048 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050fa:	e1842d83          	lw	s11,-488(s0)
    800050fe:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005102:	f80c03e3          	beqz	s8,80005088 <exec+0x306>
    80005106:	8a62                	mv	s4,s8
    80005108:	4901                	li	s2,0
    8000510a:	b345                	j	80004eaa <exec+0x128>

000000008000510c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000510c:	7179                	addi	sp,sp,-48
    8000510e:	f406                	sd	ra,40(sp)
    80005110:	f022                	sd	s0,32(sp)
    80005112:	ec26                	sd	s1,24(sp)
    80005114:	e84a                	sd	s2,16(sp)
    80005116:	1800                	addi	s0,sp,48
    80005118:	892e                	mv	s2,a1
    8000511a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000511c:	fdc40593          	addi	a1,s0,-36
    80005120:	ffffe097          	auipc	ra,0xffffe
    80005124:	b98080e7          	jalr	-1128(ra) # 80002cb8 <argint>
    80005128:	04054063          	bltz	a0,80005168 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000512c:	fdc42703          	lw	a4,-36(s0)
    80005130:	47bd                	li	a5,15
    80005132:	02e7ed63          	bltu	a5,a4,8000516c <argfd+0x60>
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	a90080e7          	jalr	-1392(ra) # 80001bc6 <myproc>
    8000513e:	fdc42703          	lw	a4,-36(s0)
    80005142:	01a70793          	addi	a5,a4,26
    80005146:	078e                	slli	a5,a5,0x3
    80005148:	953e                	add	a0,a0,a5
    8000514a:	611c                	ld	a5,0(a0)
    8000514c:	c395                	beqz	a5,80005170 <argfd+0x64>
    return -1;
  if(pfd)
    8000514e:	00090463          	beqz	s2,80005156 <argfd+0x4a>
    *pfd = fd;
    80005152:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005156:	4501                	li	a0,0
  if(pf)
    80005158:	c091                	beqz	s1,8000515c <argfd+0x50>
    *pf = f;
    8000515a:	e09c                	sd	a5,0(s1)
}
    8000515c:	70a2                	ld	ra,40(sp)
    8000515e:	7402                	ld	s0,32(sp)
    80005160:	64e2                	ld	s1,24(sp)
    80005162:	6942                	ld	s2,16(sp)
    80005164:	6145                	addi	sp,sp,48
    80005166:	8082                	ret
    return -1;
    80005168:	557d                	li	a0,-1
    8000516a:	bfcd                	j	8000515c <argfd+0x50>
    return -1;
    8000516c:	557d                	li	a0,-1
    8000516e:	b7fd                	j	8000515c <argfd+0x50>
    80005170:	557d                	li	a0,-1
    80005172:	b7ed                	j	8000515c <argfd+0x50>

0000000080005174 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005174:	1101                	addi	sp,sp,-32
    80005176:	ec06                	sd	ra,24(sp)
    80005178:	e822                	sd	s0,16(sp)
    8000517a:	e426                	sd	s1,8(sp)
    8000517c:	1000                	addi	s0,sp,32
    8000517e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	a46080e7          	jalr	-1466(ra) # 80001bc6 <myproc>
    80005188:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000518a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000518e:	4501                	li	a0,0
    80005190:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005192:	6398                	ld	a4,0(a5)
    80005194:	cb19                	beqz	a4,800051aa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005196:	2505                	addiw	a0,a0,1
    80005198:	07a1                	addi	a5,a5,8
    8000519a:	fed51ce3          	bne	a0,a3,80005192 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000519e:	557d                	li	a0,-1
}
    800051a0:	60e2                	ld	ra,24(sp)
    800051a2:	6442                	ld	s0,16(sp)
    800051a4:	64a2                	ld	s1,8(sp)
    800051a6:	6105                	addi	sp,sp,32
    800051a8:	8082                	ret
      p->ofile[fd] = f;
    800051aa:	01a50793          	addi	a5,a0,26
    800051ae:	078e                	slli	a5,a5,0x3
    800051b0:	963e                	add	a2,a2,a5
    800051b2:	e204                	sd	s1,0(a2)
      return fd;
    800051b4:	b7f5                	j	800051a0 <fdalloc+0x2c>

00000000800051b6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051b6:	715d                	addi	sp,sp,-80
    800051b8:	e486                	sd	ra,72(sp)
    800051ba:	e0a2                	sd	s0,64(sp)
    800051bc:	fc26                	sd	s1,56(sp)
    800051be:	f84a                	sd	s2,48(sp)
    800051c0:	f44e                	sd	s3,40(sp)
    800051c2:	f052                	sd	s4,32(sp)
    800051c4:	ec56                	sd	s5,24(sp)
    800051c6:	0880                	addi	s0,sp,80
    800051c8:	89ae                	mv	s3,a1
    800051ca:	8ab2                	mv	s5,a2
    800051cc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051ce:	fb040593          	addi	a1,s0,-80
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	e40080e7          	jalr	-448(ra) # 80004012 <nameiparent>
    800051da:	892a                	mv	s2,a0
    800051dc:	12050f63          	beqz	a0,8000531a <create+0x164>
    return 0;

  ilock(dp);
    800051e0:	ffffe097          	auipc	ra,0xffffe
    800051e4:	660080e7          	jalr	1632(ra) # 80003840 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051e8:	4601                	li	a2,0
    800051ea:	fb040593          	addi	a1,s0,-80
    800051ee:	854a                	mv	a0,s2
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	b32080e7          	jalr	-1230(ra) # 80003d22 <dirlookup>
    800051f8:	84aa                	mv	s1,a0
    800051fa:	c921                	beqz	a0,8000524a <create+0x94>
    iunlockput(dp);
    800051fc:	854a                	mv	a0,s2
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	8a4080e7          	jalr	-1884(ra) # 80003aa2 <iunlockput>
    ilock(ip);
    80005206:	8526                	mv	a0,s1
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	638080e7          	jalr	1592(ra) # 80003840 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005210:	2981                	sext.w	s3,s3
    80005212:	4789                	li	a5,2
    80005214:	02f99463          	bne	s3,a5,8000523c <create+0x86>
    80005218:	0444d783          	lhu	a5,68(s1)
    8000521c:	37f9                	addiw	a5,a5,-2
    8000521e:	17c2                	slli	a5,a5,0x30
    80005220:	93c1                	srli	a5,a5,0x30
    80005222:	4705                	li	a4,1
    80005224:	00f76c63          	bltu	a4,a5,8000523c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005228:	8526                	mv	a0,s1
    8000522a:	60a6                	ld	ra,72(sp)
    8000522c:	6406                	ld	s0,64(sp)
    8000522e:	74e2                	ld	s1,56(sp)
    80005230:	7942                	ld	s2,48(sp)
    80005232:	79a2                	ld	s3,40(sp)
    80005234:	7a02                	ld	s4,32(sp)
    80005236:	6ae2                	ld	s5,24(sp)
    80005238:	6161                	addi	sp,sp,80
    8000523a:	8082                	ret
    iunlockput(ip);
    8000523c:	8526                	mv	a0,s1
    8000523e:	fffff097          	auipc	ra,0xfffff
    80005242:	864080e7          	jalr	-1948(ra) # 80003aa2 <iunlockput>
    return 0;
    80005246:	4481                	li	s1,0
    80005248:	b7c5                	j	80005228 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000524a:	85ce                	mv	a1,s3
    8000524c:	00092503          	lw	a0,0(s2)
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	458080e7          	jalr	1112(ra) # 800036a8 <ialloc>
    80005258:	84aa                	mv	s1,a0
    8000525a:	c529                	beqz	a0,800052a4 <create+0xee>
  ilock(ip);
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	5e4080e7          	jalr	1508(ra) # 80003840 <ilock>
  ip->major = major;
    80005264:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005268:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000526c:	4785                	li	a5,1
    8000526e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005272:	8526                	mv	a0,s1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	502080e7          	jalr	1282(ra) # 80003776 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000527c:	2981                	sext.w	s3,s3
    8000527e:	4785                	li	a5,1
    80005280:	02f98a63          	beq	s3,a5,800052b4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005284:	40d0                	lw	a2,4(s1)
    80005286:	fb040593          	addi	a1,s0,-80
    8000528a:	854a                	mv	a0,s2
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	ca6080e7          	jalr	-858(ra) # 80003f32 <dirlink>
    80005294:	06054b63          	bltz	a0,8000530a <create+0x154>
  iunlockput(dp);
    80005298:	854a                	mv	a0,s2
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	808080e7          	jalr	-2040(ra) # 80003aa2 <iunlockput>
  return ip;
    800052a2:	b759                	j	80005228 <create+0x72>
    panic("create: ialloc");
    800052a4:	00003517          	auipc	a0,0x3
    800052a8:	44450513          	addi	a0,a0,1092 # 800086e8 <syscalls+0x2b0>
    800052ac:	ffffb097          	auipc	ra,0xffffb
    800052b0:	2aa080e7          	jalr	682(ra) # 80000556 <panic>
    dp->nlink++;  // for ".."
    800052b4:	04a95783          	lhu	a5,74(s2)
    800052b8:	2785                	addiw	a5,a5,1
    800052ba:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052be:	854a                	mv	a0,s2
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	4b6080e7          	jalr	1206(ra) # 80003776 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052c8:	40d0                	lw	a2,4(s1)
    800052ca:	00003597          	auipc	a1,0x3
    800052ce:	42e58593          	addi	a1,a1,1070 # 800086f8 <syscalls+0x2c0>
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	c5e080e7          	jalr	-930(ra) # 80003f32 <dirlink>
    800052dc:	00054f63          	bltz	a0,800052fa <create+0x144>
    800052e0:	00492603          	lw	a2,4(s2)
    800052e4:	00003597          	auipc	a1,0x3
    800052e8:	e7c58593          	addi	a1,a1,-388 # 80008160 <digits+0x120>
    800052ec:	8526                	mv	a0,s1
    800052ee:	fffff097          	auipc	ra,0xfffff
    800052f2:	c44080e7          	jalr	-956(ra) # 80003f32 <dirlink>
    800052f6:	f80557e3          	bgez	a0,80005284 <create+0xce>
      panic("create dots");
    800052fa:	00003517          	auipc	a0,0x3
    800052fe:	40650513          	addi	a0,a0,1030 # 80008700 <syscalls+0x2c8>
    80005302:	ffffb097          	auipc	ra,0xffffb
    80005306:	254080e7          	jalr	596(ra) # 80000556 <panic>
    panic("create: dirlink");
    8000530a:	00003517          	auipc	a0,0x3
    8000530e:	40650513          	addi	a0,a0,1030 # 80008710 <syscalls+0x2d8>
    80005312:	ffffb097          	auipc	ra,0xffffb
    80005316:	244080e7          	jalr	580(ra) # 80000556 <panic>
    return 0;
    8000531a:	84aa                	mv	s1,a0
    8000531c:	b731                	j	80005228 <create+0x72>

000000008000531e <sys_dup>:
{
    8000531e:	7179                	addi	sp,sp,-48
    80005320:	f406                	sd	ra,40(sp)
    80005322:	f022                	sd	s0,32(sp)
    80005324:	ec26                	sd	s1,24(sp)
    80005326:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005328:	fd840613          	addi	a2,s0,-40
    8000532c:	4581                	li	a1,0
    8000532e:	4501                	li	a0,0
    80005330:	00000097          	auipc	ra,0x0
    80005334:	ddc080e7          	jalr	-548(ra) # 8000510c <argfd>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000533a:	02054363          	bltz	a0,80005360 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000533e:	fd843503          	ld	a0,-40(s0)
    80005342:	00000097          	auipc	ra,0x0
    80005346:	e32080e7          	jalr	-462(ra) # 80005174 <fdalloc>
    8000534a:	84aa                	mv	s1,a0
    return -1;
    8000534c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000534e:	00054963          	bltz	a0,80005360 <sys_dup+0x42>
  filedup(f);
    80005352:	fd843503          	ld	a0,-40(s0)
    80005356:	fffff097          	auipc	ra,0xfffff
    8000535a:	32a080e7          	jalr	810(ra) # 80004680 <filedup>
  return fd;
    8000535e:	87a6                	mv	a5,s1
}
    80005360:	853e                	mv	a0,a5
    80005362:	70a2                	ld	ra,40(sp)
    80005364:	7402                	ld	s0,32(sp)
    80005366:	64e2                	ld	s1,24(sp)
    80005368:	6145                	addi	sp,sp,48
    8000536a:	8082                	ret

000000008000536c <sys_read>:
{
    8000536c:	7179                	addi	sp,sp,-48
    8000536e:	f406                	sd	ra,40(sp)
    80005370:	f022                	sd	s0,32(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	fe840613          	addi	a2,s0,-24
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	d90080e7          	jalr	-624(ra) # 8000510c <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	04054163          	bltz	a0,800053c8 <sys_read+0x5c>
    8000538a:	fe440593          	addi	a1,s0,-28
    8000538e:	4509                	li	a0,2
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	928080e7          	jalr	-1752(ra) # 80002cb8 <argint>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539a:	02054763          	bltz	a0,800053c8 <sys_read+0x5c>
    8000539e:	fd840593          	addi	a1,s0,-40
    800053a2:	4505                	li	a0,1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	936080e7          	jalr	-1738(ra) # 80002cda <argaddr>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ae:	00054d63          	bltz	a0,800053c8 <sys_read+0x5c>
  return fileread(f, p, n);
    800053b2:	fe442603          	lw	a2,-28(s0)
    800053b6:	fd843583          	ld	a1,-40(s0)
    800053ba:	fe843503          	ld	a0,-24(s0)
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	44e080e7          	jalr	1102(ra) # 8000480c <fileread>
    800053c6:	87aa                	mv	a5,a0
}
    800053c8:	853e                	mv	a0,a5
    800053ca:	70a2                	ld	ra,40(sp)
    800053cc:	7402                	ld	s0,32(sp)
    800053ce:	6145                	addi	sp,sp,48
    800053d0:	8082                	ret

00000000800053d2 <sys_write>:
{
    800053d2:	7179                	addi	sp,sp,-48
    800053d4:	f406                	sd	ra,40(sp)
    800053d6:	f022                	sd	s0,32(sp)
    800053d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053da:	fe840613          	addi	a2,s0,-24
    800053de:	4581                	li	a1,0
    800053e0:	4501                	li	a0,0
    800053e2:	00000097          	auipc	ra,0x0
    800053e6:	d2a080e7          	jalr	-726(ra) # 8000510c <argfd>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ec:	04054163          	bltz	a0,8000542e <sys_write+0x5c>
    800053f0:	fe440593          	addi	a1,s0,-28
    800053f4:	4509                	li	a0,2
    800053f6:	ffffe097          	auipc	ra,0xffffe
    800053fa:	8c2080e7          	jalr	-1854(ra) # 80002cb8 <argint>
    return -1;
    800053fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005400:	02054763          	bltz	a0,8000542e <sys_write+0x5c>
    80005404:	fd840593          	addi	a1,s0,-40
    80005408:	4505                	li	a0,1
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	8d0080e7          	jalr	-1840(ra) # 80002cda <argaddr>
    return -1;
    80005412:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005414:	00054d63          	bltz	a0,8000542e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005418:	fe442603          	lw	a2,-28(s0)
    8000541c:	fd843583          	ld	a1,-40(s0)
    80005420:	fe843503          	ld	a0,-24(s0)
    80005424:	fffff097          	auipc	ra,0xfffff
    80005428:	4aa080e7          	jalr	1194(ra) # 800048ce <filewrite>
    8000542c:	87aa                	mv	a5,a0
}
    8000542e:	853e                	mv	a0,a5
    80005430:	70a2                	ld	ra,40(sp)
    80005432:	7402                	ld	s0,32(sp)
    80005434:	6145                	addi	sp,sp,48
    80005436:	8082                	ret

0000000080005438 <sys_close>:
{
    80005438:	1101                	addi	sp,sp,-32
    8000543a:	ec06                	sd	ra,24(sp)
    8000543c:	e822                	sd	s0,16(sp)
    8000543e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005440:	fe040613          	addi	a2,s0,-32
    80005444:	fec40593          	addi	a1,s0,-20
    80005448:	4501                	li	a0,0
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	cc2080e7          	jalr	-830(ra) # 8000510c <argfd>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005454:	02054463          	bltz	a0,8000547c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	76e080e7          	jalr	1902(ra) # 80001bc6 <myproc>
    80005460:	fec42783          	lw	a5,-20(s0)
    80005464:	07e9                	addi	a5,a5,26
    80005466:	078e                	slli	a5,a5,0x3
    80005468:	97aa                	add	a5,a5,a0
    8000546a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000546e:	fe043503          	ld	a0,-32(s0)
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	260080e7          	jalr	608(ra) # 800046d2 <fileclose>
  return 0;
    8000547a:	4781                	li	a5,0
}
    8000547c:	853e                	mv	a0,a5
    8000547e:	60e2                	ld	ra,24(sp)
    80005480:	6442                	ld	s0,16(sp)
    80005482:	6105                	addi	sp,sp,32
    80005484:	8082                	ret

0000000080005486 <sys_fstat>:
{
    80005486:	1101                	addi	sp,sp,-32
    80005488:	ec06                	sd	ra,24(sp)
    8000548a:	e822                	sd	s0,16(sp)
    8000548c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000548e:	fe840613          	addi	a2,s0,-24
    80005492:	4581                	li	a1,0
    80005494:	4501                	li	a0,0
    80005496:	00000097          	auipc	ra,0x0
    8000549a:	c76080e7          	jalr	-906(ra) # 8000510c <argfd>
    return -1;
    8000549e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054a0:	02054563          	bltz	a0,800054ca <sys_fstat+0x44>
    800054a4:	fe040593          	addi	a1,s0,-32
    800054a8:	4505                	li	a0,1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	830080e7          	jalr	-2000(ra) # 80002cda <argaddr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054b4:	00054b63          	bltz	a0,800054ca <sys_fstat+0x44>
  return filestat(f, st);
    800054b8:	fe043583          	ld	a1,-32(s0)
    800054bc:	fe843503          	ld	a0,-24(s0)
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	2da080e7          	jalr	730(ra) # 8000479a <filestat>
    800054c8:	87aa                	mv	a5,a0
}
    800054ca:	853e                	mv	a0,a5
    800054cc:	60e2                	ld	ra,24(sp)
    800054ce:	6442                	ld	s0,16(sp)
    800054d0:	6105                	addi	sp,sp,32
    800054d2:	8082                	ret

00000000800054d4 <sys_link>:
{
    800054d4:	7169                	addi	sp,sp,-304
    800054d6:	f606                	sd	ra,296(sp)
    800054d8:	f222                	sd	s0,288(sp)
    800054da:	ee26                	sd	s1,280(sp)
    800054dc:	ea4a                	sd	s2,272(sp)
    800054de:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e0:	08000613          	li	a2,128
    800054e4:	ed040593          	addi	a1,s0,-304
    800054e8:	4501                	li	a0,0
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	812080e7          	jalr	-2030(ra) # 80002cfc <argstr>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054f4:	10054e63          	bltz	a0,80005610 <sys_link+0x13c>
    800054f8:	08000613          	li	a2,128
    800054fc:	f5040593          	addi	a1,s0,-176
    80005500:	4505                	li	a0,1
    80005502:	ffffd097          	auipc	ra,0xffffd
    80005506:	7fa080e7          	jalr	2042(ra) # 80002cfc <argstr>
    return -1;
    8000550a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000550c:	10054263          	bltz	a0,80005610 <sys_link+0x13c>
  begin_op();
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	cf0080e7          	jalr	-784(ra) # 80004200 <begin_op>
  if((ip = namei(old)) == 0){
    80005518:	ed040513          	addi	a0,s0,-304
    8000551c:	fffff097          	auipc	ra,0xfffff
    80005520:	ad8080e7          	jalr	-1320(ra) # 80003ff4 <namei>
    80005524:	84aa                	mv	s1,a0
    80005526:	c551                	beqz	a0,800055b2 <sys_link+0xde>
  ilock(ip);
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	318080e7          	jalr	792(ra) # 80003840 <ilock>
  if(ip->type == T_DIR){
    80005530:	04449703          	lh	a4,68(s1)
    80005534:	4785                	li	a5,1
    80005536:	08f70463          	beq	a4,a5,800055be <sys_link+0xea>
  ip->nlink++;
    8000553a:	04a4d783          	lhu	a5,74(s1)
    8000553e:	2785                	addiw	a5,a5,1
    80005540:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	230080e7          	jalr	560(ra) # 80003776 <iupdate>
  iunlock(ip);
    8000554e:	8526                	mv	a0,s1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	3b2080e7          	jalr	946(ra) # 80003902 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005558:	fd040593          	addi	a1,s0,-48
    8000555c:	f5040513          	addi	a0,s0,-176
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	ab2080e7          	jalr	-1358(ra) # 80004012 <nameiparent>
    80005568:	892a                	mv	s2,a0
    8000556a:	c935                	beqz	a0,800055de <sys_link+0x10a>
  ilock(dp);
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	2d4080e7          	jalr	724(ra) # 80003840 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005574:	00092703          	lw	a4,0(s2)
    80005578:	409c                	lw	a5,0(s1)
    8000557a:	04f71d63          	bne	a4,a5,800055d4 <sys_link+0x100>
    8000557e:	40d0                	lw	a2,4(s1)
    80005580:	fd040593          	addi	a1,s0,-48
    80005584:	854a                	mv	a0,s2
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	9ac080e7          	jalr	-1620(ra) # 80003f32 <dirlink>
    8000558e:	04054363          	bltz	a0,800055d4 <sys_link+0x100>
  iunlockput(dp);
    80005592:	854a                	mv	a0,s2
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	50e080e7          	jalr	1294(ra) # 80003aa2 <iunlockput>
  iput(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	45c080e7          	jalr	1116(ra) # 800039fa <iput>
  end_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	cda080e7          	jalr	-806(ra) # 80004280 <end_op>
  return 0;
    800055ae:	4781                	li	a5,0
    800055b0:	a085                	j	80005610 <sys_link+0x13c>
    end_op();
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	cce080e7          	jalr	-818(ra) # 80004280 <end_op>
    return -1;
    800055ba:	57fd                	li	a5,-1
    800055bc:	a891                	j	80005610 <sys_link+0x13c>
    iunlockput(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	4e2080e7          	jalr	1250(ra) # 80003aa2 <iunlockput>
    end_op();
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	cb8080e7          	jalr	-840(ra) # 80004280 <end_op>
    return -1;
    800055d0:	57fd                	li	a5,-1
    800055d2:	a83d                	j	80005610 <sys_link+0x13c>
    iunlockput(dp);
    800055d4:	854a                	mv	a0,s2
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	4cc080e7          	jalr	1228(ra) # 80003aa2 <iunlockput>
  ilock(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	260080e7          	jalr	608(ra) # 80003840 <ilock>
  ip->nlink--;
    800055e8:	04a4d783          	lhu	a5,74(s1)
    800055ec:	37fd                	addiw	a5,a5,-1
    800055ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	182080e7          	jalr	386(ra) # 80003776 <iupdate>
  iunlockput(ip);
    800055fc:	8526                	mv	a0,s1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	4a4080e7          	jalr	1188(ra) # 80003aa2 <iunlockput>
  end_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	c7a080e7          	jalr	-902(ra) # 80004280 <end_op>
  return -1;
    8000560e:	57fd                	li	a5,-1
}
    80005610:	853e                	mv	a0,a5
    80005612:	70b2                	ld	ra,296(sp)
    80005614:	7412                	ld	s0,288(sp)
    80005616:	64f2                	ld	s1,280(sp)
    80005618:	6952                	ld	s2,272(sp)
    8000561a:	6155                	addi	sp,sp,304
    8000561c:	8082                	ret

000000008000561e <sys_unlink>:
{
    8000561e:	7151                	addi	sp,sp,-240
    80005620:	f586                	sd	ra,232(sp)
    80005622:	f1a2                	sd	s0,224(sp)
    80005624:	eda6                	sd	s1,216(sp)
    80005626:	e9ca                	sd	s2,208(sp)
    80005628:	e5ce                	sd	s3,200(sp)
    8000562a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000562c:	08000613          	li	a2,128
    80005630:	f3040593          	addi	a1,s0,-208
    80005634:	4501                	li	a0,0
    80005636:	ffffd097          	auipc	ra,0xffffd
    8000563a:	6c6080e7          	jalr	1734(ra) # 80002cfc <argstr>
    8000563e:	18054163          	bltz	a0,800057c0 <sys_unlink+0x1a2>
  begin_op();
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	bbe080e7          	jalr	-1090(ra) # 80004200 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000564a:	fb040593          	addi	a1,s0,-80
    8000564e:	f3040513          	addi	a0,s0,-208
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	9c0080e7          	jalr	-1600(ra) # 80004012 <nameiparent>
    8000565a:	84aa                	mv	s1,a0
    8000565c:	c979                	beqz	a0,80005732 <sys_unlink+0x114>
  ilock(dp);
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	1e2080e7          	jalr	482(ra) # 80003840 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005666:	00003597          	auipc	a1,0x3
    8000566a:	09258593          	addi	a1,a1,146 # 800086f8 <syscalls+0x2c0>
    8000566e:	fb040513          	addi	a0,s0,-80
    80005672:	ffffe097          	auipc	ra,0xffffe
    80005676:	696080e7          	jalr	1686(ra) # 80003d08 <namecmp>
    8000567a:	14050a63          	beqz	a0,800057ce <sys_unlink+0x1b0>
    8000567e:	00003597          	auipc	a1,0x3
    80005682:	ae258593          	addi	a1,a1,-1310 # 80008160 <digits+0x120>
    80005686:	fb040513          	addi	a0,s0,-80
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	67e080e7          	jalr	1662(ra) # 80003d08 <namecmp>
    80005692:	12050e63          	beqz	a0,800057ce <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005696:	f2c40613          	addi	a2,s0,-212
    8000569a:	fb040593          	addi	a1,s0,-80
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	682080e7          	jalr	1666(ra) # 80003d22 <dirlookup>
    800056a8:	892a                	mv	s2,a0
    800056aa:	12050263          	beqz	a0,800057ce <sys_unlink+0x1b0>
  ilock(ip);
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	192080e7          	jalr	402(ra) # 80003840 <ilock>
  if(ip->nlink < 1)
    800056b6:	04a91783          	lh	a5,74(s2)
    800056ba:	08f05263          	blez	a5,8000573e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056be:	04491703          	lh	a4,68(s2)
    800056c2:	4785                	li	a5,1
    800056c4:	08f70563          	beq	a4,a5,8000574e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056c8:	4641                	li	a2,16
    800056ca:	4581                	li	a1,0
    800056cc:	fc040513          	addi	a0,s0,-64
    800056d0:	ffffb097          	auipc	ra,0xffffb
    800056d4:	64a080e7          	jalr	1610(ra) # 80000d1a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056d8:	4741                	li	a4,16
    800056da:	f2c42683          	lw	a3,-212(s0)
    800056de:	fc040613          	addi	a2,s0,-64
    800056e2:	4581                	li	a1,0
    800056e4:	8526                	mv	a0,s1
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	506080e7          	jalr	1286(ra) # 80003bec <writei>
    800056ee:	47c1                	li	a5,16
    800056f0:	0af51563          	bne	a0,a5,8000579a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056f4:	04491703          	lh	a4,68(s2)
    800056f8:	4785                	li	a5,1
    800056fa:	0af70863          	beq	a4,a5,800057aa <sys_unlink+0x18c>
  iunlockput(dp);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	3a2080e7          	jalr	930(ra) # 80003aa2 <iunlockput>
  ip->nlink--;
    80005708:	04a95783          	lhu	a5,74(s2)
    8000570c:	37fd                	addiw	a5,a5,-1
    8000570e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005712:	854a                	mv	a0,s2
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	062080e7          	jalr	98(ra) # 80003776 <iupdate>
  iunlockput(ip);
    8000571c:	854a                	mv	a0,s2
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	384080e7          	jalr	900(ra) # 80003aa2 <iunlockput>
  end_op();
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	b5a080e7          	jalr	-1190(ra) # 80004280 <end_op>
  return 0;
    8000572e:	4501                	li	a0,0
    80005730:	a84d                	j	800057e2 <sys_unlink+0x1c4>
    end_op();
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	b4e080e7          	jalr	-1202(ra) # 80004280 <end_op>
    return -1;
    8000573a:	557d                	li	a0,-1
    8000573c:	a05d                	j	800057e2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000573e:	00003517          	auipc	a0,0x3
    80005742:	fe250513          	addi	a0,a0,-30 # 80008720 <syscalls+0x2e8>
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	e10080e7          	jalr	-496(ra) # 80000556 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000574e:	04c92703          	lw	a4,76(s2)
    80005752:	02000793          	li	a5,32
    80005756:	f6e7f9e3          	bgeu	a5,a4,800056c8 <sys_unlink+0xaa>
    8000575a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000575e:	4741                	li	a4,16
    80005760:	86ce                	mv	a3,s3
    80005762:	f1840613          	addi	a2,s0,-232
    80005766:	4581                	li	a1,0
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	38a080e7          	jalr	906(ra) # 80003af4 <readi>
    80005772:	47c1                	li	a5,16
    80005774:	00f51b63          	bne	a0,a5,8000578a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005778:	f1845783          	lhu	a5,-232(s0)
    8000577c:	e7a1                	bnez	a5,800057c4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000577e:	29c1                	addiw	s3,s3,16
    80005780:	04c92783          	lw	a5,76(s2)
    80005784:	fcf9ede3          	bltu	s3,a5,8000575e <sys_unlink+0x140>
    80005788:	b781                	j	800056c8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000578a:	00003517          	auipc	a0,0x3
    8000578e:	fae50513          	addi	a0,a0,-82 # 80008738 <syscalls+0x300>
    80005792:	ffffb097          	auipc	ra,0xffffb
    80005796:	dc4080e7          	jalr	-572(ra) # 80000556 <panic>
    panic("unlink: writei");
    8000579a:	00003517          	auipc	a0,0x3
    8000579e:	fb650513          	addi	a0,a0,-74 # 80008750 <syscalls+0x318>
    800057a2:	ffffb097          	auipc	ra,0xffffb
    800057a6:	db4080e7          	jalr	-588(ra) # 80000556 <panic>
    dp->nlink--;
    800057aa:	04a4d783          	lhu	a5,74(s1)
    800057ae:	37fd                	addiw	a5,a5,-1
    800057b0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057b4:	8526                	mv	a0,s1
    800057b6:	ffffe097          	auipc	ra,0xffffe
    800057ba:	fc0080e7          	jalr	-64(ra) # 80003776 <iupdate>
    800057be:	b781                	j	800056fe <sys_unlink+0xe0>
    return -1;
    800057c0:	557d                	li	a0,-1
    800057c2:	a005                	j	800057e2 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	2dc080e7          	jalr	732(ra) # 80003aa2 <iunlockput>
  iunlockput(dp);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	2d2080e7          	jalr	722(ra) # 80003aa2 <iunlockput>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	aa8080e7          	jalr	-1368(ra) # 80004280 <end_op>
  return -1;
    800057e0:	557d                	li	a0,-1
}
    800057e2:	70ae                	ld	ra,232(sp)
    800057e4:	740e                	ld	s0,224(sp)
    800057e6:	64ee                	ld	s1,216(sp)
    800057e8:	694e                	ld	s2,208(sp)
    800057ea:	69ae                	ld	s3,200(sp)
    800057ec:	616d                	addi	sp,sp,240
    800057ee:	8082                	ret

00000000800057f0 <sys_open>:

uint64
sys_open(void)
{
    800057f0:	7131                	addi	sp,sp,-192
    800057f2:	fd06                	sd	ra,184(sp)
    800057f4:	f922                	sd	s0,176(sp)
    800057f6:	f526                	sd	s1,168(sp)
    800057f8:	f14a                	sd	s2,160(sp)
    800057fa:	ed4e                	sd	s3,152(sp)
    800057fc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057fe:	08000613          	li	a2,128
    80005802:	f5040593          	addi	a1,s0,-176
    80005806:	4501                	li	a0,0
    80005808:	ffffd097          	auipc	ra,0xffffd
    8000580c:	4f4080e7          	jalr	1268(ra) # 80002cfc <argstr>
    return -1;
    80005810:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005812:	0c054163          	bltz	a0,800058d4 <sys_open+0xe4>
    80005816:	f4c40593          	addi	a1,s0,-180
    8000581a:	4505                	li	a0,1
    8000581c:	ffffd097          	auipc	ra,0xffffd
    80005820:	49c080e7          	jalr	1180(ra) # 80002cb8 <argint>
    80005824:	0a054863          	bltz	a0,800058d4 <sys_open+0xe4>

  begin_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	9d8080e7          	jalr	-1576(ra) # 80004200 <begin_op>

  if(omode & O_CREATE){
    80005830:	f4c42783          	lw	a5,-180(s0)
    80005834:	2007f793          	andi	a5,a5,512
    80005838:	cbdd                	beqz	a5,800058ee <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000583a:	4681                	li	a3,0
    8000583c:	4601                	li	a2,0
    8000583e:	4589                	li	a1,2
    80005840:	f5040513          	addi	a0,s0,-176
    80005844:	00000097          	auipc	ra,0x0
    80005848:	972080e7          	jalr	-1678(ra) # 800051b6 <create>
    8000584c:	892a                	mv	s2,a0
    if(ip == 0){
    8000584e:	c959                	beqz	a0,800058e4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005850:	04491703          	lh	a4,68(s2)
    80005854:	478d                	li	a5,3
    80005856:	00f71763          	bne	a4,a5,80005864 <sys_open+0x74>
    8000585a:	04695703          	lhu	a4,70(s2)
    8000585e:	47a5                	li	a5,9
    80005860:	0ce7ec63          	bltu	a5,a4,80005938 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	db2080e7          	jalr	-590(ra) # 80004616 <filealloc>
    8000586c:	89aa                	mv	s3,a0
    8000586e:	10050263          	beqz	a0,80005972 <sys_open+0x182>
    80005872:	00000097          	auipc	ra,0x0
    80005876:	902080e7          	jalr	-1790(ra) # 80005174 <fdalloc>
    8000587a:	84aa                	mv	s1,a0
    8000587c:	0e054663          	bltz	a0,80005968 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005880:	04491703          	lh	a4,68(s2)
    80005884:	478d                	li	a5,3
    80005886:	0cf70463          	beq	a4,a5,8000594e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000588a:	4789                	li	a5,2
    8000588c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005890:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005894:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005898:	f4c42783          	lw	a5,-180(s0)
    8000589c:	0017c713          	xori	a4,a5,1
    800058a0:	8b05                	andi	a4,a4,1
    800058a2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058a6:	0037f713          	andi	a4,a5,3
    800058aa:	00e03733          	snez	a4,a4
    800058ae:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058b2:	4007f793          	andi	a5,a5,1024
    800058b6:	c791                	beqz	a5,800058c2 <sys_open+0xd2>
    800058b8:	04491703          	lh	a4,68(s2)
    800058bc:	4789                	li	a5,2
    800058be:	08f70f63          	beq	a4,a5,8000595c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058c2:	854a                	mv	a0,s2
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	03e080e7          	jalr	62(ra) # 80003902 <iunlock>
  end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	9b4080e7          	jalr	-1612(ra) # 80004280 <end_op>

  return fd;
}
    800058d4:	8526                	mv	a0,s1
    800058d6:	70ea                	ld	ra,184(sp)
    800058d8:	744a                	ld	s0,176(sp)
    800058da:	74aa                	ld	s1,168(sp)
    800058dc:	790a                	ld	s2,160(sp)
    800058de:	69ea                	ld	s3,152(sp)
    800058e0:	6129                	addi	sp,sp,192
    800058e2:	8082                	ret
      end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	99c080e7          	jalr	-1636(ra) # 80004280 <end_op>
      return -1;
    800058ec:	b7e5                	j	800058d4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058ee:	f5040513          	addi	a0,s0,-176
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	702080e7          	jalr	1794(ra) # 80003ff4 <namei>
    800058fa:	892a                	mv	s2,a0
    800058fc:	c905                	beqz	a0,8000592c <sys_open+0x13c>
    ilock(ip);
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	f42080e7          	jalr	-190(ra) # 80003840 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005906:	04491703          	lh	a4,68(s2)
    8000590a:	4785                	li	a5,1
    8000590c:	f4f712e3          	bne	a4,a5,80005850 <sys_open+0x60>
    80005910:	f4c42783          	lw	a5,-180(s0)
    80005914:	dba1                	beqz	a5,80005864 <sys_open+0x74>
      iunlockput(ip);
    80005916:	854a                	mv	a0,s2
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	18a080e7          	jalr	394(ra) # 80003aa2 <iunlockput>
      end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	960080e7          	jalr	-1696(ra) # 80004280 <end_op>
      return -1;
    80005928:	54fd                	li	s1,-1
    8000592a:	b76d                	j	800058d4 <sys_open+0xe4>
      end_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	954080e7          	jalr	-1708(ra) # 80004280 <end_op>
      return -1;
    80005934:	54fd                	li	s1,-1
    80005936:	bf79                	j	800058d4 <sys_open+0xe4>
    iunlockput(ip);
    80005938:	854a                	mv	a0,s2
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	168080e7          	jalr	360(ra) # 80003aa2 <iunlockput>
    end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	93e080e7          	jalr	-1730(ra) # 80004280 <end_op>
    return -1;
    8000594a:	54fd                	li	s1,-1
    8000594c:	b761                	j	800058d4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000594e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005952:	04691783          	lh	a5,70(s2)
    80005956:	02f99223          	sh	a5,36(s3)
    8000595a:	bf2d                	j	80005894 <sys_open+0xa4>
    itrunc(ip);
    8000595c:	854a                	mv	a0,s2
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	ff0080e7          	jalr	-16(ra) # 8000394e <itrunc>
    80005966:	bfb1                	j	800058c2 <sys_open+0xd2>
      fileclose(f);
    80005968:	854e                	mv	a0,s3
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	d68080e7          	jalr	-664(ra) # 800046d2 <fileclose>
    iunlockput(ip);
    80005972:	854a                	mv	a0,s2
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	12e080e7          	jalr	302(ra) # 80003aa2 <iunlockput>
    end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	904080e7          	jalr	-1788(ra) # 80004280 <end_op>
    return -1;
    80005984:	54fd                	li	s1,-1
    80005986:	b7b9                	j	800058d4 <sys_open+0xe4>

0000000080005988 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005988:	7175                	addi	sp,sp,-144
    8000598a:	e506                	sd	ra,136(sp)
    8000598c:	e122                	sd	s0,128(sp)
    8000598e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	870080e7          	jalr	-1936(ra) # 80004200 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005998:	08000613          	li	a2,128
    8000599c:	f7040593          	addi	a1,s0,-144
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	35a080e7          	jalr	858(ra) # 80002cfc <argstr>
    800059aa:	02054963          	bltz	a0,800059dc <sys_mkdir+0x54>
    800059ae:	4681                	li	a3,0
    800059b0:	4601                	li	a2,0
    800059b2:	4585                	li	a1,1
    800059b4:	f7040513          	addi	a0,s0,-144
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	7fe080e7          	jalr	2046(ra) # 800051b6 <create>
    800059c0:	cd11                	beqz	a0,800059dc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	0e0080e7          	jalr	224(ra) # 80003aa2 <iunlockput>
  end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	8b6080e7          	jalr	-1866(ra) # 80004280 <end_op>
  return 0;
    800059d2:	4501                	li	a0,0
}
    800059d4:	60aa                	ld	ra,136(sp)
    800059d6:	640a                	ld	s0,128(sp)
    800059d8:	6149                	addi	sp,sp,144
    800059da:	8082                	ret
    end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	8a4080e7          	jalr	-1884(ra) # 80004280 <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7fd                	j	800059d4 <sys_mkdir+0x4c>

00000000800059e8 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059e8:	7135                	addi	sp,sp,-160
    800059ea:	ed06                	sd	ra,152(sp)
    800059ec:	e922                	sd	s0,144(sp)
    800059ee:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	810080e7          	jalr	-2032(ra) # 80004200 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059f8:	08000613          	li	a2,128
    800059fc:	f7040593          	addi	a1,s0,-144
    80005a00:	4501                	li	a0,0
    80005a02:	ffffd097          	auipc	ra,0xffffd
    80005a06:	2fa080e7          	jalr	762(ra) # 80002cfc <argstr>
    80005a0a:	04054a63          	bltz	a0,80005a5e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a0e:	f6c40593          	addi	a1,s0,-148
    80005a12:	4505                	li	a0,1
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	2a4080e7          	jalr	676(ra) # 80002cb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a1c:	04054163          	bltz	a0,80005a5e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a20:	f6840593          	addi	a1,s0,-152
    80005a24:	4509                	li	a0,2
    80005a26:	ffffd097          	auipc	ra,0xffffd
    80005a2a:	292080e7          	jalr	658(ra) # 80002cb8 <argint>
     argint(1, &major) < 0 ||
    80005a2e:	02054863          	bltz	a0,80005a5e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a32:	f6841683          	lh	a3,-152(s0)
    80005a36:	f6c41603          	lh	a2,-148(s0)
    80005a3a:	458d                	li	a1,3
    80005a3c:	f7040513          	addi	a0,s0,-144
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	776080e7          	jalr	1910(ra) # 800051b6 <create>
     argint(2, &minor) < 0 ||
    80005a48:	c919                	beqz	a0,80005a5e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	058080e7          	jalr	88(ra) # 80003aa2 <iunlockput>
  end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	82e080e7          	jalr	-2002(ra) # 80004280 <end_op>
  return 0;
    80005a5a:	4501                	li	a0,0
    80005a5c:	a031                	j	80005a68 <sys_mknod+0x80>
    end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	822080e7          	jalr	-2014(ra) # 80004280 <end_op>
    return -1;
    80005a66:	557d                	li	a0,-1
}
    80005a68:	60ea                	ld	ra,152(sp)
    80005a6a:	644a                	ld	s0,144(sp)
    80005a6c:	610d                	addi	sp,sp,160
    80005a6e:	8082                	ret

0000000080005a70 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a70:	7135                	addi	sp,sp,-160
    80005a72:	ed06                	sd	ra,152(sp)
    80005a74:	e922                	sd	s0,144(sp)
    80005a76:	e526                	sd	s1,136(sp)
    80005a78:	e14a                	sd	s2,128(sp)
    80005a7a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a7c:	ffffc097          	auipc	ra,0xffffc
    80005a80:	14a080e7          	jalr	330(ra) # 80001bc6 <myproc>
    80005a84:	892a                	mv	s2,a0
  
  begin_op();
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	77a080e7          	jalr	1914(ra) # 80004200 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a8e:	08000613          	li	a2,128
    80005a92:	f6040593          	addi	a1,s0,-160
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	264080e7          	jalr	612(ra) # 80002cfc <argstr>
    80005aa0:	04054b63          	bltz	a0,80005af6 <sys_chdir+0x86>
    80005aa4:	f6040513          	addi	a0,s0,-160
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	54c080e7          	jalr	1356(ra) # 80003ff4 <namei>
    80005ab0:	84aa                	mv	s1,a0
    80005ab2:	c131                	beqz	a0,80005af6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	d8c080e7          	jalr	-628(ra) # 80003840 <ilock>
  if(ip->type != T_DIR){
    80005abc:	04449703          	lh	a4,68(s1)
    80005ac0:	4785                	li	a5,1
    80005ac2:	04f71063          	bne	a4,a5,80005b02 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	e3a080e7          	jalr	-454(ra) # 80003902 <iunlock>
  iput(p->cwd);
    80005ad0:	15093503          	ld	a0,336(s2)
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	f26080e7          	jalr	-218(ra) # 800039fa <iput>
  end_op();
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	7a4080e7          	jalr	1956(ra) # 80004280 <end_op>
  p->cwd = ip;
    80005ae4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ae8:	4501                	li	a0,0
}
    80005aea:	60ea                	ld	ra,152(sp)
    80005aec:	644a                	ld	s0,144(sp)
    80005aee:	64aa                	ld	s1,136(sp)
    80005af0:	690a                	ld	s2,128(sp)
    80005af2:	610d                	addi	sp,sp,160
    80005af4:	8082                	ret
    end_op();
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	78a080e7          	jalr	1930(ra) # 80004280 <end_op>
    return -1;
    80005afe:	557d                	li	a0,-1
    80005b00:	b7ed                	j	80005aea <sys_chdir+0x7a>
    iunlockput(ip);
    80005b02:	8526                	mv	a0,s1
    80005b04:	ffffe097          	auipc	ra,0xffffe
    80005b08:	f9e080e7          	jalr	-98(ra) # 80003aa2 <iunlockput>
    end_op();
    80005b0c:	ffffe097          	auipc	ra,0xffffe
    80005b10:	774080e7          	jalr	1908(ra) # 80004280 <end_op>
    return -1;
    80005b14:	557d                	li	a0,-1
    80005b16:	bfd1                	j	80005aea <sys_chdir+0x7a>

0000000080005b18 <sys_exec>:

uint64
sys_exec(void)
{
    80005b18:	7145                	addi	sp,sp,-464
    80005b1a:	e786                	sd	ra,456(sp)
    80005b1c:	e3a2                	sd	s0,448(sp)
    80005b1e:	ff26                	sd	s1,440(sp)
    80005b20:	fb4a                	sd	s2,432(sp)
    80005b22:	f74e                	sd	s3,424(sp)
    80005b24:	f352                	sd	s4,416(sp)
    80005b26:	ef56                	sd	s5,408(sp)
    80005b28:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b2a:	08000613          	li	a2,128
    80005b2e:	f4040593          	addi	a1,s0,-192
    80005b32:	4501                	li	a0,0
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	1c8080e7          	jalr	456(ra) # 80002cfc <argstr>
    return -1;
    80005b3c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b3e:	0c054a63          	bltz	a0,80005c12 <sys_exec+0xfa>
    80005b42:	e3840593          	addi	a1,s0,-456
    80005b46:	4505                	li	a0,1
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	192080e7          	jalr	402(ra) # 80002cda <argaddr>
    80005b50:	0c054163          	bltz	a0,80005c12 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b54:	10000613          	li	a2,256
    80005b58:	4581                	li	a1,0
    80005b5a:	e4040513          	addi	a0,s0,-448
    80005b5e:	ffffb097          	auipc	ra,0xffffb
    80005b62:	1bc080e7          	jalr	444(ra) # 80000d1a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b66:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b6a:	89a6                	mv	s3,s1
    80005b6c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b6e:	02000a13          	li	s4,32
    80005b72:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b76:	00391513          	slli	a0,s2,0x3
    80005b7a:	e3040593          	addi	a1,s0,-464
    80005b7e:	e3843783          	ld	a5,-456(s0)
    80005b82:	953e                	add	a0,a0,a5
    80005b84:	ffffd097          	auipc	ra,0xffffd
    80005b88:	09a080e7          	jalr	154(ra) # 80002c1e <fetchaddr>
    80005b8c:	02054a63          	bltz	a0,80005bc0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b90:	e3043783          	ld	a5,-464(s0)
    80005b94:	c3b9                	beqz	a5,80005bda <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b96:	ffffb097          	auipc	ra,0xffffb
    80005b9a:	f98080e7          	jalr	-104(ra) # 80000b2e <kalloc>
    80005b9e:	85aa                	mv	a1,a0
    80005ba0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ba4:	cd11                	beqz	a0,80005bc0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ba6:	6605                	lui	a2,0x1
    80005ba8:	e3043503          	ld	a0,-464(s0)
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	0c4080e7          	jalr	196(ra) # 80002c70 <fetchstr>
    80005bb4:	00054663          	bltz	a0,80005bc0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005bb8:	0905                	addi	s2,s2,1
    80005bba:	09a1                	addi	s3,s3,8
    80005bbc:	fb491be3          	bne	s2,s4,80005b72 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bc0:	10048913          	addi	s2,s1,256
    80005bc4:	6088                	ld	a0,0(s1)
    80005bc6:	c529                	beqz	a0,80005c10 <sys_exec+0xf8>
    kfree(argv[i]);
    80005bc8:	ffffb097          	auipc	ra,0xffffb
    80005bcc:	e6a080e7          	jalr	-406(ra) # 80000a32 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd0:	04a1                	addi	s1,s1,8
    80005bd2:	ff2499e3          	bne	s1,s2,80005bc4 <sys_exec+0xac>
  return -1;
    80005bd6:	597d                	li	s2,-1
    80005bd8:	a82d                	j	80005c12 <sys_exec+0xfa>
      argv[i] = 0;
    80005bda:	0a8e                	slli	s5,s5,0x3
    80005bdc:	fc040793          	addi	a5,s0,-64
    80005be0:	9abe                	add	s5,s5,a5
    80005be2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005be6:	e4040593          	addi	a1,s0,-448
    80005bea:	f4040513          	addi	a0,s0,-192
    80005bee:	fffff097          	auipc	ra,0xfffff
    80005bf2:	194080e7          	jalr	404(ra) # 80004d82 <exec>
    80005bf6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf8:	10048993          	addi	s3,s1,256
    80005bfc:	6088                	ld	a0,0(s1)
    80005bfe:	c911                	beqz	a0,80005c12 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c00:	ffffb097          	auipc	ra,0xffffb
    80005c04:	e32080e7          	jalr	-462(ra) # 80000a32 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c08:	04a1                	addi	s1,s1,8
    80005c0a:	ff3499e3          	bne	s1,s3,80005bfc <sys_exec+0xe4>
    80005c0e:	a011                	j	80005c12 <sys_exec+0xfa>
  return -1;
    80005c10:	597d                	li	s2,-1
}
    80005c12:	854a                	mv	a0,s2
    80005c14:	60be                	ld	ra,456(sp)
    80005c16:	641e                	ld	s0,448(sp)
    80005c18:	74fa                	ld	s1,440(sp)
    80005c1a:	795a                	ld	s2,432(sp)
    80005c1c:	79ba                	ld	s3,424(sp)
    80005c1e:	7a1a                	ld	s4,416(sp)
    80005c20:	6afa                	ld	s5,408(sp)
    80005c22:	6179                	addi	sp,sp,464
    80005c24:	8082                	ret

0000000080005c26 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c26:	7139                	addi	sp,sp,-64
    80005c28:	fc06                	sd	ra,56(sp)
    80005c2a:	f822                	sd	s0,48(sp)
    80005c2c:	f426                	sd	s1,40(sp)
    80005c2e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	f96080e7          	jalr	-106(ra) # 80001bc6 <myproc>
    80005c38:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c3a:	fd840593          	addi	a1,s0,-40
    80005c3e:	4501                	li	a0,0
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	09a080e7          	jalr	154(ra) # 80002cda <argaddr>
    return -1;
    80005c48:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c4a:	0e054063          	bltz	a0,80005d2a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c4e:	fc840593          	addi	a1,s0,-56
    80005c52:	fd040513          	addi	a0,s0,-48
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	dd2080e7          	jalr	-558(ra) # 80004a28 <pipealloc>
    return -1;
    80005c5e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c60:	0c054563          	bltz	a0,80005d2a <sys_pipe+0x104>
  fd0 = -1;
    80005c64:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c68:	fd043503          	ld	a0,-48(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	508080e7          	jalr	1288(ra) # 80005174 <fdalloc>
    80005c74:	fca42223          	sw	a0,-60(s0)
    80005c78:	08054c63          	bltz	a0,80005d10 <sys_pipe+0xea>
    80005c7c:	fc843503          	ld	a0,-56(s0)
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	4f4080e7          	jalr	1268(ra) # 80005174 <fdalloc>
    80005c88:	fca42023          	sw	a0,-64(s0)
    80005c8c:	06054863          	bltz	a0,80005cfc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c90:	4691                	li	a3,4
    80005c92:	fc440613          	addi	a2,s0,-60
    80005c96:	fd843583          	ld	a1,-40(s0)
    80005c9a:	68a8                	ld	a0,80(s1)
    80005c9c:	ffffc097          	auipc	ra,0xffffc
    80005ca0:	c9e080e7          	jalr	-866(ra) # 8000193a <copyout>
    80005ca4:	02054063          	bltz	a0,80005cc4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ca8:	4691                	li	a3,4
    80005caa:	fc040613          	addi	a2,s0,-64
    80005cae:	fd843583          	ld	a1,-40(s0)
    80005cb2:	0591                	addi	a1,a1,4
    80005cb4:	68a8                	ld	a0,80(s1)
    80005cb6:	ffffc097          	auipc	ra,0xffffc
    80005cba:	c84080e7          	jalr	-892(ra) # 8000193a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cbe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cc0:	06055563          	bgez	a0,80005d2a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005cc4:	fc442783          	lw	a5,-60(s0)
    80005cc8:	07e9                	addi	a5,a5,26
    80005cca:	078e                	slli	a5,a5,0x3
    80005ccc:	97a6                	add	a5,a5,s1
    80005cce:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cd2:	fc042503          	lw	a0,-64(s0)
    80005cd6:	0569                	addi	a0,a0,26
    80005cd8:	050e                	slli	a0,a0,0x3
    80005cda:	9526                	add	a0,a0,s1
    80005cdc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005ce0:	fd043503          	ld	a0,-48(s0)
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	9ee080e7          	jalr	-1554(ra) # 800046d2 <fileclose>
    fileclose(wf);
    80005cec:	fc843503          	ld	a0,-56(s0)
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	9e2080e7          	jalr	-1566(ra) # 800046d2 <fileclose>
    return -1;
    80005cf8:	57fd                	li	a5,-1
    80005cfa:	a805                	j	80005d2a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cfc:	fc442783          	lw	a5,-60(s0)
    80005d00:	0007c863          	bltz	a5,80005d10 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d04:	01a78513          	addi	a0,a5,26
    80005d08:	050e                	slli	a0,a0,0x3
    80005d0a:	9526                	add	a0,a0,s1
    80005d0c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d10:	fd043503          	ld	a0,-48(s0)
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	9be080e7          	jalr	-1602(ra) # 800046d2 <fileclose>
    fileclose(wf);
    80005d1c:	fc843503          	ld	a0,-56(s0)
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	9b2080e7          	jalr	-1614(ra) # 800046d2 <fileclose>
    return -1;
    80005d28:	57fd                	li	a5,-1
}
    80005d2a:	853e                	mv	a0,a5
    80005d2c:	70e2                	ld	ra,56(sp)
    80005d2e:	7442                	ld	s0,48(sp)
    80005d30:	74a2                	ld	s1,40(sp)
    80005d32:	6121                	addi	sp,sp,64
    80005d34:	8082                	ret
	...

0000000080005d40 <kernelvec>:
    80005d40:	7111                	addi	sp,sp,-256
    80005d42:	e006                	sd	ra,0(sp)
    80005d44:	e40a                	sd	sp,8(sp)
    80005d46:	e80e                	sd	gp,16(sp)
    80005d48:	ec12                	sd	tp,24(sp)
    80005d4a:	f016                	sd	t0,32(sp)
    80005d4c:	f41a                	sd	t1,40(sp)
    80005d4e:	f81e                	sd	t2,48(sp)
    80005d50:	fc22                	sd	s0,56(sp)
    80005d52:	e0a6                	sd	s1,64(sp)
    80005d54:	e4aa                	sd	a0,72(sp)
    80005d56:	e8ae                	sd	a1,80(sp)
    80005d58:	ecb2                	sd	a2,88(sp)
    80005d5a:	f0b6                	sd	a3,96(sp)
    80005d5c:	f4ba                	sd	a4,104(sp)
    80005d5e:	f8be                	sd	a5,112(sp)
    80005d60:	fcc2                	sd	a6,120(sp)
    80005d62:	e146                	sd	a7,128(sp)
    80005d64:	e54a                	sd	s2,136(sp)
    80005d66:	e94e                	sd	s3,144(sp)
    80005d68:	ed52                	sd	s4,152(sp)
    80005d6a:	f156                	sd	s5,160(sp)
    80005d6c:	f55a                	sd	s6,168(sp)
    80005d6e:	f95e                	sd	s7,176(sp)
    80005d70:	fd62                	sd	s8,184(sp)
    80005d72:	e1e6                	sd	s9,192(sp)
    80005d74:	e5ea                	sd	s10,200(sp)
    80005d76:	e9ee                	sd	s11,208(sp)
    80005d78:	edf2                	sd	t3,216(sp)
    80005d7a:	f1f6                	sd	t4,224(sp)
    80005d7c:	f5fa                	sd	t5,232(sp)
    80005d7e:	f9fe                	sd	t6,240(sp)
    80005d80:	d6bfc0ef          	jal	ra,80002aea <kerneltrap>
    80005d84:	6082                	ld	ra,0(sp)
    80005d86:	6122                	ld	sp,8(sp)
    80005d88:	61c2                	ld	gp,16(sp)
    80005d8a:	7282                	ld	t0,32(sp)
    80005d8c:	7322                	ld	t1,40(sp)
    80005d8e:	73c2                	ld	t2,48(sp)
    80005d90:	7462                	ld	s0,56(sp)
    80005d92:	6486                	ld	s1,64(sp)
    80005d94:	6526                	ld	a0,72(sp)
    80005d96:	65c6                	ld	a1,80(sp)
    80005d98:	6666                	ld	a2,88(sp)
    80005d9a:	7686                	ld	a3,96(sp)
    80005d9c:	7726                	ld	a4,104(sp)
    80005d9e:	77c6                	ld	a5,112(sp)
    80005da0:	7866                	ld	a6,120(sp)
    80005da2:	688a                	ld	a7,128(sp)
    80005da4:	692a                	ld	s2,136(sp)
    80005da6:	69ca                	ld	s3,144(sp)
    80005da8:	6a6a                	ld	s4,152(sp)
    80005daa:	7a8a                	ld	s5,160(sp)
    80005dac:	7b2a                	ld	s6,168(sp)
    80005dae:	7bca                	ld	s7,176(sp)
    80005db0:	7c6a                	ld	s8,184(sp)
    80005db2:	6c8e                	ld	s9,192(sp)
    80005db4:	6d2e                	ld	s10,200(sp)
    80005db6:	6dce                	ld	s11,208(sp)
    80005db8:	6e6e                	ld	t3,216(sp)
    80005dba:	7e8e                	ld	t4,224(sp)
    80005dbc:	7f2e                	ld	t5,232(sp)
    80005dbe:	7fce                	ld	t6,240(sp)
    80005dc0:	6111                	addi	sp,sp,256
    80005dc2:	10200073          	sret

0000000080005dc6 <unexpected_exc>:
    80005dc6:	a001                	j	80005dc6 <unexpected_exc>

0000000080005dc8 <unexpected_int>:
    80005dc8:	a001                	j	80005dc8 <unexpected_int>
    80005dca:	00000013          	nop
    80005dce:	0001                	nop

0000000080005dd0 <timervec>:
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	e10c                	sd	a1,0(a0)
    80005dd6:	e510                	sd	a2,8(a0)
    80005dd8:	e914                	sd	a3,16(a0)
    80005dda:	342025f3          	csrr	a1,mcause
    80005dde:	fe05d4e3          	bgez	a1,80005dc6 <unexpected_exc>
    80005de2:	fff0061b          	addiw	a2,zero,-1
    80005de6:	167e                	slli	a2,a2,0x3f
    80005de8:	061d                	addi	a2,a2,7
    80005dea:	fcc59fe3          	bne	a1,a2,80005dc8 <unexpected_int>
    80005dee:	710c                	ld	a1,32(a0)
    80005df0:	7510                	ld	a2,40(a0)
    80005df2:	6194                	ld	a3,0(a1)
    80005df4:	96b2                	add	a3,a3,a2
    80005df6:	e194                	sd	a3,0(a1)
    80005df8:	4589                	li	a1,2
    80005dfa:	14459073          	csrw	sip,a1
    80005dfe:	6914                	ld	a3,16(a0)
    80005e00:	6510                	ld	a2,8(a0)
    80005e02:	610c                	ld	a1,0(a0)
    80005e04:	34051573          	csrrw	a0,mscratch,a0
    80005e08:	30200073          	mret
	...

0000000080005e16 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e422                	sd	s0,8(sp)
    80005e1a:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e1c:	0c0007b7          	lui	a5,0xc000
    80005e20:	4705                	li	a4,1
    80005e22:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e24:	c3d8                	sw	a4,4(a5)
}
    80005e26:	6422                	ld	s0,8(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plicinithart>:

void
plicinithart(void)
{
    80005e2c:	1141                	addi	sp,sp,-16
    80005e2e:	e406                	sd	ra,8(sp)
    80005e30:	e022                	sd	s0,0(sp)
    80005e32:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e34:	ffffc097          	auipc	ra,0xffffc
    80005e38:	d66080e7          	jalr	-666(ra) # 80001b9a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e3c:	0085171b          	slliw	a4,a0,0x8
    80005e40:	0c0027b7          	lui	a5,0xc002
    80005e44:	97ba                	add	a5,a5,a4
    80005e46:	40200713          	li	a4,1026
    80005e4a:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e4e:	00d5151b          	slliw	a0,a0,0xd
    80005e52:	0c2017b7          	lui	a5,0xc201
    80005e56:	953e                	add	a0,a0,a5
    80005e58:	00052023          	sw	zero,0(a0)
}
    80005e5c:	60a2                	ld	ra,8(sp)
    80005e5e:	6402                	ld	s0,0(sp)
    80005e60:	0141                	addi	sp,sp,16
    80005e62:	8082                	ret

0000000080005e64 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e64:	1141                	addi	sp,sp,-16
    80005e66:	e406                	sd	ra,8(sp)
    80005e68:	e022                	sd	s0,0(sp)
    80005e6a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e6c:	ffffc097          	auipc	ra,0xffffc
    80005e70:	d2e080e7          	jalr	-722(ra) # 80001b9a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e74:	00d5179b          	slliw	a5,a0,0xd
    80005e78:	0c201537          	lui	a0,0xc201
    80005e7c:	953e                	add	a0,a0,a5
  return irq;
}
    80005e7e:	4148                	lw	a0,4(a0)
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e88:	1101                	addi	sp,sp,-32
    80005e8a:	ec06                	sd	ra,24(sp)
    80005e8c:	e822                	sd	s0,16(sp)
    80005e8e:	e426                	sd	s1,8(sp)
    80005e90:	1000                	addi	s0,sp,32
    80005e92:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e94:	ffffc097          	auipc	ra,0xffffc
    80005e98:	d06080e7          	jalr	-762(ra) # 80001b9a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e9c:	00d5151b          	slliw	a0,a0,0xd
    80005ea0:	0c2017b7          	lui	a5,0xc201
    80005ea4:	97aa                	add	a5,a5,a0
    80005ea6:	c3c4                	sw	s1,4(a5)
}
    80005ea8:	60e2                	ld	ra,24(sp)
    80005eaa:	6442                	ld	s0,16(sp)
    80005eac:	64a2                	ld	s1,8(sp)
    80005eae:	6105                	addi	sp,sp,32
    80005eb0:	8082                	ret

0000000080005eb2 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005eb2:	1141                	addi	sp,sp,-16
    80005eb4:	e406                	sd	ra,8(sp)
    80005eb6:	e022                	sd	s0,0(sp)
    80005eb8:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eba:	479d                	li	a5,7
    80005ebc:	04a7cc63          	blt	a5,a0,80005f14 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005ec0:	0001d797          	auipc	a5,0x1d
    80005ec4:	14078793          	addi	a5,a5,320 # 80023000 <disk>
    80005ec8:	00a78733          	add	a4,a5,a0
    80005ecc:	6789                	lui	a5,0x2
    80005ece:	97ba                	add	a5,a5,a4
    80005ed0:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ed4:	eba1                	bnez	a5,80005f24 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005ed6:	00451713          	slli	a4,a0,0x4
    80005eda:	0001f797          	auipc	a5,0x1f
    80005ede:	1267b783          	ld	a5,294(a5) # 80025000 <disk+0x2000>
    80005ee2:	97ba                	add	a5,a5,a4
    80005ee4:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ee8:	0001d797          	auipc	a5,0x1d
    80005eec:	11878793          	addi	a5,a5,280 # 80023000 <disk>
    80005ef0:	97aa                	add	a5,a5,a0
    80005ef2:	6509                	lui	a0,0x2
    80005ef4:	953e                	add	a0,a0,a5
    80005ef6:	4785                	li	a5,1
    80005ef8:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005efc:	0001f517          	auipc	a0,0x1f
    80005f00:	11c50513          	addi	a0,a0,284 # 80025018 <disk+0x2018>
    80005f04:	ffffc097          	auipc	ra,0xffffc
    80005f08:	658080e7          	jalr	1624(ra) # 8000255c <wakeup>
}
    80005f0c:	60a2                	ld	ra,8(sp)
    80005f0e:	6402                	ld	s0,0(sp)
    80005f10:	0141                	addi	sp,sp,16
    80005f12:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f14:	00003517          	auipc	a0,0x3
    80005f18:	84c50513          	addi	a0,a0,-1972 # 80008760 <syscalls+0x328>
    80005f1c:	ffffa097          	auipc	ra,0xffffa
    80005f20:	63a080e7          	jalr	1594(ra) # 80000556 <panic>
    panic("virtio_disk_intr 2");
    80005f24:	00003517          	auipc	a0,0x3
    80005f28:	85450513          	addi	a0,a0,-1964 # 80008778 <syscalls+0x340>
    80005f2c:	ffffa097          	auipc	ra,0xffffa
    80005f30:	62a080e7          	jalr	1578(ra) # 80000556 <panic>

0000000080005f34 <virtio_disk_init>:
{
    80005f34:	1101                	addi	sp,sp,-32
    80005f36:	ec06                	sd	ra,24(sp)
    80005f38:	e822                	sd	s0,16(sp)
    80005f3a:	e426                	sd	s1,8(sp)
    80005f3c:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f3e:	00003597          	auipc	a1,0x3
    80005f42:	85258593          	addi	a1,a1,-1966 # 80008790 <syscalls+0x358>
    80005f46:	0001f517          	auipc	a0,0x1f
    80005f4a:	16250513          	addi	a0,a0,354 # 800250a8 <disk+0x20a8>
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	c40080e7          	jalr	-960(ra) # 80000b8e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f56:	100017b7          	lui	a5,0x10001
    80005f5a:	4398                	lw	a4,0(a5)
    80005f5c:	2701                	sext.w	a4,a4
    80005f5e:	747277b7          	lui	a5,0x74727
    80005f62:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f66:	0ef71163          	bne	a4,a5,80006048 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f6a:	100017b7          	lui	a5,0x10001
    80005f6e:	43dc                	lw	a5,4(a5)
    80005f70:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f72:	4705                	li	a4,1
    80005f74:	0ce79a63          	bne	a5,a4,80006048 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f78:	100017b7          	lui	a5,0x10001
    80005f7c:	479c                	lw	a5,8(a5)
    80005f7e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f80:	4709                	li	a4,2
    80005f82:	0ce79363          	bne	a5,a4,80006048 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f86:	100017b7          	lui	a5,0x10001
    80005f8a:	47d8                	lw	a4,12(a5)
    80005f8c:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f8e:	554d47b7          	lui	a5,0x554d4
    80005f92:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f96:	0af71963          	bne	a4,a5,80006048 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f9a:	100017b7          	lui	a5,0x10001
    80005f9e:	4705                	li	a4,1
    80005fa0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa2:	470d                	li	a4,3
    80005fa4:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fa6:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fa8:	c7ffe737          	lui	a4,0xc7ffe
    80005fac:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005fb0:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fb2:	2701                	sext.w	a4,a4
    80005fb4:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb6:	472d                	li	a4,11
    80005fb8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fba:	473d                	li	a4,15
    80005fbc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fbe:	6705                	lui	a4,0x1
    80005fc0:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fc2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fc6:	5bdc                	lw	a5,52(a5)
    80005fc8:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fca:	c7d9                	beqz	a5,80006058 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fcc:	471d                	li	a4,7
    80005fce:	08f77d63          	bgeu	a4,a5,80006068 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fd2:	100014b7          	lui	s1,0x10001
    80005fd6:	47a1                	li	a5,8
    80005fd8:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fda:	6609                	lui	a2,0x2
    80005fdc:	4581                	li	a1,0
    80005fde:	0001d517          	auipc	a0,0x1d
    80005fe2:	02250513          	addi	a0,a0,34 # 80023000 <disk>
    80005fe6:	ffffb097          	auipc	ra,0xffffb
    80005fea:	d34080e7          	jalr	-716(ra) # 80000d1a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fee:	0001d717          	auipc	a4,0x1d
    80005ff2:	01270713          	addi	a4,a4,18 # 80023000 <disk>
    80005ff6:	00c75793          	srli	a5,a4,0xc
    80005ffa:	2781                	sext.w	a5,a5
    80005ffc:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ffe:	0001f797          	auipc	a5,0x1f
    80006002:	00278793          	addi	a5,a5,2 # 80025000 <disk+0x2000>
    80006006:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80006008:	0001d717          	auipc	a4,0x1d
    8000600c:	07870713          	addi	a4,a4,120 # 80023080 <disk+0x80>
    80006010:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006012:	0001e717          	auipc	a4,0x1e
    80006016:	fee70713          	addi	a4,a4,-18 # 80024000 <disk+0x1000>
    8000601a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000601c:	4705                	li	a4,1
    8000601e:	00e78c23          	sb	a4,24(a5)
    80006022:	00e78ca3          	sb	a4,25(a5)
    80006026:	00e78d23          	sb	a4,26(a5)
    8000602a:	00e78da3          	sb	a4,27(a5)
    8000602e:	00e78e23          	sb	a4,28(a5)
    80006032:	00e78ea3          	sb	a4,29(a5)
    80006036:	00e78f23          	sb	a4,30(a5)
    8000603a:	00e78fa3          	sb	a4,31(a5)
}
    8000603e:	60e2                	ld	ra,24(sp)
    80006040:	6442                	ld	s0,16(sp)
    80006042:	64a2                	ld	s1,8(sp)
    80006044:	6105                	addi	sp,sp,32
    80006046:	8082                	ret
    panic("could not find virtio disk");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	75850513          	addi	a0,a0,1880 # 800087a0 <syscalls+0x368>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	506080e7          	jalr	1286(ra) # 80000556 <panic>
    panic("virtio disk has no queue 0");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	76850513          	addi	a0,a0,1896 # 800087c0 <syscalls+0x388>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4f6080e7          	jalr	1270(ra) # 80000556 <panic>
    panic("virtio disk max queue too short");
    80006068:	00002517          	auipc	a0,0x2
    8000606c:	77850513          	addi	a0,a0,1912 # 800087e0 <syscalls+0x3a8>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4e6080e7          	jalr	1254(ra) # 80000556 <panic>

0000000080006078 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006078:	7119                	addi	sp,sp,-128
    8000607a:	fc86                	sd	ra,120(sp)
    8000607c:	f8a2                	sd	s0,112(sp)
    8000607e:	f4a6                	sd	s1,104(sp)
    80006080:	f0ca                	sd	s2,96(sp)
    80006082:	ecce                	sd	s3,88(sp)
    80006084:	e8d2                	sd	s4,80(sp)
    80006086:	e4d6                	sd	s5,72(sp)
    80006088:	e0da                	sd	s6,64(sp)
    8000608a:	fc5e                	sd	s7,56(sp)
    8000608c:	f862                	sd	s8,48(sp)
    8000608e:	f466                	sd	s9,40(sp)
    80006090:	f06a                	sd	s10,32(sp)
    80006092:	0100                	addi	s0,sp,128
    80006094:	892a                	mv	s2,a0
    80006096:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006098:	00c52c83          	lw	s9,12(a0)
    8000609c:	001c9c9b          	slliw	s9,s9,0x1
    800060a0:	1c82                	slli	s9,s9,0x20
    800060a2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060a6:	0001f517          	auipc	a0,0x1f
    800060aa:	00250513          	addi	a0,a0,2 # 800250a8 <disk+0x20a8>
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	b70080e7          	jalr	-1168(ra) # 80000c1e <acquire>
  for(int i = 0; i < 3; i++){
    800060b6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060b8:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060ba:	0001db97          	auipc	s7,0x1d
    800060be:	f46b8b93          	addi	s7,s7,-186 # 80023000 <disk>
    800060c2:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060c4:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060c6:	8a4e                	mv	s4,s3
    800060c8:	a051                	j	8000614c <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060ca:	00fb86b3          	add	a3,s7,a5
    800060ce:	96da                	add	a3,a3,s6
    800060d0:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060d4:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060d6:	0207c563          	bltz	a5,80006100 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060da:	2485                	addiw	s1,s1,1
    800060dc:	0711                	addi	a4,a4,4
    800060de:	23548d63          	beq	s1,s5,80006318 <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800060e2:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060e4:	0001f697          	auipc	a3,0x1f
    800060e8:	f3468693          	addi	a3,a3,-204 # 80025018 <disk+0x2018>
    800060ec:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060ee:	0006c583          	lbu	a1,0(a3)
    800060f2:	fde1                	bnez	a1,800060ca <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060f4:	2785                	addiw	a5,a5,1
    800060f6:	0685                	addi	a3,a3,1
    800060f8:	ff879be3          	bne	a5,s8,800060ee <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060fc:	57fd                	li	a5,-1
    800060fe:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006100:	02905a63          	blez	s1,80006134 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006104:	f9042503          	lw	a0,-112(s0)
    80006108:	00000097          	auipc	ra,0x0
    8000610c:	daa080e7          	jalr	-598(ra) # 80005eb2 <free_desc>
      for(int j = 0; j < i; j++)
    80006110:	4785                	li	a5,1
    80006112:	0297d163          	bge	a5,s1,80006134 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006116:	f9442503          	lw	a0,-108(s0)
    8000611a:	00000097          	auipc	ra,0x0
    8000611e:	d98080e7          	jalr	-616(ra) # 80005eb2 <free_desc>
      for(int j = 0; j < i; j++)
    80006122:	4789                	li	a5,2
    80006124:	0097d863          	bge	a5,s1,80006134 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006128:	f9842503          	lw	a0,-104(s0)
    8000612c:	00000097          	auipc	ra,0x0
    80006130:	d86080e7          	jalr	-634(ra) # 80005eb2 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006134:	0001f597          	auipc	a1,0x1f
    80006138:	f7458593          	addi	a1,a1,-140 # 800250a8 <disk+0x20a8>
    8000613c:	0001f517          	auipc	a0,0x1f
    80006140:	edc50513          	addi	a0,a0,-292 # 80025018 <disk+0x2018>
    80006144:	ffffc097          	auipc	ra,0xffffc
    80006148:	292080e7          	jalr	658(ra) # 800023d6 <sleep>
  for(int i = 0; i < 3; i++){
    8000614c:	f9040713          	addi	a4,s0,-112
    80006150:	84ce                	mv	s1,s3
    80006152:	bf41                	j	800060e2 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006154:	4785                	li	a5,1
    80006156:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000615a:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    8000615e:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006162:	f9042983          	lw	s3,-112(s0)
    80006166:	00499493          	slli	s1,s3,0x4
    8000616a:	0001fa17          	auipc	s4,0x1f
    8000616e:	e96a0a13          	addi	s4,s4,-362 # 80025000 <disk+0x2000>
    80006172:	000a3a83          	ld	s5,0(s4)
    80006176:	9aa6                	add	s5,s5,s1
    80006178:	f8040513          	addi	a0,s0,-128
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	f72080e7          	jalr	-142(ra) # 800010ee <kvmpa>
    80006184:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006188:	000a3783          	ld	a5,0(s4)
    8000618c:	97a6                	add	a5,a5,s1
    8000618e:	4741                	li	a4,16
    80006190:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006192:	000a3783          	ld	a5,0(s4)
    80006196:	97a6                	add	a5,a5,s1
    80006198:	4705                	li	a4,1
    8000619a:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    8000619e:	f9442703          	lw	a4,-108(s0)
    800061a2:	000a3783          	ld	a5,0(s4)
    800061a6:	97a6                	add	a5,a5,s1
    800061a8:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061ac:	0712                	slli	a4,a4,0x4
    800061ae:	000a3783          	ld	a5,0(s4)
    800061b2:	97ba                	add	a5,a5,a4
    800061b4:	05890693          	addi	a3,s2,88
    800061b8:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800061ba:	000a3783          	ld	a5,0(s4)
    800061be:	97ba                	add	a5,a5,a4
    800061c0:	40000693          	li	a3,1024
    800061c4:	c794                	sw	a3,8(a5)
  if(write)
    800061c6:	100d0a63          	beqz	s10,800062da <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061ca:	0001f797          	auipc	a5,0x1f
    800061ce:	e367b783          	ld	a5,-458(a5) # 80025000 <disk+0x2000>
    800061d2:	97ba                	add	a5,a5,a4
    800061d4:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061d8:	0001d517          	auipc	a0,0x1d
    800061dc:	e2850513          	addi	a0,a0,-472 # 80023000 <disk>
    800061e0:	0001f797          	auipc	a5,0x1f
    800061e4:	e2078793          	addi	a5,a5,-480 # 80025000 <disk+0x2000>
    800061e8:	6394                	ld	a3,0(a5)
    800061ea:	96ba                	add	a3,a3,a4
    800061ec:	00c6d603          	lhu	a2,12(a3)
    800061f0:	00166613          	ori	a2,a2,1
    800061f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061f8:	f9842683          	lw	a3,-104(s0)
    800061fc:	6390                	ld	a2,0(a5)
    800061fe:	9732                	add	a4,a4,a2
    80006200:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006204:	20098613          	addi	a2,s3,512
    80006208:	0612                	slli	a2,a2,0x4
    8000620a:	962a                	add	a2,a2,a0
    8000620c:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006210:	00469713          	slli	a4,a3,0x4
    80006214:	6394                	ld	a3,0(a5)
    80006216:	96ba                	add	a3,a3,a4
    80006218:	6589                	lui	a1,0x2
    8000621a:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    8000621e:	94ae                	add	s1,s1,a1
    80006220:	94aa                	add	s1,s1,a0
    80006222:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006224:	6394                	ld	a3,0(a5)
    80006226:	96ba                	add	a3,a3,a4
    80006228:	4585                	li	a1,1
    8000622a:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000622c:	6394                	ld	a3,0(a5)
    8000622e:	96ba                	add	a3,a3,a4
    80006230:	4509                	li	a0,2
    80006232:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006236:	6394                	ld	a3,0(a5)
    80006238:	9736                	add	a4,a4,a3
    8000623a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000623e:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006242:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006246:	6794                	ld	a3,8(a5)
    80006248:	0026d703          	lhu	a4,2(a3)
    8000624c:	8b1d                	andi	a4,a4,7
    8000624e:	2709                	addiw	a4,a4,2
    80006250:	0706                	slli	a4,a4,0x1
    80006252:	9736                	add	a4,a4,a3
    80006254:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006258:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000625c:	6798                	ld	a4,8(a5)
    8000625e:	00275783          	lhu	a5,2(a4)
    80006262:	2785                	addiw	a5,a5,1
    80006264:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006268:	100017b7          	lui	a5,0x10001
    8000626c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006270:	00492703          	lw	a4,4(s2)
    80006274:	4785                	li	a5,1
    80006276:	02f71163          	bne	a4,a5,80006298 <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000627a:	0001f997          	auipc	s3,0x1f
    8000627e:	e2e98993          	addi	s3,s3,-466 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006282:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006284:	85ce                	mv	a1,s3
    80006286:	854a                	mv	a0,s2
    80006288:	ffffc097          	auipc	ra,0xffffc
    8000628c:	14e080e7          	jalr	334(ra) # 800023d6 <sleep>
  while(b->disk == 1) {
    80006290:	00492783          	lw	a5,4(s2)
    80006294:	fe9788e3          	beq	a5,s1,80006284 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    80006298:	f9042483          	lw	s1,-112(s0)
    8000629c:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800062a0:	00479713          	slli	a4,a5,0x4
    800062a4:	0001d797          	auipc	a5,0x1d
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80023000 <disk>
    800062ac:	97ba                	add	a5,a5,a4
    800062ae:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062b2:	0001f917          	auipc	s2,0x1f
    800062b6:	d4e90913          	addi	s2,s2,-690 # 80025000 <disk+0x2000>
    free_desc(i);
    800062ba:	8526                	mv	a0,s1
    800062bc:	00000097          	auipc	ra,0x0
    800062c0:	bf6080e7          	jalr	-1034(ra) # 80005eb2 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062c4:	0492                	slli	s1,s1,0x4
    800062c6:	00093783          	ld	a5,0(s2)
    800062ca:	94be                	add	s1,s1,a5
    800062cc:	00c4d783          	lhu	a5,12(s1)
    800062d0:	8b85                	andi	a5,a5,1
    800062d2:	cf89                	beqz	a5,800062ec <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800062d4:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800062d8:	b7cd                	j	800062ba <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062da:	0001f797          	auipc	a5,0x1f
    800062de:	d267b783          	ld	a5,-730(a5) # 80025000 <disk+0x2000>
    800062e2:	97ba                	add	a5,a5,a4
    800062e4:	4689                	li	a3,2
    800062e6:	00d79623          	sh	a3,12(a5)
    800062ea:	b5fd                	j	800061d8 <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ec:	0001f517          	auipc	a0,0x1f
    800062f0:	dbc50513          	addi	a0,a0,-580 # 800250a8 <disk+0x20a8>
    800062f4:	ffffb097          	auipc	ra,0xffffb
    800062f8:	9de080e7          	jalr	-1570(ra) # 80000cd2 <release>
}
    800062fc:	70e6                	ld	ra,120(sp)
    800062fe:	7446                	ld	s0,112(sp)
    80006300:	74a6                	ld	s1,104(sp)
    80006302:	7906                	ld	s2,96(sp)
    80006304:	69e6                	ld	s3,88(sp)
    80006306:	6a46                	ld	s4,80(sp)
    80006308:	6aa6                	ld	s5,72(sp)
    8000630a:	6b06                	ld	s6,64(sp)
    8000630c:	7be2                	ld	s7,56(sp)
    8000630e:	7c42                	ld	s8,48(sp)
    80006310:	7ca2                	ld	s9,40(sp)
    80006312:	7d02                	ld	s10,32(sp)
    80006314:	6109                	addi	sp,sp,128
    80006316:	8082                	ret
  if(write)
    80006318:	e20d1ee3          	bnez	s10,80006154 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    8000631c:	f8042023          	sw	zero,-128(s0)
    80006320:	bd2d                	j	8000615a <virtio_disk_rw+0xe2>

0000000080006322 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006322:	1101                	addi	sp,sp,-32
    80006324:	ec06                	sd	ra,24(sp)
    80006326:	e822                	sd	s0,16(sp)
    80006328:	e426                	sd	s1,8(sp)
    8000632a:	e04a                	sd	s2,0(sp)
    8000632c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000632e:	0001f517          	auipc	a0,0x1f
    80006332:	d7a50513          	addi	a0,a0,-646 # 800250a8 <disk+0x20a8>
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	8e8080e7          	jalr	-1816(ra) # 80000c1e <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000633e:	0001f717          	auipc	a4,0x1f
    80006342:	cc270713          	addi	a4,a4,-830 # 80025000 <disk+0x2000>
    80006346:	02075783          	lhu	a5,32(a4)
    8000634a:	6b18                	ld	a4,16(a4)
    8000634c:	00275683          	lhu	a3,2(a4)
    80006350:	8ebd                	xor	a3,a3,a5
    80006352:	8a9d                	andi	a3,a3,7
    80006354:	cab9                	beqz	a3,800063aa <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006356:	0001d917          	auipc	s2,0x1d
    8000635a:	caa90913          	addi	s2,s2,-854 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000635e:	0001f497          	auipc	s1,0x1f
    80006362:	ca248493          	addi	s1,s1,-862 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006366:	078e                	slli	a5,a5,0x3
    80006368:	97ba                	add	a5,a5,a4
    8000636a:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    8000636c:	20078713          	addi	a4,a5,512
    80006370:	0712                	slli	a4,a4,0x4
    80006372:	974a                	add	a4,a4,s2
    80006374:	03074703          	lbu	a4,48(a4)
    80006378:	ef21                	bnez	a4,800063d0 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000637a:	20078793          	addi	a5,a5,512
    8000637e:	0792                	slli	a5,a5,0x4
    80006380:	97ca                	add	a5,a5,s2
    80006382:	7798                	ld	a4,40(a5)
    80006384:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006388:	7788                	ld	a0,40(a5)
    8000638a:	ffffc097          	auipc	ra,0xffffc
    8000638e:	1d2080e7          	jalr	466(ra) # 8000255c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006392:	0204d783          	lhu	a5,32(s1)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	8b9d                	andi	a5,a5,7
    8000639a:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000639e:	6898                	ld	a4,16(s1)
    800063a0:	00275683          	lhu	a3,2(a4)
    800063a4:	8a9d                	andi	a3,a3,7
    800063a6:	fcf690e3          	bne	a3,a5,80006366 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063aa:	10001737          	lui	a4,0x10001
    800063ae:	533c                	lw	a5,96(a4)
    800063b0:	8b8d                	andi	a5,a5,3
    800063b2:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063b4:	0001f517          	auipc	a0,0x1f
    800063b8:	cf450513          	addi	a0,a0,-780 # 800250a8 <disk+0x20a8>
    800063bc:	ffffb097          	auipc	ra,0xffffb
    800063c0:	916080e7          	jalr	-1770(ra) # 80000cd2 <release>
}
    800063c4:	60e2                	ld	ra,24(sp)
    800063c6:	6442                	ld	s0,16(sp)
    800063c8:	64a2                	ld	s1,8(sp)
    800063ca:	6902                	ld	s2,0(sp)
    800063cc:	6105                	addi	sp,sp,32
    800063ce:	8082                	ret
      panic("virtio_disk_intr status");
    800063d0:	00002517          	auipc	a0,0x2
    800063d4:	43050513          	addi	a0,a0,1072 # 80008800 <syscalls+0x3c8>
    800063d8:	ffffa097          	auipc	ra,0xffffa
    800063dc:	17e080e7          	jalr	382(ra) # 80000556 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
