
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
    80000060:	e1478793          	addi	a5,a5,-492 # 80005e70 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffb87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	fb078793          	addi	a5,a5,-80 # 80001056 <main>
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
    8000011e:	c8e080e7          	jalr	-882(ra) # 80000da8 <acquire>
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
    80000138:	60e080e7          	jalr	1550(ra) # 80002742 <either_copyin>
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
    80000160:	d00080e7          	jalr	-768(ra) # 80000e5c <release>

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
    800001b0:	bfc080e7          	jalr	-1028(ra) # 80000da8 <acquire>
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
    800001e0:	a9e080e7          	jalr	-1378(ra) # 80001c7a <myproc>
    800001e4:	591c                	lw	a5,48(a0)
    800001e6:	e7b5                	bnez	a5,80000252 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e8:	85ce                	mv	a1,s3
    800001ea:	854a                	mv	a0,s2
    800001ec:	00002097          	auipc	ra,0x2
    800001f0:	29e080e7          	jalr	670(ra) # 8000248a <sleep>
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
    8000022c:	4c4080e7          	jalr	1220(ra) # 800026ec <either_copyout>
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
    80000248:	c18080e7          	jalr	-1000(ra) # 80000e5c <release>

  return target - n;
    8000024c:	414b853b          	subw	a0,s7,s4
    80000250:	a811                	j	80000264 <consoleread+0xe8>
        release(&cons.lock);
    80000252:	00011517          	auipc	a0,0x11
    80000256:	5de50513          	addi	a0,a0,1502 # 80011830 <cons>
    8000025a:	00001097          	auipc	ra,0x1
    8000025e:	c02080e7          	jalr	-1022(ra) # 80000e5c <release>
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
    800002f0:	abc080e7          	jalr	-1348(ra) # 80000da8 <acquire>

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
    8000030e:	48e080e7          	jalr	1166(ra) # 80002798 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000312:	00011517          	auipc	a0,0x11
    80000316:	51e50513          	addi	a0,a0,1310 # 80011830 <cons>
    8000031a:	00001097          	auipc	ra,0x1
    8000031e:	b42080e7          	jalr	-1214(ra) # 80000e5c <release>
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
    80000462:	1b2080e7          	jalr	434(ra) # 80002610 <wakeup>
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
    80000480:	00001097          	auipc	ra,0x1
    80000484:	898080e7          	jalr	-1896(ra) # 80000d18 <initlock>

  uartinit();
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	330080e7          	jalr	816(ra) # 800007b8 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000490:	00041797          	auipc	a5,0x41
    80000494:	53878793          	addi	a5,a5,1336 # 800419c8 <devsw>
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
    80000588:	b4c50513          	addi	a0,a0,-1204 # 800080d0 <digits+0x90>
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
    8000061c:	790080e7          	jalr	1936(ra) # 80000da8 <acquire>
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
    80000780:	6e0080e7          	jalr	1760(ra) # 80000e5c <release>
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
    800007a6:	576080e7          	jalr	1398(ra) # 80000d18 <initlock>
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
    800007fc:	520080e7          	jalr	1312(ra) # 80000d18 <initlock>
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
    80000818:	548080e7          	jalr	1352(ra) # 80000d5c <push_off>

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
    8000084a:	5b6080e7          	jalr	1462(ra) # 80000dfc <pop_off>
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
    800008c8:	d4c080e7          	jalr	-692(ra) # 80002610 <wakeup>
    
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
    8000090c:	4a0080e7          	jalr	1184(ra) # 80000da8 <acquire>
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
    80000962:	b2c080e7          	jalr	-1236(ra) # 8000248a <sleep>
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
    800009a6:	4ba080e7          	jalr	1210(ra) # 80000e5c <release>
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
    80000a12:	39a080e7          	jalr	922(ra) # 80000da8 <acquire>
  uartstart();
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	e42080e7          	jalr	-446(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    80000a1e:	8526                	mv	a0,s1
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	43c080e7          	jalr	1084(ra) # 80000e5c <release>
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
    80000a32:	7179                	addi	sp,sp,-48
    80000a34:	f406                	sd	ra,40(sp)
    80000a36:	f022                	sd	s0,32(sp)
    80000a38:	ec26                	sd	s1,24(sp)
    80000a3a:	e84a                	sd	s2,16(sp)
    80000a3c:	e44e                	sd	s3,8(sp)
    80000a3e:	1800                	addi	s0,sp,48
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a40:	03451793          	slli	a5,a0,0x34
    80000a44:	e7a5                	bnez	a5,80000aac <kfree+0x7a>
    80000a46:	84aa                	mv	s1,a0
    80000a48:	00045797          	auipc	a5,0x45
    80000a4c:	5b878793          	addi	a5,a5,1464 # 80046000 <end>
    80000a50:	04f56e63          	bltu	a0,a5,80000aac <kfree+0x7a>
    80000a54:	47c5                	li	a5,17
    80000a56:	07ee                	slli	a5,a5,0x1b
    80000a58:	04f57a63          	bgeu	a0,a5,80000aac <kfree+0x7a>
    panic("kfree");

  acquire(&pgreflock);
    80000a5c:	00011517          	auipc	a0,0x11
    80000a60:	ed450513          	addi	a0,a0,-300 # 80011930 <pgreflock>
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	344080e7          	jalr	836(ra) # 80000da8 <acquire>
  if(--PA2PGREF(pa) <= 0) {
    80000a6c:	800007b7          	lui	a5,0x80000
    80000a70:	97a6                	add	a5,a5,s1
    80000a72:	83b1                	srli	a5,a5,0xc
    80000a74:	078a                	slli	a5,a5,0x2
    80000a76:	00011717          	auipc	a4,0x11
    80000a7a:	ef270713          	addi	a4,a4,-270 # 80011968 <pageref>
    80000a7e:	97ba                	add	a5,a5,a4
    80000a80:	4398                	lw	a4,0(a5)
    80000a82:	377d                	addiw	a4,a4,-1
    80000a84:	0007069b          	sext.w	a3,a4
    80000a88:	c398                	sw	a4,0(a5)
    80000a8a:	02d05963          	blez	a3,80000abc <kfree+0x8a>
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
  }
  release(&pgreflock);
    80000a8e:	00011517          	auipc	a0,0x11
    80000a92:	ea250513          	addi	a0,a0,-350 # 80011930 <pgreflock>
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	3c6080e7          	jalr	966(ra) # 80000e5c <release>
}
    80000a9e:	70a2                	ld	ra,40(sp)
    80000aa0:	7402                	ld	s0,32(sp)
    80000aa2:	64e2                	ld	s1,24(sp)
    80000aa4:	6942                	ld	s2,16(sp)
    80000aa6:	69a2                	ld	s3,8(sp)
    80000aa8:	6145                	addi	sp,sp,48
    80000aaa:	8082                	ret
    panic("kfree");
    80000aac:	00007517          	auipc	a0,0x7
    80000ab0:	5b450513          	addi	a0,a0,1460 # 80008060 <digits+0x20>
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	aa2080e7          	jalr	-1374(ra) # 80000556 <panic>
    memset(pa, 1, PGSIZE);
    80000abc:	6605                	lui	a2,0x1
    80000abe:	4585                	li	a1,1
    80000ac0:	8526                	mv	a0,s1
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	3e2080e7          	jalr	994(ra) # 80000ea4 <memset>
    acquire(&kmem.lock);
    80000aca:	00011997          	auipc	s3,0x11
    80000ace:	e6698993          	addi	s3,s3,-410 # 80011930 <pgreflock>
    80000ad2:	00011917          	auipc	s2,0x11
    80000ad6:	e7690913          	addi	s2,s2,-394 # 80011948 <kmem>
    80000ada:	854a                	mv	a0,s2
    80000adc:	00000097          	auipc	ra,0x0
    80000ae0:	2cc080e7          	jalr	716(ra) # 80000da8 <acquire>
    r->next = kmem.freelist;
    80000ae4:	0309b783          	ld	a5,48(s3)
    80000ae8:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000aea:	0299b823          	sd	s1,48(s3)
    release(&kmem.lock);
    80000aee:	854a                	mv	a0,s2
    80000af0:	00000097          	auipc	ra,0x0
    80000af4:	36c080e7          	jalr	876(ra) # 80000e5c <release>
    80000af8:	bf59                	j	80000a8e <kfree+0x5c>

0000000080000afa <freerange>:
{
    80000afa:	7179                	addi	sp,sp,-48
    80000afc:	f406                	sd	ra,40(sp)
    80000afe:	f022                	sd	s0,32(sp)
    80000b00:	ec26                	sd	s1,24(sp)
    80000b02:	e84a                	sd	s2,16(sp)
    80000b04:	e44e                	sd	s3,8(sp)
    80000b06:	e052                	sd	s4,0(sp)
    80000b08:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b0a:	6785                	lui	a5,0x1
    80000b0c:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b10:	94aa                	add	s1,s1,a0
    80000b12:	757d                	lui	a0,0xfffff
    80000b14:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b16:	94be                	add	s1,s1,a5
    80000b18:	0095ee63          	bltu	a1,s1,80000b34 <freerange+0x3a>
    80000b1c:	892e                	mv	s2,a1
    kfree(p);
    80000b1e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b20:	6985                	lui	s3,0x1
    kfree(p);
    80000b22:	01448533          	add	a0,s1,s4
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	f0c080e7          	jalr	-244(ra) # 80000a32 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2e:	94ce                	add	s1,s1,s3
    80000b30:	fe9979e3          	bgeu	s2,s1,80000b22 <freerange+0x28>
}
    80000b34:	70a2                	ld	ra,40(sp)
    80000b36:	7402                	ld	s0,32(sp)
    80000b38:	64e2                	ld	s1,24(sp)
    80000b3a:	6942                	ld	s2,16(sp)
    80000b3c:	69a2                	ld	s3,8(sp)
    80000b3e:	6a02                	ld	s4,0(sp)
    80000b40:	6145                	addi	sp,sp,48
    80000b42:	8082                	ret

0000000080000b44 <kinit>:
{
    80000b44:	1141                	addi	sp,sp,-16
    80000b46:	e406                	sd	ra,8(sp)
    80000b48:	e022                	sd	s0,0(sp)
    80000b4a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b4c:	00007597          	auipc	a1,0x7
    80000b50:	51c58593          	addi	a1,a1,1308 # 80008068 <digits+0x28>
    80000b54:	00011517          	auipc	a0,0x11
    80000b58:	df450513          	addi	a0,a0,-524 # 80011948 <kmem>
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	1bc080e7          	jalr	444(ra) # 80000d18 <initlock>
  initlock(&pgreflock, "pgref");
    80000b64:	00007597          	auipc	a1,0x7
    80000b68:	50c58593          	addi	a1,a1,1292 # 80008070 <digits+0x30>
    80000b6c:	00011517          	auipc	a0,0x11
    80000b70:	dc450513          	addi	a0,a0,-572 # 80011930 <pgreflock>
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	1a4080e7          	jalr	420(ra) # 80000d18 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b7c:	45c5                	li	a1,17
    80000b7e:	05ee                	slli	a1,a1,0x1b
    80000b80:	00045517          	auipc	a0,0x45
    80000b84:	48050513          	addi	a0,a0,1152 # 80046000 <end>
    80000b88:	00000097          	auipc	ra,0x0
    80000b8c:	f72080e7          	jalr	-142(ra) # 80000afa <freerange>
}
    80000b90:	60a2                	ld	ra,8(sp)
    80000b92:	6402                	ld	s0,0(sp)
    80000b94:	0141                	addi	sp,sp,16
    80000b96:	8082                	ret

0000000080000b98 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000ba2:	00011517          	auipc	a0,0x11
    80000ba6:	da650513          	addi	a0,a0,-602 # 80011948 <kmem>
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	1fe080e7          	jalr	510(ra) # 80000da8 <acquire>
  r = kmem.freelist;
    80000bb2:	00011497          	auipc	s1,0x11
    80000bb6:	dae4b483          	ld	s1,-594(s1) # 80011960 <kmem+0x18>
  if(r)
    80000bba:	c4b9                	beqz	s1,80000c08 <kalloc+0x70>
    kmem.freelist = r->next;
    80000bbc:	609c                	ld	a5,0(s1)
    80000bbe:	00011717          	auipc	a4,0x11
    80000bc2:	daf73123          	sd	a5,-606(a4) # 80011960 <kmem+0x18>
  release(&kmem.lock);
    80000bc6:	00011517          	auipc	a0,0x11
    80000bca:	d8250513          	addi	a0,a0,-638 # 80011948 <kmem>
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	28e080e7          	jalr	654(ra) # 80000e5c <release>

  if(r){
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bd6:	6605                	lui	a2,0x1
    80000bd8:	4595                	li	a1,5
    80000bda:	8526                	mv	a0,s1
    80000bdc:	00000097          	auipc	ra,0x0
    80000be0:	2c8080e7          	jalr	712(ra) # 80000ea4 <memset>
    // reference count for a physical page is always 1 after allocation.
    // (no need to lock this operation)
    PA2PGREF(r) = 1;
    80000be4:	800007b7          	lui	a5,0x80000
    80000be8:	97a6                	add	a5,a5,s1
    80000bea:	83b1                	srli	a5,a5,0xc
    80000bec:	078a                	slli	a5,a5,0x2
    80000bee:	00011717          	auipc	a4,0x11
    80000bf2:	d7a70713          	addi	a4,a4,-646 # 80011968 <pageref>
    80000bf6:	97ba                	add	a5,a5,a4
    80000bf8:	4705                	li	a4,1
    80000bfa:	c398                	sw	a4,0(a5)
  }
  
  return (void*)r;
}
    80000bfc:	8526                	mv	a0,s1
    80000bfe:	60e2                	ld	ra,24(sp)
    80000c00:	6442                	ld	s0,16(sp)
    80000c02:	64a2                	ld	s1,8(sp)
    80000c04:	6105                	addi	sp,sp,32
    80000c06:	8082                	ret
  release(&kmem.lock);
    80000c08:	00011517          	auipc	a0,0x11
    80000c0c:	d4050513          	addi	a0,a0,-704 # 80011948 <kmem>
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	24c080e7          	jalr	588(ra) # 80000e5c <release>
  if(r){
    80000c18:	b7d5                	j	80000bfc <kalloc+0x64>

0000000080000c1a <kcopy_n_deref>:
// allocate a new physical page and copy the page into it.
// (Effectively turing one reference into one copy.)
// 
// Do nothing and simply return pa when reference count is already
// less than or equal to 1.
void *kcopy_n_deref(void *pa) {
    80000c1a:	7179                	addi	sp,sp,-48
    80000c1c:	f406                	sd	ra,40(sp)
    80000c1e:	f022                	sd	s0,32(sp)
    80000c20:	ec26                	sd	s1,24(sp)
    80000c22:	e84a                	sd	s2,16(sp)
    80000c24:	e44e                	sd	s3,8(sp)
    80000c26:	1800                	addi	s0,sp,48
    80000c28:	892a                	mv	s2,a0
  acquire(&pgreflock);
    80000c2a:	00011517          	auipc	a0,0x11
    80000c2e:	d0650513          	addi	a0,a0,-762 # 80011930 <pgreflock>
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	176080e7          	jalr	374(ra) # 80000da8 <acquire>

  if(PA2PGREF(pa) <= 1) {
    80000c3a:	800004b7          	lui	s1,0x80000
    80000c3e:	94ca                	add	s1,s1,s2
    80000c40:	80b1                	srli	s1,s1,0xc
    80000c42:	00249713          	slli	a4,s1,0x2
    80000c46:	00011797          	auipc	a5,0x11
    80000c4a:	d2278793          	addi	a5,a5,-734 # 80011968 <pageref>
    80000c4e:	97ba                	add	a5,a5,a4
    80000c50:	4398                	lw	a4,0(a5)
    80000c52:	4785                	li	a5,1
    80000c54:	04e7d763          	bge	a5,a4,80000ca2 <kcopy_n_deref+0x88>
    release(&pgreflock);
    return pa;
  }

  uint64 newpa = (uint64)kalloc();
    80000c58:	00000097          	auipc	ra,0x0
    80000c5c:	f40080e7          	jalr	-192(ra) # 80000b98 <kalloc>
    80000c60:	89aa                	mv	s3,a0
  if(newpa == 0) {
    80000c62:	c931                	beqz	a0,80000cb6 <kcopy_n_deref+0x9c>
    release(&pgreflock);
    return 0; // out of memory
  }
  memmove((void*)newpa, (void*)pa, PGSIZE);
    80000c64:	6605                	lui	a2,0x1
    80000c66:	85ca                	mv	a1,s2
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	29c080e7          	jalr	668(ra) # 80000f04 <memmove>
  PA2PGREF(pa)--;
    80000c70:	048a                	slli	s1,s1,0x2
    80000c72:	00011797          	auipc	a5,0x11
    80000c76:	cf678793          	addi	a5,a5,-778 # 80011968 <pageref>
    80000c7a:	94be                	add	s1,s1,a5
    80000c7c:	409c                	lw	a5,0(s1)
    80000c7e:	37fd                	addiw	a5,a5,-1
    80000c80:	c09c                	sw	a5,0(s1)

  release(&pgreflock);
    80000c82:	00011517          	auipc	a0,0x11
    80000c86:	cae50513          	addi	a0,a0,-850 # 80011930 <pgreflock>
    80000c8a:	00000097          	auipc	ra,0x0
    80000c8e:	1d2080e7          	jalr	466(ra) # 80000e5c <release>
  return (void*)newpa;
}
    80000c92:	854e                	mv	a0,s3
    80000c94:	70a2                	ld	ra,40(sp)
    80000c96:	7402                	ld	s0,32(sp)
    80000c98:	64e2                	ld	s1,24(sp)
    80000c9a:	6942                	ld	s2,16(sp)
    80000c9c:	69a2                	ld	s3,8(sp)
    80000c9e:	6145                	addi	sp,sp,48
    80000ca0:	8082                	ret
    release(&pgreflock);
    80000ca2:	00011517          	auipc	a0,0x11
    80000ca6:	c8e50513          	addi	a0,a0,-882 # 80011930 <pgreflock>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	1b2080e7          	jalr	434(ra) # 80000e5c <release>
    return pa;
    80000cb2:	89ca                	mv	s3,s2
    80000cb4:	bff9                	j	80000c92 <kcopy_n_deref+0x78>
    release(&pgreflock);
    80000cb6:	00011517          	auipc	a0,0x11
    80000cba:	c7a50513          	addi	a0,a0,-902 # 80011930 <pgreflock>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	19e080e7          	jalr	414(ra) # 80000e5c <release>
    return 0; // out of memory
    80000cc6:	b7f1                	j	80000c92 <kcopy_n_deref+0x78>

0000000080000cc8 <krefpage>:

// increase reference count of the page by one
void krefpage(void *pa) {
    80000cc8:	1101                	addi	sp,sp,-32
    80000cca:	ec06                	sd	ra,24(sp)
    80000ccc:	e822                	sd	s0,16(sp)
    80000cce:	e426                	sd	s1,8(sp)
    80000cd0:	e04a                	sd	s2,0(sp)
    80000cd2:	1000                	addi	s0,sp,32
    80000cd4:	84aa                	mv	s1,a0
  acquire(&pgreflock);
    80000cd6:	00011917          	auipc	s2,0x11
    80000cda:	c5a90913          	addi	s2,s2,-934 # 80011930 <pgreflock>
    80000cde:	854a                	mv	a0,s2
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	0c8080e7          	jalr	200(ra) # 80000da8 <acquire>
  PA2PGREF(pa)++;
    80000ce8:	80000537          	lui	a0,0x80000
    80000cec:	94aa                	add	s1,s1,a0
    80000cee:	80b1                	srli	s1,s1,0xc
    80000cf0:	048a                	slli	s1,s1,0x2
    80000cf2:	00011797          	auipc	a5,0x11
    80000cf6:	c7678793          	addi	a5,a5,-906 # 80011968 <pageref>
    80000cfa:	94be                	add	s1,s1,a5
    80000cfc:	409c                	lw	a5,0(s1)
    80000cfe:	2785                	addiw	a5,a5,1
    80000d00:	c09c                	sw	a5,0(s1)
  release(&pgreflock);
    80000d02:	854a                	mv	a0,s2
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	158080e7          	jalr	344(ra) # 80000e5c <release>
    80000d0c:	60e2                	ld	ra,24(sp)
    80000d0e:	6442                	ld	s0,16(sp)
    80000d10:	64a2                	ld	s1,8(sp)
    80000d12:	6902                	ld	s2,0(sp)
    80000d14:	6105                	addi	sp,sp,32
    80000d16:	8082                	ret

0000000080000d18 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d18:	1141                	addi	sp,sp,-16
    80000d1a:	e422                	sd	s0,8(sp)
    80000d1c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d1e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d20:	00052023          	sw	zero,0(a0) # ffffffff80000000 <end+0xfffffffefffba000>
  lk->cpu = 0;
    80000d24:	00053823          	sd	zero,16(a0)
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret

0000000080000d2e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d2e:	411c                	lw	a5,0(a0)
    80000d30:	e399                	bnez	a5,80000d36 <holding+0x8>
    80000d32:	4501                	li	a0,0
  return r;
}
    80000d34:	8082                	ret
{
    80000d36:	1101                	addi	sp,sp,-32
    80000d38:	ec06                	sd	ra,24(sp)
    80000d3a:	e822                	sd	s0,16(sp)
    80000d3c:	e426                	sd	s1,8(sp)
    80000d3e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d40:	6904                	ld	s1,16(a0)
    80000d42:	00001097          	auipc	ra,0x1
    80000d46:	f1c080e7          	jalr	-228(ra) # 80001c5e <mycpu>
    80000d4a:	40a48533          	sub	a0,s1,a0
    80000d4e:	00153513          	seqz	a0,a0
}
    80000d52:	60e2                	ld	ra,24(sp)
    80000d54:	6442                	ld	s0,16(sp)
    80000d56:	64a2                	ld	s1,8(sp)
    80000d58:	6105                	addi	sp,sp,32
    80000d5a:	8082                	ret

0000000080000d5c <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d5c:	1101                	addi	sp,sp,-32
    80000d5e:	ec06                	sd	ra,24(sp)
    80000d60:	e822                	sd	s0,16(sp)
    80000d62:	e426                	sd	s1,8(sp)
    80000d64:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d66:	100024f3          	csrr	s1,sstatus
    80000d6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d6e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d70:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d74:	00001097          	auipc	ra,0x1
    80000d78:	eea080e7          	jalr	-278(ra) # 80001c5e <mycpu>
    80000d7c:	5d3c                	lw	a5,120(a0)
    80000d7e:	cf89                	beqz	a5,80000d98 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d80:	00001097          	auipc	ra,0x1
    80000d84:	ede080e7          	jalr	-290(ra) # 80001c5e <mycpu>
    80000d88:	5d3c                	lw	a5,120(a0)
    80000d8a:	2785                	addiw	a5,a5,1
    80000d8c:	dd3c                	sw	a5,120(a0)
}
    80000d8e:	60e2                	ld	ra,24(sp)
    80000d90:	6442                	ld	s0,16(sp)
    80000d92:	64a2                	ld	s1,8(sp)
    80000d94:	6105                	addi	sp,sp,32
    80000d96:	8082                	ret
    mycpu()->intena = old;
    80000d98:	00001097          	auipc	ra,0x1
    80000d9c:	ec6080e7          	jalr	-314(ra) # 80001c5e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000da0:	8085                	srli	s1,s1,0x1
    80000da2:	8885                	andi	s1,s1,1
    80000da4:	dd64                	sw	s1,124(a0)
    80000da6:	bfe9                	j	80000d80 <push_off+0x24>

0000000080000da8 <acquire>:
{
    80000da8:	1101                	addi	sp,sp,-32
    80000daa:	ec06                	sd	ra,24(sp)
    80000dac:	e822                	sd	s0,16(sp)
    80000dae:	e426                	sd	s1,8(sp)
    80000db0:	1000                	addi	s0,sp,32
    80000db2:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000db4:	00000097          	auipc	ra,0x0
    80000db8:	fa8080e7          	jalr	-88(ra) # 80000d5c <push_off>
  if(holding(lk))
    80000dbc:	8526                	mv	a0,s1
    80000dbe:	00000097          	auipc	ra,0x0
    80000dc2:	f70080e7          	jalr	-144(ra) # 80000d2e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dc6:	4705                	li	a4,1
  if(holding(lk))
    80000dc8:	e115                	bnez	a0,80000dec <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dca:	87ba                	mv	a5,a4
    80000dcc:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dd0:	2781                	sext.w	a5,a5
    80000dd2:	ffe5                	bnez	a5,80000dca <acquire+0x22>
  __sync_synchronize();
    80000dd4:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dd8:	00001097          	auipc	ra,0x1
    80000ddc:	e86080e7          	jalr	-378(ra) # 80001c5e <mycpu>
    80000de0:	e888                	sd	a0,16(s1)
}
    80000de2:	60e2                	ld	ra,24(sp)
    80000de4:	6442                	ld	s0,16(sp)
    80000de6:	64a2                	ld	s1,8(sp)
    80000de8:	6105                	addi	sp,sp,32
    80000dea:	8082                	ret
    panic("acquire");
    80000dec:	00007517          	auipc	a0,0x7
    80000df0:	28c50513          	addi	a0,a0,652 # 80008078 <digits+0x38>
    80000df4:	fffff097          	auipc	ra,0xfffff
    80000df8:	762080e7          	jalr	1890(ra) # 80000556 <panic>

0000000080000dfc <pop_off>:

void
pop_off(void)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000e04:	00001097          	auipc	ra,0x1
    80000e08:	e5a080e7          	jalr	-422(ra) # 80001c5e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e0c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e10:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e12:	e78d                	bnez	a5,80000e3c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e14:	5d3c                	lw	a5,120(a0)
    80000e16:	02f05b63          	blez	a5,80000e4c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e1a:	37fd                	addiw	a5,a5,-1
    80000e1c:	0007871b          	sext.w	a4,a5
    80000e20:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e22:	eb09                	bnez	a4,80000e34 <pop_off+0x38>
    80000e24:	5d7c                	lw	a5,124(a0)
    80000e26:	c799                	beqz	a5,80000e34 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e28:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e2c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e30:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e34:	60a2                	ld	ra,8(sp)
    80000e36:	6402                	ld	s0,0(sp)
    80000e38:	0141                	addi	sp,sp,16
    80000e3a:	8082                	ret
    panic("pop_off - interruptible");
    80000e3c:	00007517          	auipc	a0,0x7
    80000e40:	24450513          	addi	a0,a0,580 # 80008080 <digits+0x40>
    80000e44:	fffff097          	auipc	ra,0xfffff
    80000e48:	712080e7          	jalr	1810(ra) # 80000556 <panic>
    panic("pop_off");
    80000e4c:	00007517          	auipc	a0,0x7
    80000e50:	24c50513          	addi	a0,a0,588 # 80008098 <digits+0x58>
    80000e54:	fffff097          	auipc	ra,0xfffff
    80000e58:	702080e7          	jalr	1794(ra) # 80000556 <panic>

0000000080000e5c <release>:
{
    80000e5c:	1101                	addi	sp,sp,-32
    80000e5e:	ec06                	sd	ra,24(sp)
    80000e60:	e822                	sd	s0,16(sp)
    80000e62:	e426                	sd	s1,8(sp)
    80000e64:	1000                	addi	s0,sp,32
    80000e66:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e68:	00000097          	auipc	ra,0x0
    80000e6c:	ec6080e7          	jalr	-314(ra) # 80000d2e <holding>
    80000e70:	c115                	beqz	a0,80000e94 <release+0x38>
  lk->cpu = 0;
    80000e72:	0004b823          	sd	zero,16(s1) # ffffffff80000010 <end+0xfffffffefffba010>
  __sync_synchronize();
    80000e76:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e7a:	0f50000f          	fence	iorw,ow
    80000e7e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e82:	00000097          	auipc	ra,0x0
    80000e86:	f7a080e7          	jalr	-134(ra) # 80000dfc <pop_off>
}
    80000e8a:	60e2                	ld	ra,24(sp)
    80000e8c:	6442                	ld	s0,16(sp)
    80000e8e:	64a2                	ld	s1,8(sp)
    80000e90:	6105                	addi	sp,sp,32
    80000e92:	8082                	ret
    panic("release");
    80000e94:	00007517          	auipc	a0,0x7
    80000e98:	20c50513          	addi	a0,a0,524 # 800080a0 <digits+0x60>
    80000e9c:	fffff097          	auipc	ra,0xfffff
    80000ea0:	6ba080e7          	jalr	1722(ra) # 80000556 <panic>

0000000080000ea4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ea4:	1141                	addi	sp,sp,-16
    80000ea6:	e422                	sd	s0,8(sp)
    80000ea8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000eaa:	ce09                	beqz	a2,80000ec4 <memset+0x20>
    80000eac:	87aa                	mv	a5,a0
    80000eae:	fff6071b          	addiw	a4,a2,-1
    80000eb2:	1702                	slli	a4,a4,0x20
    80000eb4:	9301                	srli	a4,a4,0x20
    80000eb6:	0705                	addi	a4,a4,1
    80000eb8:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000eba:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ebe:	0785                	addi	a5,a5,1
    80000ec0:	fee79de3          	bne	a5,a4,80000eba <memset+0x16>
  }
  return dst;
}
    80000ec4:	6422                	ld	s0,8(sp)
    80000ec6:	0141                	addi	sp,sp,16
    80000ec8:	8082                	ret

0000000080000eca <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000eca:	1141                	addi	sp,sp,-16
    80000ecc:	e422                	sd	s0,8(sp)
    80000ece:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ed0:	ca05                	beqz	a2,80000f00 <memcmp+0x36>
    80000ed2:	fff6069b          	addiw	a3,a2,-1
    80000ed6:	1682                	slli	a3,a3,0x20
    80000ed8:	9281                	srli	a3,a3,0x20
    80000eda:	0685                	addi	a3,a3,1
    80000edc:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000ede:	00054783          	lbu	a5,0(a0)
    80000ee2:	0005c703          	lbu	a4,0(a1)
    80000ee6:	00e79863          	bne	a5,a4,80000ef6 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000eee:	fed518e3          	bne	a0,a3,80000ede <memcmp+0x14>
  }

  return 0;
    80000ef2:	4501                	li	a0,0
    80000ef4:	a019                	j	80000efa <memcmp+0x30>
      return *s1 - *s2;
    80000ef6:	40e7853b          	subw	a0,a5,a4
}
    80000efa:	6422                	ld	s0,8(sp)
    80000efc:	0141                	addi	sp,sp,16
    80000efe:	8082                	ret
  return 0;
    80000f00:	4501                	li	a0,0
    80000f02:	bfe5                	j	80000efa <memcmp+0x30>

0000000080000f04 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f04:	1141                	addi	sp,sp,-16
    80000f06:	e422                	sd	s0,8(sp)
    80000f08:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f0a:	00a5f963          	bgeu	a1,a0,80000f1c <memmove+0x18>
    80000f0e:	02061713          	slli	a4,a2,0x20
    80000f12:	9301                	srli	a4,a4,0x20
    80000f14:	00e587b3          	add	a5,a1,a4
    80000f18:	02f56563          	bltu	a0,a5,80000f42 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f1c:	fff6069b          	addiw	a3,a2,-1
    80000f20:	ce11                	beqz	a2,80000f3c <memmove+0x38>
    80000f22:	1682                	slli	a3,a3,0x20
    80000f24:	9281                	srli	a3,a3,0x20
    80000f26:	0685                	addi	a3,a3,1
    80000f28:	96ae                	add	a3,a3,a1
    80000f2a:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000f2c:	0585                	addi	a1,a1,1
    80000f2e:	0785                	addi	a5,a5,1
    80000f30:	fff5c703          	lbu	a4,-1(a1)
    80000f34:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000f38:	fed59ae3          	bne	a1,a3,80000f2c <memmove+0x28>

  return dst;
}
    80000f3c:	6422                	ld	s0,8(sp)
    80000f3e:	0141                	addi	sp,sp,16
    80000f40:	8082                	ret
    d += n;
    80000f42:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000f44:	fff6069b          	addiw	a3,a2,-1
    80000f48:	da75                	beqz	a2,80000f3c <memmove+0x38>
    80000f4a:	02069613          	slli	a2,a3,0x20
    80000f4e:	9201                	srli	a2,a2,0x20
    80000f50:	fff64613          	not	a2,a2
    80000f54:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000f56:	17fd                	addi	a5,a5,-1
    80000f58:	177d                	addi	a4,a4,-1
    80000f5a:	0007c683          	lbu	a3,0(a5)
    80000f5e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000f62:	fec79ae3          	bne	a5,a2,80000f56 <memmove+0x52>
    80000f66:	bfd9                	j	80000f3c <memmove+0x38>

0000000080000f68 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f68:	1141                	addi	sp,sp,-16
    80000f6a:	e406                	sd	ra,8(sp)
    80000f6c:	e022                	sd	s0,0(sp)
    80000f6e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	f94080e7          	jalr	-108(ra) # 80000f04 <memmove>
}
    80000f78:	60a2                	ld	ra,8(sp)
    80000f7a:	6402                	ld	s0,0(sp)
    80000f7c:	0141                	addi	sp,sp,16
    80000f7e:	8082                	ret

0000000080000f80 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f80:	1141                	addi	sp,sp,-16
    80000f82:	e422                	sd	s0,8(sp)
    80000f84:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f86:	ce11                	beqz	a2,80000fa2 <strncmp+0x22>
    80000f88:	00054783          	lbu	a5,0(a0)
    80000f8c:	cf89                	beqz	a5,80000fa6 <strncmp+0x26>
    80000f8e:	0005c703          	lbu	a4,0(a1)
    80000f92:	00f71a63          	bne	a4,a5,80000fa6 <strncmp+0x26>
    n--, p++, q++;
    80000f96:	367d                	addiw	a2,a2,-1
    80000f98:	0505                	addi	a0,a0,1
    80000f9a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f9c:	f675                	bnez	a2,80000f88 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f9e:	4501                	li	a0,0
    80000fa0:	a809                	j	80000fb2 <strncmp+0x32>
    80000fa2:	4501                	li	a0,0
    80000fa4:	a039                	j	80000fb2 <strncmp+0x32>
  if(n == 0)
    80000fa6:	ca09                	beqz	a2,80000fb8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000fa8:	00054503          	lbu	a0,0(a0)
    80000fac:	0005c783          	lbu	a5,0(a1)
    80000fb0:	9d1d                	subw	a0,a0,a5
}
    80000fb2:	6422                	ld	s0,8(sp)
    80000fb4:	0141                	addi	sp,sp,16
    80000fb6:	8082                	ret
    return 0;
    80000fb8:	4501                	li	a0,0
    80000fba:	bfe5                	j	80000fb2 <strncmp+0x32>

0000000080000fbc <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e422                	sd	s0,8(sp)
    80000fc0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fc2:	872a                	mv	a4,a0
    80000fc4:	8832                	mv	a6,a2
    80000fc6:	367d                	addiw	a2,a2,-1
    80000fc8:	01005963          	blez	a6,80000fda <strncpy+0x1e>
    80000fcc:	0705                	addi	a4,a4,1
    80000fce:	0005c783          	lbu	a5,0(a1)
    80000fd2:	fef70fa3          	sb	a5,-1(a4)
    80000fd6:	0585                	addi	a1,a1,1
    80000fd8:	f7f5                	bnez	a5,80000fc4 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fda:	00c05d63          	blez	a2,80000ff4 <strncpy+0x38>
    80000fde:	86ba                	mv	a3,a4
    *s++ = 0;
    80000fe0:	0685                	addi	a3,a3,1
    80000fe2:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000fe6:	fff6c793          	not	a5,a3
    80000fea:	9fb9                	addw	a5,a5,a4
    80000fec:	010787bb          	addw	a5,a5,a6
    80000ff0:	fef048e3          	bgtz	a5,80000fe0 <strncpy+0x24>
  return os;
}
    80000ff4:	6422                	ld	s0,8(sp)
    80000ff6:	0141                	addi	sp,sp,16
    80000ff8:	8082                	ret

0000000080000ffa <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ffa:	1141                	addi	sp,sp,-16
    80000ffc:	e422                	sd	s0,8(sp)
    80000ffe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001000:	02c05363          	blez	a2,80001026 <safestrcpy+0x2c>
    80001004:	fff6069b          	addiw	a3,a2,-1
    80001008:	1682                	slli	a3,a3,0x20
    8000100a:	9281                	srli	a3,a3,0x20
    8000100c:	96ae                	add	a3,a3,a1
    8000100e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001010:	00d58963          	beq	a1,a3,80001022 <safestrcpy+0x28>
    80001014:	0585                	addi	a1,a1,1
    80001016:	0785                	addi	a5,a5,1
    80001018:	fff5c703          	lbu	a4,-1(a1)
    8000101c:	fee78fa3          	sb	a4,-1(a5)
    80001020:	fb65                	bnez	a4,80001010 <safestrcpy+0x16>
    ;
  *s = 0;
    80001022:	00078023          	sb	zero,0(a5)
  return os;
}
    80001026:	6422                	ld	s0,8(sp)
    80001028:	0141                	addi	sp,sp,16
    8000102a:	8082                	ret

000000008000102c <strlen>:

int
strlen(const char *s)
{
    8000102c:	1141                	addi	sp,sp,-16
    8000102e:	e422                	sd	s0,8(sp)
    80001030:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001032:	00054783          	lbu	a5,0(a0)
    80001036:	cf91                	beqz	a5,80001052 <strlen+0x26>
    80001038:	0505                	addi	a0,a0,1
    8000103a:	87aa                	mv	a5,a0
    8000103c:	4685                	li	a3,1
    8000103e:	9e89                	subw	a3,a3,a0
    80001040:	00f6853b          	addw	a0,a3,a5
    80001044:	0785                	addi	a5,a5,1
    80001046:	fff7c703          	lbu	a4,-1(a5)
    8000104a:	fb7d                	bnez	a4,80001040 <strlen+0x14>
    ;
  return n;
}
    8000104c:	6422                	ld	s0,8(sp)
    8000104e:	0141                	addi	sp,sp,16
    80001050:	8082                	ret
  for(n = 0; s[n]; n++)
    80001052:	4501                	li	a0,0
    80001054:	bfe5                	j	8000104c <strlen+0x20>

0000000080001056 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001056:	1141                	addi	sp,sp,-16
    80001058:	e406                	sd	ra,8(sp)
    8000105a:	e022                	sd	s0,0(sp)
    8000105c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000105e:	00001097          	auipc	ra,0x1
    80001062:	bf0080e7          	jalr	-1040(ra) # 80001c4e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001066:	00008717          	auipc	a4,0x8
    8000106a:	fa670713          	addi	a4,a4,-90 # 8000900c <started>
  if(cpuid() == 0){
    8000106e:	c139                	beqz	a0,800010b4 <main+0x5e>
    while(started == 0)
    80001070:	431c                	lw	a5,0(a4)
    80001072:	2781                	sext.w	a5,a5
    80001074:	dff5                	beqz	a5,80001070 <main+0x1a>
      ;
    __sync_synchronize();
    80001076:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000107a:	00001097          	auipc	ra,0x1
    8000107e:	bd4080e7          	jalr	-1068(ra) # 80001c4e <cpuid>
    80001082:	85aa                	mv	a1,a0
    80001084:	00007517          	auipc	a0,0x7
    80001088:	03c50513          	addi	a0,a0,60 # 800080c0 <digits+0x80>
    8000108c:	fffff097          	auipc	ra,0xfffff
    80001090:	514080e7          	jalr	1300(ra) # 800005a0 <printf>
    kvminithart();    // turn on paging
    80001094:	00000097          	auipc	ra,0x0
    80001098:	0d8080e7          	jalr	216(ra) # 8000116c <kvminithart>
    trapinithart();   // install kernel trap vector
    8000109c:	00002097          	auipc	ra,0x2
    800010a0:	83c080e7          	jalr	-1988(ra) # 800028d8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800010a4:	00005097          	auipc	ra,0x5
    800010a8:	e28080e7          	jalr	-472(ra) # 80005ecc <plicinithart>
  }

  scheduler();        
    800010ac:	00001097          	auipc	ra,0x1
    800010b0:	0fe080e7          	jalr	254(ra) # 800021aa <scheduler>
    consoleinit();
    800010b4:	fffff097          	auipc	ra,0xfffff
    800010b8:	3b4080e7          	jalr	948(ra) # 80000468 <consoleinit>
    printfinit();
    800010bc:	fffff097          	auipc	ra,0xfffff
    800010c0:	6ca080e7          	jalr	1738(ra) # 80000786 <printfinit>
    printf("\n");
    800010c4:	00007517          	auipc	a0,0x7
    800010c8:	00c50513          	addi	a0,a0,12 # 800080d0 <digits+0x90>
    800010cc:	fffff097          	auipc	ra,0xfffff
    800010d0:	4d4080e7          	jalr	1236(ra) # 800005a0 <printf>
    printf("xv6 kernel is booting\n");
    800010d4:	00007517          	auipc	a0,0x7
    800010d8:	fd450513          	addi	a0,a0,-44 # 800080a8 <digits+0x68>
    800010dc:	fffff097          	auipc	ra,0xfffff
    800010e0:	4c4080e7          	jalr	1220(ra) # 800005a0 <printf>
    printf("\n");
    800010e4:	00007517          	auipc	a0,0x7
    800010e8:	fec50513          	addi	a0,a0,-20 # 800080d0 <digits+0x90>
    800010ec:	fffff097          	auipc	ra,0xfffff
    800010f0:	4b4080e7          	jalr	1204(ra) # 800005a0 <printf>
    kinit();         // physical page allocator
    800010f4:	00000097          	auipc	ra,0x0
    800010f8:	a50080e7          	jalr	-1456(ra) # 80000b44 <kinit>
    kvminit();       // create kernel page table
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	2a0080e7          	jalr	672(ra) # 8000139c <kvminit>
    kvminithart();   // turn on paging
    80001104:	00000097          	auipc	ra,0x0
    80001108:	068080e7          	jalr	104(ra) # 8000116c <kvminithart>
    procinit();      // process table
    8000110c:	00001097          	auipc	ra,0x1
    80001110:	a72080e7          	jalr	-1422(ra) # 80001b7e <procinit>
    trapinit();      // trap vectors
    80001114:	00001097          	auipc	ra,0x1
    80001118:	79c080e7          	jalr	1948(ra) # 800028b0 <trapinit>
    trapinithart();  // install kernel trap vector
    8000111c:	00001097          	auipc	ra,0x1
    80001120:	7bc080e7          	jalr	1980(ra) # 800028d8 <trapinithart>
    plicinit();      // set up interrupt controller
    80001124:	00005097          	auipc	ra,0x5
    80001128:	d92080e7          	jalr	-622(ra) # 80005eb6 <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000112c:	00005097          	auipc	ra,0x5
    80001130:	da0080e7          	jalr	-608(ra) # 80005ecc <plicinithart>
    binit();         // buffer cache
    80001134:	00002097          	auipc	ra,0x2
    80001138:	f20080e7          	jalr	-224(ra) # 80003054 <binit>
    iinit();         // inode cache
    8000113c:	00002097          	auipc	ra,0x2
    80001140:	5b0080e7          	jalr	1456(ra) # 800036ec <iinit>
    fileinit();      // file table
    80001144:	00003097          	auipc	ra,0x3
    80001148:	54e080e7          	jalr	1358(ra) # 80004692 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000114c:	00005097          	auipc	ra,0x5
    80001150:	e88080e7          	jalr	-376(ra) # 80005fd4 <virtio_disk_init>
    userinit();      // first user process
    80001154:	00001097          	auipc	ra,0x1
    80001158:	df0080e7          	jalr	-528(ra) # 80001f44 <userinit>
    __sync_synchronize();
    8000115c:	0ff0000f          	fence
    started = 1;
    80001160:	4785                	li	a5,1
    80001162:	00008717          	auipc	a4,0x8
    80001166:	eaf72523          	sw	a5,-342(a4) # 8000900c <started>
    8000116a:	b789                	j	800010ac <main+0x56>

000000008000116c <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000116c:	1141                	addi	sp,sp,-16
    8000116e:	e422                	sd	s0,8(sp)
    80001170:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001172:	00008797          	auipc	a5,0x8
    80001176:	e9e7b783          	ld	a5,-354(a5) # 80009010 <kernel_pagetable>
    8000117a:	83b1                	srli	a5,a5,0xc
    8000117c:	577d                	li	a4,-1
    8000117e:	177e                	slli	a4,a4,0x3f
    80001180:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001182:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001186:	12000073          	sfence.vma
  sfence_vma();
}
    8000118a:	6422                	ld	s0,8(sp)
    8000118c:	0141                	addi	sp,sp,16
    8000118e:	8082                	ret

0000000080001190 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001190:	7139                	addi	sp,sp,-64
    80001192:	fc06                	sd	ra,56(sp)
    80001194:	f822                	sd	s0,48(sp)
    80001196:	f426                	sd	s1,40(sp)
    80001198:	f04a                	sd	s2,32(sp)
    8000119a:	ec4e                	sd	s3,24(sp)
    8000119c:	e852                	sd	s4,16(sp)
    8000119e:	e456                	sd	s5,8(sp)
    800011a0:	e05a                	sd	s6,0(sp)
    800011a2:	0080                	addi	s0,sp,64
    800011a4:	84aa                	mv	s1,a0
    800011a6:	89ae                	mv	s3,a1
    800011a8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800011aa:	57fd                	li	a5,-1
    800011ac:	83e9                	srli	a5,a5,0x1a
    800011ae:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011b0:	4b31                	li	s6,12
  if(va >= MAXVA)
    800011b2:	04b7f263          	bgeu	a5,a1,800011f6 <walk+0x66>
    panic("walk");
    800011b6:	00007517          	auipc	a0,0x7
    800011ba:	f2250513          	addi	a0,a0,-222 # 800080d8 <digits+0x98>
    800011be:	fffff097          	auipc	ra,0xfffff
    800011c2:	398080e7          	jalr	920(ra) # 80000556 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011c6:	060a8663          	beqz	s5,80001232 <walk+0xa2>
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	9ce080e7          	jalr	-1586(ra) # 80000b98 <kalloc>
    800011d2:	84aa                	mv	s1,a0
    800011d4:	c529                	beqz	a0,8000121e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011d6:	6605                	lui	a2,0x1
    800011d8:	4581                	li	a1,0
    800011da:	00000097          	auipc	ra,0x0
    800011de:	cca080e7          	jalr	-822(ra) # 80000ea4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011e2:	00c4d793          	srli	a5,s1,0xc
    800011e6:	07aa                	slli	a5,a5,0xa
    800011e8:	0017e793          	ori	a5,a5,1
    800011ec:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011f0:	3a5d                	addiw	s4,s4,-9
    800011f2:	036a0063          	beq	s4,s6,80001212 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011f6:	0149d933          	srl	s2,s3,s4
    800011fa:	1ff97913          	andi	s2,s2,511
    800011fe:	090e                	slli	s2,s2,0x3
    80001200:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001202:	00093483          	ld	s1,0(s2)
    80001206:	0014f793          	andi	a5,s1,1
    8000120a:	dfd5                	beqz	a5,800011c6 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000120c:	80a9                	srli	s1,s1,0xa
    8000120e:	04b2                	slli	s1,s1,0xc
    80001210:	b7c5                	j	800011f0 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001212:	00c9d513          	srli	a0,s3,0xc
    80001216:	1ff57513          	andi	a0,a0,511
    8000121a:	050e                	slli	a0,a0,0x3
    8000121c:	9526                	add	a0,a0,s1
}
    8000121e:	70e2                	ld	ra,56(sp)
    80001220:	7442                	ld	s0,48(sp)
    80001222:	74a2                	ld	s1,40(sp)
    80001224:	7902                	ld	s2,32(sp)
    80001226:	69e2                	ld	s3,24(sp)
    80001228:	6a42                	ld	s4,16(sp)
    8000122a:	6aa2                	ld	s5,8(sp)
    8000122c:	6b02                	ld	s6,0(sp)
    8000122e:	6121                	addi	sp,sp,64
    80001230:	8082                	ret
        return 0;
    80001232:	4501                	li	a0,0
    80001234:	b7ed                	j	8000121e <walk+0x8e>

0000000080001236 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001236:	57fd                	li	a5,-1
    80001238:	83e9                	srli	a5,a5,0x1a
    8000123a:	00b7f463          	bgeu	a5,a1,80001242 <walkaddr+0xc>
    return 0;
    8000123e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001240:	8082                	ret
{
    80001242:	1141                	addi	sp,sp,-16
    80001244:	e406                	sd	ra,8(sp)
    80001246:	e022                	sd	s0,0(sp)
    80001248:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000124a:	4601                	li	a2,0
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f44080e7          	jalr	-188(ra) # 80001190 <walk>
  if(pte == 0)
    80001254:	c105                	beqz	a0,80001274 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001256:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001258:	0117f693          	andi	a3,a5,17
    8000125c:	4745                	li	a4,17
    return 0;
    8000125e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001260:	00e68663          	beq	a3,a4,8000126c <walkaddr+0x36>
}
    80001264:	60a2                	ld	ra,8(sp)
    80001266:	6402                	ld	s0,0(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret
  pa = PTE2PA(*pte);
    8000126c:	00a7d513          	srli	a0,a5,0xa
    80001270:	0532                	slli	a0,a0,0xc
  return pa;
    80001272:	bfcd                	j	80001264 <walkaddr+0x2e>
    return 0;
    80001274:	4501                	li	a0,0
    80001276:	b7fd                	j	80001264 <walkaddr+0x2e>

0000000080001278 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001278:	1101                	addi	sp,sp,-32
    8000127a:	ec06                	sd	ra,24(sp)
    8000127c:	e822                	sd	s0,16(sp)
    8000127e:	e426                	sd	s1,8(sp)
    80001280:	1000                	addi	s0,sp,32
    80001282:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001284:	1552                	slli	a0,a0,0x34
    80001286:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000128a:	4601                	li	a2,0
    8000128c:	00008517          	auipc	a0,0x8
    80001290:	d8453503          	ld	a0,-636(a0) # 80009010 <kernel_pagetable>
    80001294:	00000097          	auipc	ra,0x0
    80001298:	efc080e7          	jalr	-260(ra) # 80001190 <walk>
  if(pte == 0)
    8000129c:	cd09                	beqz	a0,800012b6 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000129e:	6108                	ld	a0,0(a0)
    800012a0:	00157793          	andi	a5,a0,1
    800012a4:	c38d                	beqz	a5,800012c6 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800012a6:	8129                	srli	a0,a0,0xa
    800012a8:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800012aa:	9526                	add	a0,a0,s1
    800012ac:	60e2                	ld	ra,24(sp)
    800012ae:	6442                	ld	s0,16(sp)
    800012b0:	64a2                	ld	s1,8(sp)
    800012b2:	6105                	addi	sp,sp,32
    800012b4:	8082                	ret
    panic("kvmpa");
    800012b6:	00007517          	auipc	a0,0x7
    800012ba:	e2a50513          	addi	a0,a0,-470 # 800080e0 <digits+0xa0>
    800012be:	fffff097          	auipc	ra,0xfffff
    800012c2:	298080e7          	jalr	664(ra) # 80000556 <panic>
    panic("kvmpa");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e1a50513          	addi	a0,a0,-486 # 800080e0 <digits+0xa0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	288080e7          	jalr	648(ra) # 80000556 <panic>

00000000800012d6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012d6:	715d                	addi	sp,sp,-80
    800012d8:	e486                	sd	ra,72(sp)
    800012da:	e0a2                	sd	s0,64(sp)
    800012dc:	fc26                	sd	s1,56(sp)
    800012de:	f84a                	sd	s2,48(sp)
    800012e0:	f44e                	sd	s3,40(sp)
    800012e2:	f052                	sd	s4,32(sp)
    800012e4:	ec56                	sd	s5,24(sp)
    800012e6:	e85a                	sd	s6,16(sp)
    800012e8:	e45e                	sd	s7,8(sp)
    800012ea:	0880                	addi	s0,sp,80
    800012ec:	8aaa                	mv	s5,a0
    800012ee:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800012f0:	777d                	lui	a4,0xfffff
    800012f2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800012f6:	167d                	addi	a2,a2,-1
    800012f8:	00b609b3          	add	s3,a2,a1
    800012fc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001300:	893e                	mv	s2,a5
    80001302:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001306:	6b85                	lui	s7,0x1
    80001308:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000130c:	4605                	li	a2,1
    8000130e:	85ca                	mv	a1,s2
    80001310:	8556                	mv	a0,s5
    80001312:	00000097          	auipc	ra,0x0
    80001316:	e7e080e7          	jalr	-386(ra) # 80001190 <walk>
    8000131a:	c51d                	beqz	a0,80001348 <mappages+0x72>
    if(*pte & PTE_V)
    8000131c:	611c                	ld	a5,0(a0)
    8000131e:	8b85                	andi	a5,a5,1
    80001320:	ef81                	bnez	a5,80001338 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001322:	80b1                	srli	s1,s1,0xc
    80001324:	04aa                	slli	s1,s1,0xa
    80001326:	0164e4b3          	or	s1,s1,s6
    8000132a:	0014e493          	ori	s1,s1,1
    8000132e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001330:	03390863          	beq	s2,s3,80001360 <mappages+0x8a>
    a += PGSIZE;
    80001334:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001336:	bfc9                	j	80001308 <mappages+0x32>
      panic("remap");
    80001338:	00007517          	auipc	a0,0x7
    8000133c:	db050513          	addi	a0,a0,-592 # 800080e8 <digits+0xa8>
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	216080e7          	jalr	534(ra) # 80000556 <panic>
      return -1;
    80001348:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000134a:	60a6                	ld	ra,72(sp)
    8000134c:	6406                	ld	s0,64(sp)
    8000134e:	74e2                	ld	s1,56(sp)
    80001350:	7942                	ld	s2,48(sp)
    80001352:	79a2                	ld	s3,40(sp)
    80001354:	7a02                	ld	s4,32(sp)
    80001356:	6ae2                	ld	s5,24(sp)
    80001358:	6b42                	ld	s6,16(sp)
    8000135a:	6ba2                	ld	s7,8(sp)
    8000135c:	6161                	addi	sp,sp,80
    8000135e:	8082                	ret
  return 0;
    80001360:	4501                	li	a0,0
    80001362:	b7e5                	j	8000134a <mappages+0x74>

0000000080001364 <kvmmap>:
{
    80001364:	1141                	addi	sp,sp,-16
    80001366:	e406                	sd	ra,8(sp)
    80001368:	e022                	sd	s0,0(sp)
    8000136a:	0800                	addi	s0,sp,16
    8000136c:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000136e:	86ae                	mv	a3,a1
    80001370:	85aa                	mv	a1,a0
    80001372:	00008517          	auipc	a0,0x8
    80001376:	c9e53503          	ld	a0,-866(a0) # 80009010 <kernel_pagetable>
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	f5c080e7          	jalr	-164(ra) # 800012d6 <mappages>
    80001382:	e509                	bnez	a0,8000138c <kvmmap+0x28>
}
    80001384:	60a2                	ld	ra,8(sp)
    80001386:	6402                	ld	s0,0(sp)
    80001388:	0141                	addi	sp,sp,16
    8000138a:	8082                	ret
    panic("kvmmap");
    8000138c:	00007517          	auipc	a0,0x7
    80001390:	d6450513          	addi	a0,a0,-668 # 800080f0 <digits+0xb0>
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	1c2080e7          	jalr	450(ra) # 80000556 <panic>

000000008000139c <kvminit>:
{
    8000139c:	1101                	addi	sp,sp,-32
    8000139e:	ec06                	sd	ra,24(sp)
    800013a0:	e822                	sd	s0,16(sp)
    800013a2:	e426                	sd	s1,8(sp)
    800013a4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800013a6:	fffff097          	auipc	ra,0xfffff
    800013aa:	7f2080e7          	jalr	2034(ra) # 80000b98 <kalloc>
    800013ae:	00008797          	auipc	a5,0x8
    800013b2:	c6a7b123          	sd	a0,-926(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	aea080e7          	jalr	-1302(ra) # 80000ea4 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013c2:	4699                	li	a3,6
    800013c4:	6605                	lui	a2,0x1
    800013c6:	100005b7          	lui	a1,0x10000
    800013ca:	10000537          	lui	a0,0x10000
    800013ce:	00000097          	auipc	ra,0x0
    800013d2:	f96080e7          	jalr	-106(ra) # 80001364 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800013d6:	4699                	li	a3,6
    800013d8:	6605                	lui	a2,0x1
    800013da:	100015b7          	lui	a1,0x10001
    800013de:	10001537          	lui	a0,0x10001
    800013e2:	00000097          	auipc	ra,0x0
    800013e6:	f82080e7          	jalr	-126(ra) # 80001364 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800013ea:	4699                	li	a3,6
    800013ec:	6641                	lui	a2,0x10
    800013ee:	020005b7          	lui	a1,0x2000
    800013f2:	02000537          	lui	a0,0x2000
    800013f6:	00000097          	auipc	ra,0x0
    800013fa:	f6e080e7          	jalr	-146(ra) # 80001364 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013fe:	4699                	li	a3,6
    80001400:	00400637          	lui	a2,0x400
    80001404:	0c0005b7          	lui	a1,0xc000
    80001408:	0c000537          	lui	a0,0xc000
    8000140c:	00000097          	auipc	ra,0x0
    80001410:	f58080e7          	jalr	-168(ra) # 80001364 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001414:	00007497          	auipc	s1,0x7
    80001418:	bec48493          	addi	s1,s1,-1044 # 80008000 <etext>
    8000141c:	46a9                	li	a3,10
    8000141e:	80007617          	auipc	a2,0x80007
    80001422:	be260613          	addi	a2,a2,-1054 # 8000 <_entry-0x7fff8000>
    80001426:	4585                	li	a1,1
    80001428:	05fe                	slli	a1,a1,0x1f
    8000142a:	852e                	mv	a0,a1
    8000142c:	00000097          	auipc	ra,0x0
    80001430:	f38080e7          	jalr	-200(ra) # 80001364 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001434:	4699                	li	a3,6
    80001436:	4645                	li	a2,17
    80001438:	066e                	slli	a2,a2,0x1b
    8000143a:	8e05                	sub	a2,a2,s1
    8000143c:	85a6                	mv	a1,s1
    8000143e:	8526                	mv	a0,s1
    80001440:	00000097          	auipc	ra,0x0
    80001444:	f24080e7          	jalr	-220(ra) # 80001364 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001448:	46a9                	li	a3,10
    8000144a:	6605                	lui	a2,0x1
    8000144c:	00006597          	auipc	a1,0x6
    80001450:	bb458593          	addi	a1,a1,-1100 # 80007000 <_trampoline>
    80001454:	04000537          	lui	a0,0x4000
    80001458:	157d                	addi	a0,a0,-1
    8000145a:	0532                	slli	a0,a0,0xc
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	f08080e7          	jalr	-248(ra) # 80001364 <kvmmap>
}
    80001464:	60e2                	ld	ra,24(sp)
    80001466:	6442                	ld	s0,16(sp)
    80001468:	64a2                	ld	s1,8(sp)
    8000146a:	6105                	addi	sp,sp,32
    8000146c:	8082                	ret

000000008000146e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000146e:	715d                	addi	sp,sp,-80
    80001470:	e486                	sd	ra,72(sp)
    80001472:	e0a2                	sd	s0,64(sp)
    80001474:	fc26                	sd	s1,56(sp)
    80001476:	f84a                	sd	s2,48(sp)
    80001478:	f44e                	sd	s3,40(sp)
    8000147a:	f052                	sd	s4,32(sp)
    8000147c:	ec56                	sd	s5,24(sp)
    8000147e:	e85a                	sd	s6,16(sp)
    80001480:	e45e                	sd	s7,8(sp)
    80001482:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001484:	03459793          	slli	a5,a1,0x34
    80001488:	e795                	bnez	a5,800014b4 <uvmunmap+0x46>
    8000148a:	8a2a                	mv	s4,a0
    8000148c:	892e                	mv	s2,a1
    8000148e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001490:	0632                	slli	a2,a2,0xc
    80001492:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001496:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001498:	6b05                	lui	s6,0x1
    8000149a:	0735e863          	bltu	a1,s3,8000150a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000149e:	60a6                	ld	ra,72(sp)
    800014a0:	6406                	ld	s0,64(sp)
    800014a2:	74e2                	ld	s1,56(sp)
    800014a4:	7942                	ld	s2,48(sp)
    800014a6:	79a2                	ld	s3,40(sp)
    800014a8:	7a02                	ld	s4,32(sp)
    800014aa:	6ae2                	ld	s5,24(sp)
    800014ac:	6b42                	ld	s6,16(sp)
    800014ae:	6ba2                	ld	s7,8(sp)
    800014b0:	6161                	addi	sp,sp,80
    800014b2:	8082                	ret
    panic("uvmunmap: not aligned");
    800014b4:	00007517          	auipc	a0,0x7
    800014b8:	c4450513          	addi	a0,a0,-956 # 800080f8 <digits+0xb8>
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	09a080e7          	jalr	154(ra) # 80000556 <panic>
      panic("uvmunmap: walk");
    800014c4:	00007517          	auipc	a0,0x7
    800014c8:	c4c50513          	addi	a0,a0,-948 # 80008110 <digits+0xd0>
    800014cc:	fffff097          	auipc	ra,0xfffff
    800014d0:	08a080e7          	jalr	138(ra) # 80000556 <panic>
      panic("uvmunmap: not mapped");
    800014d4:	00007517          	auipc	a0,0x7
    800014d8:	c4c50513          	addi	a0,a0,-948 # 80008120 <digits+0xe0>
    800014dc:	fffff097          	auipc	ra,0xfffff
    800014e0:	07a080e7          	jalr	122(ra) # 80000556 <panic>
      panic("uvmunmap: not a leaf");
    800014e4:	00007517          	auipc	a0,0x7
    800014e8:	c5450513          	addi	a0,a0,-940 # 80008138 <digits+0xf8>
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	06a080e7          	jalr	106(ra) # 80000556 <panic>
      uint64 pa = PTE2PA(*pte);
    800014f4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014f6:	0532                	slli	a0,a0,0xc
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	53a080e7          	jalr	1338(ra) # 80000a32 <kfree>
    *pte = 0;
    80001500:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001504:	995a                	add	s2,s2,s6
    80001506:	f9397ce3          	bgeu	s2,s3,8000149e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000150a:	4601                	li	a2,0
    8000150c:	85ca                	mv	a1,s2
    8000150e:	8552                	mv	a0,s4
    80001510:	00000097          	auipc	ra,0x0
    80001514:	c80080e7          	jalr	-896(ra) # 80001190 <walk>
    80001518:	84aa                	mv	s1,a0
    8000151a:	d54d                	beqz	a0,800014c4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000151c:	6108                	ld	a0,0(a0)
    8000151e:	00157793          	andi	a5,a0,1
    80001522:	dbcd                	beqz	a5,800014d4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001524:	3ff57793          	andi	a5,a0,1023
    80001528:	fb778ee3          	beq	a5,s7,800014e4 <uvmunmap+0x76>
    if(do_free){
    8000152c:	fc0a8ae3          	beqz	s5,80001500 <uvmunmap+0x92>
    80001530:	b7d1                	j	800014f4 <uvmunmap+0x86>

0000000080001532 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001532:	1101                	addi	sp,sp,-32
    80001534:	ec06                	sd	ra,24(sp)
    80001536:	e822                	sd	s0,16(sp)
    80001538:	e426                	sd	s1,8(sp)
    8000153a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000153c:	fffff097          	auipc	ra,0xfffff
    80001540:	65c080e7          	jalr	1628(ra) # 80000b98 <kalloc>
    80001544:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001546:	c519                	beqz	a0,80001554 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001548:	6605                	lui	a2,0x1
    8000154a:	4581                	li	a1,0
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	958080e7          	jalr	-1704(ra) # 80000ea4 <memset>
  return pagetable;
}
    80001554:	8526                	mv	a0,s1
    80001556:	60e2                	ld	ra,24(sp)
    80001558:	6442                	ld	s0,16(sp)
    8000155a:	64a2                	ld	s1,8(sp)
    8000155c:	6105                	addi	sp,sp,32
    8000155e:	8082                	ret

0000000080001560 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001560:	7179                	addi	sp,sp,-48
    80001562:	f406                	sd	ra,40(sp)
    80001564:	f022                	sd	s0,32(sp)
    80001566:	ec26                	sd	s1,24(sp)
    80001568:	e84a                	sd	s2,16(sp)
    8000156a:	e44e                	sd	s3,8(sp)
    8000156c:	e052                	sd	s4,0(sp)
    8000156e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001570:	6785                	lui	a5,0x1
    80001572:	04f67863          	bgeu	a2,a5,800015c2 <uvminit+0x62>
    80001576:	8a2a                	mv	s4,a0
    80001578:	89ae                	mv	s3,a1
    8000157a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	61c080e7          	jalr	1564(ra) # 80000b98 <kalloc>
    80001584:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001586:	6605                	lui	a2,0x1
    80001588:	4581                	li	a1,0
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	91a080e7          	jalr	-1766(ra) # 80000ea4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001592:	4779                	li	a4,30
    80001594:	86ca                	mv	a3,s2
    80001596:	6605                	lui	a2,0x1
    80001598:	4581                	li	a1,0
    8000159a:	8552                	mv	a0,s4
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	d3a080e7          	jalr	-710(ra) # 800012d6 <mappages>
  memmove(mem, src, sz);
    800015a4:	8626                	mv	a2,s1
    800015a6:	85ce                	mv	a1,s3
    800015a8:	854a                	mv	a0,s2
    800015aa:	00000097          	auipc	ra,0x0
    800015ae:	95a080e7          	jalr	-1702(ra) # 80000f04 <memmove>
}
    800015b2:	70a2                	ld	ra,40(sp)
    800015b4:	7402                	ld	s0,32(sp)
    800015b6:	64e2                	ld	s1,24(sp)
    800015b8:	6942                	ld	s2,16(sp)
    800015ba:	69a2                	ld	s3,8(sp)
    800015bc:	6a02                	ld	s4,0(sp)
    800015be:	6145                	addi	sp,sp,48
    800015c0:	8082                	ret
    panic("inituvm: more than a page");
    800015c2:	00007517          	auipc	a0,0x7
    800015c6:	b8e50513          	addi	a0,a0,-1138 # 80008150 <digits+0x110>
    800015ca:	fffff097          	auipc	ra,0xfffff
    800015ce:	f8c080e7          	jalr	-116(ra) # 80000556 <panic>

00000000800015d2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800015d2:	1101                	addi	sp,sp,-32
    800015d4:	ec06                	sd	ra,24(sp)
    800015d6:	e822                	sd	s0,16(sp)
    800015d8:	e426                	sd	s1,8(sp)
    800015da:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800015dc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015de:	00b67d63          	bgeu	a2,a1,800015f8 <uvmdealloc+0x26>
    800015e2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015e4:	6785                	lui	a5,0x1
    800015e6:	17fd                	addi	a5,a5,-1
    800015e8:	00f60733          	add	a4,a2,a5
    800015ec:	767d                	lui	a2,0xfffff
    800015ee:	8f71                	and	a4,a4,a2
    800015f0:	97ae                	add	a5,a5,a1
    800015f2:	8ff1                	and	a5,a5,a2
    800015f4:	00f76863          	bltu	a4,a5,80001604 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015f8:	8526                	mv	a0,s1
    800015fa:	60e2                	ld	ra,24(sp)
    800015fc:	6442                	ld	s0,16(sp)
    800015fe:	64a2                	ld	s1,8(sp)
    80001600:	6105                	addi	sp,sp,32
    80001602:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001604:	8f99                	sub	a5,a5,a4
    80001606:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001608:	4685                	li	a3,1
    8000160a:	0007861b          	sext.w	a2,a5
    8000160e:	85ba                	mv	a1,a4
    80001610:	00000097          	auipc	ra,0x0
    80001614:	e5e080e7          	jalr	-418(ra) # 8000146e <uvmunmap>
    80001618:	b7c5                	j	800015f8 <uvmdealloc+0x26>

000000008000161a <uvmalloc>:
  if(newsz < oldsz)
    8000161a:	0ab66163          	bltu	a2,a1,800016bc <uvmalloc+0xa2>
{
    8000161e:	7139                	addi	sp,sp,-64
    80001620:	fc06                	sd	ra,56(sp)
    80001622:	f822                	sd	s0,48(sp)
    80001624:	f426                	sd	s1,40(sp)
    80001626:	f04a                	sd	s2,32(sp)
    80001628:	ec4e                	sd	s3,24(sp)
    8000162a:	e852                	sd	s4,16(sp)
    8000162c:	e456                	sd	s5,8(sp)
    8000162e:	0080                	addi	s0,sp,64
    80001630:	8aaa                	mv	s5,a0
    80001632:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001634:	6985                	lui	s3,0x1
    80001636:	19fd                	addi	s3,s3,-1
    80001638:	95ce                	add	a1,a1,s3
    8000163a:	79fd                	lui	s3,0xfffff
    8000163c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001640:	08c9f063          	bgeu	s3,a2,800016c0 <uvmalloc+0xa6>
    80001644:	894e                	mv	s2,s3
    mem = kalloc();
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	552080e7          	jalr	1362(ra) # 80000b98 <kalloc>
    8000164e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001650:	c51d                	beqz	a0,8000167e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001652:	6605                	lui	a2,0x1
    80001654:	4581                	li	a1,0
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	84e080e7          	jalr	-1970(ra) # 80000ea4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000165e:	4779                	li	a4,30
    80001660:	86a6                	mv	a3,s1
    80001662:	6605                	lui	a2,0x1
    80001664:	85ca                	mv	a1,s2
    80001666:	8556                	mv	a0,s5
    80001668:	00000097          	auipc	ra,0x0
    8000166c:	c6e080e7          	jalr	-914(ra) # 800012d6 <mappages>
    80001670:	e905                	bnez	a0,800016a0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001672:	6785                	lui	a5,0x1
    80001674:	993e                	add	s2,s2,a5
    80001676:	fd4968e3          	bltu	s2,s4,80001646 <uvmalloc+0x2c>
  return newsz;
    8000167a:	8552                	mv	a0,s4
    8000167c:	a809                	j	8000168e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000167e:	864e                	mv	a2,s3
    80001680:	85ca                	mv	a1,s2
    80001682:	8556                	mv	a0,s5
    80001684:	00000097          	auipc	ra,0x0
    80001688:	f4e080e7          	jalr	-178(ra) # 800015d2 <uvmdealloc>
      return 0;
    8000168c:	4501                	li	a0,0
}
    8000168e:	70e2                	ld	ra,56(sp)
    80001690:	7442                	ld	s0,48(sp)
    80001692:	74a2                	ld	s1,40(sp)
    80001694:	7902                	ld	s2,32(sp)
    80001696:	69e2                	ld	s3,24(sp)
    80001698:	6a42                	ld	s4,16(sp)
    8000169a:	6aa2                	ld	s5,8(sp)
    8000169c:	6121                	addi	sp,sp,64
    8000169e:	8082                	ret
      kfree(mem);
    800016a0:	8526                	mv	a0,s1
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	390080e7          	jalr	912(ra) # 80000a32 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016aa:	864e                	mv	a2,s3
    800016ac:	85ca                	mv	a1,s2
    800016ae:	8556                	mv	a0,s5
    800016b0:	00000097          	auipc	ra,0x0
    800016b4:	f22080e7          	jalr	-222(ra) # 800015d2 <uvmdealloc>
      return 0;
    800016b8:	4501                	li	a0,0
    800016ba:	bfd1                	j	8000168e <uvmalloc+0x74>
    return oldsz;
    800016bc:	852e                	mv	a0,a1
}
    800016be:	8082                	ret
  return newsz;
    800016c0:	8532                	mv	a0,a2
    800016c2:	b7f1                	j	8000168e <uvmalloc+0x74>

00000000800016c4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800016c4:	7179                	addi	sp,sp,-48
    800016c6:	f406                	sd	ra,40(sp)
    800016c8:	f022                	sd	s0,32(sp)
    800016ca:	ec26                	sd	s1,24(sp)
    800016cc:	e84a                	sd	s2,16(sp)
    800016ce:	e44e                	sd	s3,8(sp)
    800016d0:	e052                	sd	s4,0(sp)
    800016d2:	1800                	addi	s0,sp,48
    800016d4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800016d6:	84aa                	mv	s1,a0
    800016d8:	6905                	lui	s2,0x1
    800016da:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016dc:	4985                	li	s3,1
    800016de:	a821                	j	800016f6 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016e0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800016e2:	0532                	slli	a0,a0,0xc
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	fe0080e7          	jalr	-32(ra) # 800016c4 <freewalk>
      pagetable[i] = 0;
    800016ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016f0:	04a1                	addi	s1,s1,8
    800016f2:	03248163          	beq	s1,s2,80001714 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800016f6:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016f8:	00f57793          	andi	a5,a0,15
    800016fc:	ff3782e3          	beq	a5,s3,800016e0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001700:	8905                	andi	a0,a0,1
    80001702:	d57d                	beqz	a0,800016f0 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001704:	00007517          	auipc	a0,0x7
    80001708:	a6c50513          	addi	a0,a0,-1428 # 80008170 <digits+0x130>
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	e4a080e7          	jalr	-438(ra) # 80000556 <panic>
    }
  }
  kfree((void*)pagetable);
    80001714:	8552                	mv	a0,s4
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	31c080e7          	jalr	796(ra) # 80000a32 <kfree>
}
    8000171e:	70a2                	ld	ra,40(sp)
    80001720:	7402                	ld	s0,32(sp)
    80001722:	64e2                	ld	s1,24(sp)
    80001724:	6942                	ld	s2,16(sp)
    80001726:	69a2                	ld	s3,8(sp)
    80001728:	6a02                	ld	s4,0(sp)
    8000172a:	6145                	addi	sp,sp,48
    8000172c:	8082                	ret

000000008000172e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000172e:	1101                	addi	sp,sp,-32
    80001730:	ec06                	sd	ra,24(sp)
    80001732:	e822                	sd	s0,16(sp)
    80001734:	e426                	sd	s1,8(sp)
    80001736:	1000                	addi	s0,sp,32
    80001738:	84aa                	mv	s1,a0
  if(sz > 0)
    8000173a:	e999                	bnez	a1,80001750 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000173c:	8526                	mv	a0,s1
    8000173e:	00000097          	auipc	ra,0x0
    80001742:	f86080e7          	jalr	-122(ra) # 800016c4 <freewalk>
}
    80001746:	60e2                	ld	ra,24(sp)
    80001748:	6442                	ld	s0,16(sp)
    8000174a:	64a2                	ld	s1,8(sp)
    8000174c:	6105                	addi	sp,sp,32
    8000174e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001750:	6605                	lui	a2,0x1
    80001752:	167d                	addi	a2,a2,-1
    80001754:	962e                	add	a2,a2,a1
    80001756:	4685                	li	a3,1
    80001758:	8231                	srli	a2,a2,0xc
    8000175a:	4581                	li	a1,0
    8000175c:	00000097          	auipc	ra,0x0
    80001760:	d12080e7          	jalr	-750(ra) # 8000146e <uvmunmap>
    80001764:	bfe1                	j	8000173c <uvmfree+0xe>

0000000080001766 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001766:	7139                	addi	sp,sp,-64
    80001768:	fc06                	sd	ra,56(sp)
    8000176a:	f822                	sd	s0,48(sp)
    8000176c:	f426                	sd	s1,40(sp)
    8000176e:	f04a                	sd	s2,32(sp)
    80001770:	ec4e                	sd	s3,24(sp)
    80001772:	e852                	sd	s4,16(sp)
    80001774:	e456                	sd	s5,8(sp)
    80001776:	e05a                	sd	s6,0(sp)
    80001778:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  // char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000177a:	c645                	beqz	a2,80001822 <uvmcopy+0xbc>
    8000177c:	8aaa                	mv	s5,a0
    8000177e:	8a2e                	mv	s4,a1
    80001780:	89b2                	mv	s3,a2
    80001782:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    80001784:	4601                	li	a2,0
    80001786:	85a6                	mv	a1,s1
    80001788:	8556                	mv	a0,s5
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	a06080e7          	jalr	-1530(ra) # 80001190 <walk>
    80001792:	c139                	beqz	a0,800017d8 <uvmcopy+0x72>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001794:	6118                	ld	a4,0(a0)
    80001796:	00177793          	andi	a5,a4,1
    8000179a:	c7b9                	beqz	a5,800017e8 <uvmcopy+0x82>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000179c:	00a75913          	srli	s2,a4,0xa
    800017a0:	0932                	slli	s2,s2,0xc
    // clear out PTE_W for parent, set PTE_COW
    *pte = (*pte & ~PTE_W) | PTE_COW;
    800017a2:	efb77713          	andi	a4,a4,-261
    800017a6:	10076713          	ori	a4,a4,256
    800017aa:	e118                	sd	a4,0(a0)
    flags = PTE_FLAGS(*pte);
    // map physical page of parent directly to child (copy-on-write)
    // since the write flag has already been cleared for the parent
    // the child mapping won't have the write flag as well.
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    800017ac:	3fb77713          	andi	a4,a4,1019
    800017b0:	86ca                	mv	a3,s2
    800017b2:	6605                	lui	a2,0x1
    800017b4:	85a6                	mv	a1,s1
    800017b6:	8552                	mv	a0,s4
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	b1e080e7          	jalr	-1250(ra) # 800012d6 <mappages>
    800017c0:	8b2a                	mv	s6,a0
    800017c2:	e91d                	bnez	a0,800017f8 <uvmcopy+0x92>
      goto err;
    }
    // increase reference count of the page by one (for the child)
    krefpage((void*)pa);
    800017c4:	854a                	mv	a0,s2
    800017c6:	fffff097          	auipc	ra,0xfffff
    800017ca:	502080e7          	jalr	1282(ra) # 80000cc8 <krefpage>
  for(i = 0; i < sz; i += PGSIZE){
    800017ce:	6785                	lui	a5,0x1
    800017d0:	94be                	add	s1,s1,a5
    800017d2:	fb34e9e3          	bltu	s1,s3,80001784 <uvmcopy+0x1e>
    800017d6:	a81d                	j	8000180c <uvmcopy+0xa6>
      panic("uvmcopy: pte should exist");
    800017d8:	00007517          	auipc	a0,0x7
    800017dc:	9a850513          	addi	a0,a0,-1624 # 80008180 <digits+0x140>
    800017e0:	fffff097          	auipc	ra,0xfffff
    800017e4:	d76080e7          	jalr	-650(ra) # 80000556 <panic>
      panic("uvmcopy: page not present");
    800017e8:	00007517          	auipc	a0,0x7
    800017ec:	9b850513          	addi	a0,a0,-1608 # 800081a0 <digits+0x160>
    800017f0:	fffff097          	auipc	ra,0xfffff
    800017f4:	d66080e7          	jalr	-666(ra) # 80000556 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017f8:	4685                	li	a3,1
    800017fa:	00c4d613          	srli	a2,s1,0xc
    800017fe:	4581                	li	a1,0
    80001800:	8552                	mv	a0,s4
    80001802:	00000097          	auipc	ra,0x0
    80001806:	c6c080e7          	jalr	-916(ra) # 8000146e <uvmunmap>
  return -1;
    8000180a:	5b7d                	li	s6,-1
}
    8000180c:	855a                	mv	a0,s6
    8000180e:	70e2                	ld	ra,56(sp)
    80001810:	7442                	ld	s0,48(sp)
    80001812:	74a2                	ld	s1,40(sp)
    80001814:	7902                	ld	s2,32(sp)
    80001816:	69e2                	ld	s3,24(sp)
    80001818:	6a42                	ld	s4,16(sp)
    8000181a:	6aa2                	ld	s5,8(sp)
    8000181c:	6b02                	ld	s6,0(sp)
    8000181e:	6121                	addi	sp,sp,64
    80001820:	8082                	ret
  return 0;
    80001822:	4b01                	li	s6,0
    80001824:	b7e5                	j	8000180c <uvmcopy+0xa6>

0000000080001826 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001826:	1141                	addi	sp,sp,-16
    80001828:	e406                	sd	ra,8(sp)
    8000182a:	e022                	sd	s0,0(sp)
    8000182c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000182e:	4601                	li	a2,0
    80001830:	00000097          	auipc	ra,0x0
    80001834:	960080e7          	jalr	-1696(ra) # 80001190 <walk>
  if(pte == 0)
    80001838:	c901                	beqz	a0,80001848 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000183a:	611c                	ld	a5,0(a0)
    8000183c:	9bbd                	andi	a5,a5,-17
    8000183e:	e11c                	sd	a5,0(a0)
}
    80001840:	60a2                	ld	ra,8(sp)
    80001842:	6402                	ld	s0,0(sp)
    80001844:	0141                	addi	sp,sp,16
    80001846:	8082                	ret
    panic("uvmclear");
    80001848:	00007517          	auipc	a0,0x7
    8000184c:	97850513          	addi	a0,a0,-1672 # 800081c0 <digits+0x180>
    80001850:	fffff097          	auipc	ra,0xfffff
    80001854:	d06080e7          	jalr	-762(ra) # 80000556 <panic>

0000000080001858 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001858:	c6bd                	beqz	a3,800018c6 <copyin+0x6e>
{
    8000185a:	715d                	addi	sp,sp,-80
    8000185c:	e486                	sd	ra,72(sp)
    8000185e:	e0a2                	sd	s0,64(sp)
    80001860:	fc26                	sd	s1,56(sp)
    80001862:	f84a                	sd	s2,48(sp)
    80001864:	f44e                	sd	s3,40(sp)
    80001866:	f052                	sd	s4,32(sp)
    80001868:	ec56                	sd	s5,24(sp)
    8000186a:	e85a                	sd	s6,16(sp)
    8000186c:	e45e                	sd	s7,8(sp)
    8000186e:	e062                	sd	s8,0(sp)
    80001870:	0880                	addi	s0,sp,80
    80001872:	8b2a                	mv	s6,a0
    80001874:	8a2e                	mv	s4,a1
    80001876:	8c32                	mv	s8,a2
    80001878:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000187a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000187c:	6a85                	lui	s5,0x1
    8000187e:	a015                	j	800018a2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001880:	9562                	add	a0,a0,s8
    80001882:	0004861b          	sext.w	a2,s1
    80001886:	412505b3          	sub	a1,a0,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	678080e7          	jalr	1656(ra) # 80000f04 <memmove>

    len -= n;
    80001894:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001898:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000189a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000189e:	02098263          	beqz	s3,800018c2 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018a6:	85ca                	mv	a1,s2
    800018a8:	855a                	mv	a0,s6
    800018aa:	00000097          	auipc	ra,0x0
    800018ae:	98c080e7          	jalr	-1652(ra) # 80001236 <walkaddr>
    if(pa0 == 0)
    800018b2:	cd01                	beqz	a0,800018ca <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018b4:	418904b3          	sub	s1,s2,s8
    800018b8:	94d6                	add	s1,s1,s5
    if(n > len)
    800018ba:	fc99f3e3          	bgeu	s3,s1,80001880 <copyin+0x28>
    800018be:	84ce                	mv	s1,s3
    800018c0:	b7c1                	j	80001880 <copyin+0x28>
  }
  return 0;
    800018c2:	4501                	li	a0,0
    800018c4:	a021                	j	800018cc <copyin+0x74>
    800018c6:	4501                	li	a0,0
}
    800018c8:	8082                	ret
      return -1;
    800018ca:	557d                	li	a0,-1
}
    800018cc:	60a6                	ld	ra,72(sp)
    800018ce:	6406                	ld	s0,64(sp)
    800018d0:	74e2                	ld	s1,56(sp)
    800018d2:	7942                	ld	s2,48(sp)
    800018d4:	79a2                	ld	s3,40(sp)
    800018d6:	7a02                	ld	s4,32(sp)
    800018d8:	6ae2                	ld	s5,24(sp)
    800018da:	6b42                	ld	s6,16(sp)
    800018dc:	6ba2                	ld	s7,8(sp)
    800018de:	6c02                	ld	s8,0(sp)
    800018e0:	6161                	addi	sp,sp,80
    800018e2:	8082                	ret

00000000800018e4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018e4:	c6c5                	beqz	a3,8000198c <copyinstr+0xa8>
{
    800018e6:	715d                	addi	sp,sp,-80
    800018e8:	e486                	sd	ra,72(sp)
    800018ea:	e0a2                	sd	s0,64(sp)
    800018ec:	fc26                	sd	s1,56(sp)
    800018ee:	f84a                	sd	s2,48(sp)
    800018f0:	f44e                	sd	s3,40(sp)
    800018f2:	f052                	sd	s4,32(sp)
    800018f4:	ec56                	sd	s5,24(sp)
    800018f6:	e85a                	sd	s6,16(sp)
    800018f8:	e45e                	sd	s7,8(sp)
    800018fa:	0880                	addi	s0,sp,80
    800018fc:	8a2a                	mv	s4,a0
    800018fe:	8b2e                	mv	s6,a1
    80001900:	8bb2                	mv	s7,a2
    80001902:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001904:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001906:	6985                	lui	s3,0x1
    80001908:	a035                	j	80001934 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000190a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000190e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001910:	0017b793          	seqz	a5,a5
    80001914:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001918:	60a6                	ld	ra,72(sp)
    8000191a:	6406                	ld	s0,64(sp)
    8000191c:	74e2                	ld	s1,56(sp)
    8000191e:	7942                	ld	s2,48(sp)
    80001920:	79a2                	ld	s3,40(sp)
    80001922:	7a02                	ld	s4,32(sp)
    80001924:	6ae2                	ld	s5,24(sp)
    80001926:	6b42                	ld	s6,16(sp)
    80001928:	6ba2                	ld	s7,8(sp)
    8000192a:	6161                	addi	sp,sp,80
    8000192c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000192e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001932:	c8a9                	beqz	s1,80001984 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001934:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001938:	85ca                	mv	a1,s2
    8000193a:	8552                	mv	a0,s4
    8000193c:	00000097          	auipc	ra,0x0
    80001940:	8fa080e7          	jalr	-1798(ra) # 80001236 <walkaddr>
    if(pa0 == 0)
    80001944:	c131                	beqz	a0,80001988 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001946:	41790833          	sub	a6,s2,s7
    8000194a:	984e                	add	a6,a6,s3
    if(n > max)
    8000194c:	0104f363          	bgeu	s1,a6,80001952 <copyinstr+0x6e>
    80001950:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001952:	955e                	add	a0,a0,s7
    80001954:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001958:	fc080be3          	beqz	a6,8000192e <copyinstr+0x4a>
    8000195c:	985a                	add	a6,a6,s6
    8000195e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001960:	41650633          	sub	a2,a0,s6
    80001964:	14fd                	addi	s1,s1,-1
    80001966:	9b26                	add	s6,s6,s1
    80001968:	00f60733          	add	a4,a2,a5
    8000196c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffb9000>
    80001970:	df49                	beqz	a4,8000190a <copyinstr+0x26>
        *dst = *p;
    80001972:	00e78023          	sb	a4,0(a5)
      --max;
    80001976:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000197a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000197c:	ff0796e3          	bne	a5,a6,80001968 <copyinstr+0x84>
      dst++;
    80001980:	8b42                	mv	s6,a6
    80001982:	b775                	j	8000192e <copyinstr+0x4a>
    80001984:	4781                	li	a5,0
    80001986:	b769                	j	80001910 <copyinstr+0x2c>
      return -1;
    80001988:	557d                	li	a0,-1
    8000198a:	b779                	j	80001918 <copyinstr+0x34>
  int got_null = 0;
    8000198c:	4781                	li	a5,0
  if(got_null){
    8000198e:	0017b793          	seqz	a5,a5
    80001992:	40f00533          	neg	a0,a5
}
    80001996:	8082                	ret

0000000080001998 <uvmcheckcowpage>:
 
// Check if a given virtual address points to a copy-on-write page
int uvmcheckcowpage(uint64 va) {
    80001998:	1101                	addi	sp,sp,-32
    8000199a:	ec06                	sd	ra,24(sp)
    8000199c:	e822                	sd	s0,16(sp)
    8000199e:	e426                	sd	s1,8(sp)
    800019a0:	1000                	addi	s0,sp,32
    800019a2:	84aa                	mv	s1,a0
  pte_t *pte;
  struct proc *p = myproc();
    800019a4:	00000097          	auipc	ra,0x0
    800019a8:	2d6080e7          	jalr	726(ra) # 80001c7a <myproc>
  
  return va < p->sz // within size of memory for the process
    && ((pte = walk(p->pagetable, va, 0))!=0)
    && (*pte & PTE_V) // page table entry exists
    && (*pte & PTE_COW); // page is a cow page
    800019ac:	653c                	ld	a5,72(a0)
    800019ae:	00f4e863          	bltu	s1,a5,800019be <uvmcheckcowpage+0x26>
    800019b2:	4501                	li	a0,0
}
    800019b4:	60e2                	ld	ra,24(sp)
    800019b6:	6442                	ld	s0,16(sp)
    800019b8:	64a2                	ld	s1,8(sp)
    800019ba:	6105                	addi	sp,sp,32
    800019bc:	8082                	ret
    && ((pte = walk(p->pagetable, va, 0))!=0)
    800019be:	4601                	li	a2,0
    800019c0:	85a6                	mv	a1,s1
    800019c2:	6928                	ld	a0,80(a0)
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	7cc080e7          	jalr	1996(ra) # 80001190 <walk>
    800019cc:	87aa                	mv	a5,a0
    && (*pte & PTE_COW); // page is a cow page
    800019ce:	4501                	li	a0,0
    && ((pte = walk(p->pagetable, va, 0))!=0)
    800019d0:	d3f5                	beqz	a5,800019b4 <uvmcheckcowpage+0x1c>
    && (*pte & PTE_COW); // page is a cow page
    800019d2:	6388                	ld	a0,0(a5)
    800019d4:	10157513          	andi	a0,a0,257
    800019d8:	eff50513          	addi	a0,a0,-257
    800019dc:	00153513          	seqz	a0,a0
    800019e0:	bfd1                	j	800019b4 <uvmcheckcowpage+0x1c>

00000000800019e2 <uvmcowcopy>:

// Copy the cow page, then map it as writable
int uvmcowcopy(uint64 va) {
    800019e2:	7179                	addi	sp,sp,-48
    800019e4:	f406                	sd	ra,40(sp)
    800019e6:	f022                	sd	s0,32(sp)
    800019e8:	ec26                	sd	s1,24(sp)
    800019ea:	e84a                	sd	s2,16(sp)
    800019ec:	e44e                	sd	s3,8(sp)
    800019ee:	e052                	sd	s4,0(sp)
    800019f0:	1800                	addi	s0,sp,48
    800019f2:	89aa                	mv	s3,a0
  pte_t *pte;
  struct proc *p = myproc();
    800019f4:	00000097          	auipc	ra,0x0
    800019f8:	286080e7          	jalr	646(ra) # 80001c7a <myproc>
    800019fc:	892a                	mv	s2,a0

  if((pte = walk(p->pagetable, va, 0)) == 0)
    800019fe:	4601                	li	a2,0
    80001a00:	85ce                	mv	a1,s3
    80001a02:	6928                	ld	a0,80(a0)
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	78c080e7          	jalr	1932(ra) # 80001190 <walk>
    80001a0c:	c135                	beqz	a0,80001a70 <uvmcowcopy+0x8e>
    80001a0e:	84aa                	mv	s1,a0
    panic("uvmcowcopy: walk");
  
  // copy the cow page
  // (no copying will take place if reference count is already 1)
  uint64 pa = PTE2PA(*pte);
    80001a10:	6108                	ld	a0,0(a0)
    80001a12:	8129                	srli	a0,a0,0xa
  uint64 new = (uint64)kcopy_n_deref((void*)pa);
    80001a14:	0532                	slli	a0,a0,0xc
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	204080e7          	jalr	516(ra) # 80000c1a <kcopy_n_deref>
    80001a1e:	8a2a                	mv	s4,a0
  if(new == 0)
    80001a20:	c925                	beqz	a0,80001a90 <uvmcowcopy+0xae>
    return -1;
  
  // map as writable, remove the cow flag
  uint64 flags = (PTE_FLAGS(*pte) | PTE_W) & ~PTE_COW;
    80001a22:	6084                	ld	s1,0(s1)
    80001a24:	2fb4f493          	andi	s1,s1,763
    80001a28:	0044e493          	ori	s1,s1,4
  uvmunmap(p->pagetable, PGROUNDDOWN(va), 1, 0);
    80001a2c:	4681                	li	a3,0
    80001a2e:	4605                	li	a2,1
    80001a30:	75fd                	lui	a1,0xfffff
    80001a32:	00b9f5b3          	and	a1,s3,a1
    80001a36:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    80001a3a:	00000097          	auipc	ra,0x0
    80001a3e:	a34080e7          	jalr	-1484(ra) # 8000146e <uvmunmap>
  if(mappages(p->pagetable, va, 1, new, flags) == -1) {
    80001a42:	8726                	mv	a4,s1
    80001a44:	86d2                	mv	a3,s4
    80001a46:	4605                	li	a2,1
    80001a48:	85ce                	mv	a1,s3
    80001a4a:	05093503          	ld	a0,80(s2)
    80001a4e:	00000097          	auipc	ra,0x0
    80001a52:	888080e7          	jalr	-1912(ra) # 800012d6 <mappages>
    80001a56:	872a                	mv	a4,a0
    80001a58:	57fd                	li	a5,-1
    panic("uvmcowcopy: mappages");
  }
  return 0;
    80001a5a:	4501                	li	a0,0
  if(mappages(p->pagetable, va, 1, new, flags) == -1) {
    80001a5c:	02f70263          	beq	a4,a5,80001a80 <uvmcowcopy+0x9e>
    80001a60:	70a2                	ld	ra,40(sp)
    80001a62:	7402                	ld	s0,32(sp)
    80001a64:	64e2                	ld	s1,24(sp)
    80001a66:	6942                	ld	s2,16(sp)
    80001a68:	69a2                	ld	s3,8(sp)
    80001a6a:	6a02                	ld	s4,0(sp)
    80001a6c:	6145                	addi	sp,sp,48
    80001a6e:	8082                	ret
    panic("uvmcowcopy: walk");
    80001a70:	00006517          	auipc	a0,0x6
    80001a74:	76050513          	addi	a0,a0,1888 # 800081d0 <digits+0x190>
    80001a78:	fffff097          	auipc	ra,0xfffff
    80001a7c:	ade080e7          	jalr	-1314(ra) # 80000556 <panic>
    panic("uvmcowcopy: mappages");
    80001a80:	00006517          	auipc	a0,0x6
    80001a84:	76850513          	addi	a0,a0,1896 # 800081e8 <digits+0x1a8>
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	ace080e7          	jalr	-1330(ra) # 80000556 <panic>
    return -1;
    80001a90:	557d                	li	a0,-1
    80001a92:	b7f9                	j	80001a60 <uvmcowcopy+0x7e>

0000000080001a94 <copyout>:
{
    80001a94:	715d                	addi	sp,sp,-80
    80001a96:	e486                	sd	ra,72(sp)
    80001a98:	e0a2                	sd	s0,64(sp)
    80001a9a:	fc26                	sd	s1,56(sp)
    80001a9c:	f84a                	sd	s2,48(sp)
    80001a9e:	f44e                	sd	s3,40(sp)
    80001aa0:	f052                	sd	s4,32(sp)
    80001aa2:	ec56                	sd	s5,24(sp)
    80001aa4:	e85a                	sd	s6,16(sp)
    80001aa6:	e45e                	sd	s7,8(sp)
    80001aa8:	e062                	sd	s8,0(sp)
    80001aaa:	0880                	addi	s0,sp,80
    80001aac:	8b2a                	mv	s6,a0
    80001aae:	8c2e                	mv	s8,a1
    80001ab0:	8a32                	mv	s4,a2
    80001ab2:	89b6                	mv	s3,a3
  if(uvmcheckcowpage(dstva))
    80001ab4:	852e                	mv	a0,a1
    80001ab6:	00000097          	auipc	ra,0x0
    80001aba:	ee2080e7          	jalr	-286(ra) # 80001998 <uvmcheckcowpage>
    80001abe:	e511                	bnez	a0,80001aca <copyout+0x36>
  while(len > 0){
    80001ac0:	04098e63          	beqz	s3,80001b1c <copyout+0x88>
    va0 = PGROUNDDOWN(dstva);
    80001ac4:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (dstva - va0);
    80001ac6:	6a85                	lui	s5,0x1
    80001ac8:	a805                	j	80001af8 <copyout+0x64>
    uvmcowcopy(dstva);
    80001aca:	8562                	mv	a0,s8
    80001acc:	00000097          	auipc	ra,0x0
    80001ad0:	f16080e7          	jalr	-234(ra) # 800019e2 <uvmcowcopy>
    80001ad4:	b7f5                	j	80001ac0 <copyout+0x2c>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001ad6:	9562                	add	a0,a0,s8
    80001ad8:	0004861b          	sext.w	a2,s1
    80001adc:	85d2                	mv	a1,s4
    80001ade:	41250533          	sub	a0,a0,s2
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	422080e7          	jalr	1058(ra) # 80000f04 <memmove>
    len -= n;
    80001aea:	409989b3          	sub	s3,s3,s1
    src += n;
    80001aee:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001af0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001af4:	02098263          	beqz	s3,80001b18 <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    80001af8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001afc:	85ca                	mv	a1,s2
    80001afe:	855a                	mv	a0,s6
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	736080e7          	jalr	1846(ra) # 80001236 <walkaddr>
    if(pa0 == 0)
    80001b08:	cd01                	beqz	a0,80001b20 <copyout+0x8c>
    n = PGSIZE - (dstva - va0);
    80001b0a:	418904b3          	sub	s1,s2,s8
    80001b0e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b10:	fc99f3e3          	bgeu	s3,s1,80001ad6 <copyout+0x42>
    80001b14:	84ce                	mv	s1,s3
    80001b16:	b7c1                	j	80001ad6 <copyout+0x42>
  return 0;
    80001b18:	4501                	li	a0,0
    80001b1a:	a021                	j	80001b22 <copyout+0x8e>
    80001b1c:	4501                	li	a0,0
    80001b1e:	a011                	j	80001b22 <copyout+0x8e>
      return -1;
    80001b20:	557d                	li	a0,-1
}
    80001b22:	60a6                	ld	ra,72(sp)
    80001b24:	6406                	ld	s0,64(sp)
    80001b26:	74e2                	ld	s1,56(sp)
    80001b28:	7942                	ld	s2,48(sp)
    80001b2a:	79a2                	ld	s3,40(sp)
    80001b2c:	7a02                	ld	s4,32(sp)
    80001b2e:	6ae2                	ld	s5,24(sp)
    80001b30:	6b42                	ld	s6,16(sp)
    80001b32:	6ba2                	ld	s7,8(sp)
    80001b34:	6c02                	ld	s8,0(sp)
    80001b36:	6161                	addi	sp,sp,80
    80001b38:	8082                	ret

0000000080001b3a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001b3a:	1101                	addi	sp,sp,-32
    80001b3c:	ec06                	sd	ra,24(sp)
    80001b3e:	e822                	sd	s0,16(sp)
    80001b40:	e426                	sd	s1,8(sp)
    80001b42:	1000                	addi	s0,sp,32
    80001b44:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b46:	fffff097          	auipc	ra,0xfffff
    80001b4a:	1e8080e7          	jalr	488(ra) # 80000d2e <holding>
    80001b4e:	c909                	beqz	a0,80001b60 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001b50:	749c                	ld	a5,40(s1)
    80001b52:	00978f63          	beq	a5,s1,80001b70 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6105                	addi	sp,sp,32
    80001b5e:	8082                	ret
    panic("wakeup1");
    80001b60:	00006517          	auipc	a0,0x6
    80001b64:	6a050513          	addi	a0,a0,1696 # 80008200 <digits+0x1c0>
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	9ee080e7          	jalr	-1554(ra) # 80000556 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001b70:	4c98                	lw	a4,24(s1)
    80001b72:	4785                	li	a5,1
    80001b74:	fef711e3          	bne	a4,a5,80001b56 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b78:	4789                	li	a5,2
    80001b7a:	cc9c                	sw	a5,24(s1)
}
    80001b7c:	bfe9                	j	80001b56 <wakeup1+0x1c>

0000000080001b7e <procinit>:
{
    80001b7e:	715d                	addi	sp,sp,-80
    80001b80:	e486                	sd	ra,72(sp)
    80001b82:	e0a2                	sd	s0,64(sp)
    80001b84:	fc26                	sd	s1,56(sp)
    80001b86:	f84a                	sd	s2,48(sp)
    80001b88:	f44e                	sd	s3,40(sp)
    80001b8a:	f052                	sd	s4,32(sp)
    80001b8c:	ec56                	sd	s5,24(sp)
    80001b8e:	e85a                	sd	s6,16(sp)
    80001b90:	e45e                	sd	s7,8(sp)
    80001b92:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001b94:	00006597          	auipc	a1,0x6
    80001b98:	67458593          	addi	a1,a1,1652 # 80008208 <digits+0x1c8>
    80001b9c:	00030517          	auipc	a0,0x30
    80001ba0:	dcc50513          	addi	a0,a0,-564 # 80031968 <pid_lock>
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	174080e7          	jalr	372(ra) # 80000d18 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bac:	00030917          	auipc	s2,0x30
    80001bb0:	1d490913          	addi	s2,s2,468 # 80031d80 <proc>
      initlock(&p->lock, "proc");
    80001bb4:	00006b97          	auipc	s7,0x6
    80001bb8:	65cb8b93          	addi	s7,s7,1628 # 80008210 <digits+0x1d0>
      uint64 va = KSTACK((int) (p - proc));
    80001bbc:	8b4a                	mv	s6,s2
    80001bbe:	00006a97          	auipc	s5,0x6
    80001bc2:	442a8a93          	addi	s5,s5,1090 # 80008000 <etext>
    80001bc6:	040009b7          	lui	s3,0x4000
    80001bca:	19fd                	addi	s3,s3,-1
    80001bcc:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bce:	00036a17          	auipc	s4,0x36
    80001bd2:	bb2a0a13          	addi	s4,s4,-1102 # 80037780 <tickslock>
      initlock(&p->lock, "proc");
    80001bd6:	85de                	mv	a1,s7
    80001bd8:	854a                	mv	a0,s2
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	13e080e7          	jalr	318(ra) # 80000d18 <initlock>
      char *pa = kalloc();
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	fb6080e7          	jalr	-74(ra) # 80000b98 <kalloc>
    80001bea:	85aa                	mv	a1,a0
      if(pa == 0)
    80001bec:	c929                	beqz	a0,80001c3e <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001bee:	416904b3          	sub	s1,s2,s6
    80001bf2:	848d                	srai	s1,s1,0x3
    80001bf4:	000ab783          	ld	a5,0(s5)
    80001bf8:	02f484b3          	mul	s1,s1,a5
    80001bfc:	2485                	addiw	s1,s1,1
    80001bfe:	00d4949b          	slliw	s1,s1,0xd
    80001c02:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c06:	4699                	li	a3,6
    80001c08:	6605                	lui	a2,0x1
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	758080e7          	jalr	1880(ra) # 80001364 <kvmmap>
      p->kstack = va;
    80001c14:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c18:	16890913          	addi	s2,s2,360
    80001c1c:	fb491de3          	bne	s2,s4,80001bd6 <procinit+0x58>
  kvminithart();
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	54c080e7          	jalr	1356(ra) # 8000116c <kvminithart>
}
    80001c28:	60a6                	ld	ra,72(sp)
    80001c2a:	6406                	ld	s0,64(sp)
    80001c2c:	74e2                	ld	s1,56(sp)
    80001c2e:	7942                	ld	s2,48(sp)
    80001c30:	79a2                	ld	s3,40(sp)
    80001c32:	7a02                	ld	s4,32(sp)
    80001c34:	6ae2                	ld	s5,24(sp)
    80001c36:	6b42                	ld	s6,16(sp)
    80001c38:	6ba2                	ld	s7,8(sp)
    80001c3a:	6161                	addi	sp,sp,80
    80001c3c:	8082                	ret
        panic("kalloc");
    80001c3e:	00006517          	auipc	a0,0x6
    80001c42:	5da50513          	addi	a0,a0,1498 # 80008218 <digits+0x1d8>
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	910080e7          	jalr	-1776(ra) # 80000556 <panic>

0000000080001c4e <cpuid>:
{
    80001c4e:	1141                	addi	sp,sp,-16
    80001c50:	e422                	sd	s0,8(sp)
    80001c52:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c54:	8512                	mv	a0,tp
}
    80001c56:	2501                	sext.w	a0,a0
    80001c58:	6422                	ld	s0,8(sp)
    80001c5a:	0141                	addi	sp,sp,16
    80001c5c:	8082                	ret

0000000080001c5e <mycpu>:
mycpu(void) {
    80001c5e:	1141                	addi	sp,sp,-16
    80001c60:	e422                	sd	s0,8(sp)
    80001c62:	0800                	addi	s0,sp,16
    80001c64:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001c66:	2781                	sext.w	a5,a5
    80001c68:	079e                	slli	a5,a5,0x7
}
    80001c6a:	00030517          	auipc	a0,0x30
    80001c6e:	d1650513          	addi	a0,a0,-746 # 80031980 <cpus>
    80001c72:	953e                	add	a0,a0,a5
    80001c74:	6422                	ld	s0,8(sp)
    80001c76:	0141                	addi	sp,sp,16
    80001c78:	8082                	ret

0000000080001c7a <myproc>:
myproc(void) {
    80001c7a:	1101                	addi	sp,sp,-32
    80001c7c:	ec06                	sd	ra,24(sp)
    80001c7e:	e822                	sd	s0,16(sp)
    80001c80:	e426                	sd	s1,8(sp)
    80001c82:	1000                	addi	s0,sp,32
  push_off();
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	0d8080e7          	jalr	216(ra) # 80000d5c <push_off>
    80001c8c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001c8e:	2781                	sext.w	a5,a5
    80001c90:	079e                	slli	a5,a5,0x7
    80001c92:	00030717          	auipc	a4,0x30
    80001c96:	cd670713          	addi	a4,a4,-810 # 80031968 <pid_lock>
    80001c9a:	97ba                	add	a5,a5,a4
    80001c9c:	6f84                	ld	s1,24(a5)
  pop_off();
    80001c9e:	fffff097          	auipc	ra,0xfffff
    80001ca2:	15e080e7          	jalr	350(ra) # 80000dfc <pop_off>
}
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6105                	addi	sp,sp,32
    80001cb0:	8082                	ret

0000000080001cb2 <forkret>:
{
    80001cb2:	1141                	addi	sp,sp,-16
    80001cb4:	e406                	sd	ra,8(sp)
    80001cb6:	e022                	sd	s0,0(sp)
    80001cb8:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	fc0080e7          	jalr	-64(ra) # 80001c7a <myproc>
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	19a080e7          	jalr	410(ra) # 80000e5c <release>
  if (first) {
    80001cca:	00007797          	auipc	a5,0x7
    80001cce:	b867a783          	lw	a5,-1146(a5) # 80008850 <first.1676>
    80001cd2:	eb89                	bnez	a5,80001ce4 <forkret+0x32>
  usertrapret();
    80001cd4:	00001097          	auipc	ra,0x1
    80001cd8:	c1c080e7          	jalr	-996(ra) # 800028f0 <usertrapret>
}
    80001cdc:	60a2                	ld	ra,8(sp)
    80001cde:	6402                	ld	s0,0(sp)
    80001ce0:	0141                	addi	sp,sp,16
    80001ce2:	8082                	ret
    first = 0;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	b607a623          	sw	zero,-1172(a5) # 80008850 <first.1676>
    fsinit(ROOTDEV);
    80001cec:	4505                	li	a0,1
    80001cee:	00002097          	auipc	ra,0x2
    80001cf2:	97e080e7          	jalr	-1666(ra) # 8000366c <fsinit>
    80001cf6:	bff9                	j	80001cd4 <forkret+0x22>

0000000080001cf8 <allocpid>:
allocpid() {
    80001cf8:	1101                	addi	sp,sp,-32
    80001cfa:	ec06                	sd	ra,24(sp)
    80001cfc:	e822                	sd	s0,16(sp)
    80001cfe:	e426                	sd	s1,8(sp)
    80001d00:	e04a                	sd	s2,0(sp)
    80001d02:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d04:	00030917          	auipc	s2,0x30
    80001d08:	c6490913          	addi	s2,s2,-924 # 80031968 <pid_lock>
    80001d0c:	854a                	mv	a0,s2
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	09a080e7          	jalr	154(ra) # 80000da8 <acquire>
  pid = nextpid;
    80001d16:	00007797          	auipc	a5,0x7
    80001d1a:	b3e78793          	addi	a5,a5,-1218 # 80008854 <nextpid>
    80001d1e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d20:	0014871b          	addiw	a4,s1,1
    80001d24:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d26:	854a                	mv	a0,s2
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	134080e7          	jalr	308(ra) # 80000e5c <release>
}
    80001d30:	8526                	mv	a0,s1
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6902                	ld	s2,0(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <proc_pagetable>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	e04a                	sd	s2,0(sp)
    80001d48:	1000                	addi	s0,sp,32
    80001d4a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	7e6080e7          	jalr	2022(ra) # 80001532 <uvmcreate>
    80001d54:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d56:	c121                	beqz	a0,80001d96 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d58:	4729                	li	a4,10
    80001d5a:	00005697          	auipc	a3,0x5
    80001d5e:	2a668693          	addi	a3,a3,678 # 80007000 <_trampoline>
    80001d62:	6605                	lui	a2,0x1
    80001d64:	040005b7          	lui	a1,0x4000
    80001d68:	15fd                	addi	a1,a1,-1
    80001d6a:	05b2                	slli	a1,a1,0xc
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	56a080e7          	jalr	1386(ra) # 800012d6 <mappages>
    80001d74:	02054863          	bltz	a0,80001da4 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d78:	4719                	li	a4,6
    80001d7a:	05893683          	ld	a3,88(s2)
    80001d7e:	6605                	lui	a2,0x1
    80001d80:	020005b7          	lui	a1,0x2000
    80001d84:	15fd                	addi	a1,a1,-1
    80001d86:	05b6                	slli	a1,a1,0xd
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	54c080e7          	jalr	1356(ra) # 800012d6 <mappages>
    80001d92:	02054163          	bltz	a0,80001db4 <proc_pagetable+0x76>
}
    80001d96:	8526                	mv	a0,s1
    80001d98:	60e2                	ld	ra,24(sp)
    80001d9a:	6442                	ld	s0,16(sp)
    80001d9c:	64a2                	ld	s1,8(sp)
    80001d9e:	6902                	ld	s2,0(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret
    uvmfree(pagetable, 0);
    80001da4:	4581                	li	a1,0
    80001da6:	8526                	mv	a0,s1
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	986080e7          	jalr	-1658(ra) # 8000172e <uvmfree>
    return 0;
    80001db0:	4481                	li	s1,0
    80001db2:	b7d5                	j	80001d96 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001db4:	4681                	li	a3,0
    80001db6:	4605                	li	a2,1
    80001db8:	040005b7          	lui	a1,0x4000
    80001dbc:	15fd                	addi	a1,a1,-1
    80001dbe:	05b2                	slli	a1,a1,0xc
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	6ac080e7          	jalr	1708(ra) # 8000146e <uvmunmap>
    uvmfree(pagetable, 0);
    80001dca:	4581                	li	a1,0
    80001dcc:	8526                	mv	a0,s1
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	960080e7          	jalr	-1696(ra) # 8000172e <uvmfree>
    return 0;
    80001dd6:	4481                	li	s1,0
    80001dd8:	bf7d                	j	80001d96 <proc_pagetable+0x58>

0000000080001dda <proc_freepagetable>:
{
    80001dda:	1101                	addi	sp,sp,-32
    80001ddc:	ec06                	sd	ra,24(sp)
    80001dde:	e822                	sd	s0,16(sp)
    80001de0:	e426                	sd	s1,8(sp)
    80001de2:	e04a                	sd	s2,0(sp)
    80001de4:	1000                	addi	s0,sp,32
    80001de6:	84aa                	mv	s1,a0
    80001de8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dea:	4681                	li	a3,0
    80001dec:	4605                	li	a2,1
    80001dee:	040005b7          	lui	a1,0x4000
    80001df2:	15fd                	addi	a1,a1,-1
    80001df4:	05b2                	slli	a1,a1,0xc
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	678080e7          	jalr	1656(ra) # 8000146e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dfe:	4681                	li	a3,0
    80001e00:	4605                	li	a2,1
    80001e02:	020005b7          	lui	a1,0x2000
    80001e06:	15fd                	addi	a1,a1,-1
    80001e08:	05b6                	slli	a1,a1,0xd
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	662080e7          	jalr	1634(ra) # 8000146e <uvmunmap>
  uvmfree(pagetable, sz);
    80001e14:	85ca                	mv	a1,s2
    80001e16:	8526                	mv	a0,s1
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	916080e7          	jalr	-1770(ra) # 8000172e <uvmfree>
}
    80001e20:	60e2                	ld	ra,24(sp)
    80001e22:	6442                	ld	s0,16(sp)
    80001e24:	64a2                	ld	s1,8(sp)
    80001e26:	6902                	ld	s2,0(sp)
    80001e28:	6105                	addi	sp,sp,32
    80001e2a:	8082                	ret

0000000080001e2c <freeproc>:
{
    80001e2c:	1101                	addi	sp,sp,-32
    80001e2e:	ec06                	sd	ra,24(sp)
    80001e30:	e822                	sd	s0,16(sp)
    80001e32:	e426                	sd	s1,8(sp)
    80001e34:	1000                	addi	s0,sp,32
    80001e36:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e38:	6d28                	ld	a0,88(a0)
    80001e3a:	c509                	beqz	a0,80001e44 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	bf6080e7          	jalr	-1034(ra) # 80000a32 <kfree>
  p->trapframe = 0;
    80001e44:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e48:	68a8                	ld	a0,80(s1)
    80001e4a:	c511                	beqz	a0,80001e56 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e4c:	64ac                	ld	a1,72(s1)
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	f8c080e7          	jalr	-116(ra) # 80001dda <proc_freepagetable>
  p->pagetable = 0;
    80001e56:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e5a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e5e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001e62:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001e66:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e6a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e6e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e72:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e76:	0004ac23          	sw	zero,24(s1)
}
    80001e7a:	60e2                	ld	ra,24(sp)
    80001e7c:	6442                	ld	s0,16(sp)
    80001e7e:	64a2                	ld	s1,8(sp)
    80001e80:	6105                	addi	sp,sp,32
    80001e82:	8082                	ret

0000000080001e84 <allocproc>:
{
    80001e84:	1101                	addi	sp,sp,-32
    80001e86:	ec06                	sd	ra,24(sp)
    80001e88:	e822                	sd	s0,16(sp)
    80001e8a:	e426                	sd	s1,8(sp)
    80001e8c:	e04a                	sd	s2,0(sp)
    80001e8e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e90:	00030497          	auipc	s1,0x30
    80001e94:	ef048493          	addi	s1,s1,-272 # 80031d80 <proc>
    80001e98:	00036917          	auipc	s2,0x36
    80001e9c:	8e890913          	addi	s2,s2,-1816 # 80037780 <tickslock>
    acquire(&p->lock);
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	f06080e7          	jalr	-250(ra) # 80000da8 <acquire>
    if(p->state == UNUSED) {
    80001eaa:	4c9c                	lw	a5,24(s1)
    80001eac:	cf81                	beqz	a5,80001ec4 <allocproc+0x40>
      release(&p->lock);
    80001eae:	8526                	mv	a0,s1
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	fac080e7          	jalr	-84(ra) # 80000e5c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb8:	16848493          	addi	s1,s1,360
    80001ebc:	ff2492e3          	bne	s1,s2,80001ea0 <allocproc+0x1c>
  return 0;
    80001ec0:	4481                	li	s1,0
    80001ec2:	a0b9                	j	80001f10 <allocproc+0x8c>
  p->pid = allocpid();
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	e34080e7          	jalr	-460(ra) # 80001cf8 <allocpid>
    80001ecc:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	cca080e7          	jalr	-822(ra) # 80000b98 <kalloc>
    80001ed6:	892a                	mv	s2,a0
    80001ed8:	eca8                	sd	a0,88(s1)
    80001eda:	c131                	beqz	a0,80001f1e <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001edc:	8526                	mv	a0,s1
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	e60080e7          	jalr	-416(ra) # 80001d3e <proc_pagetable>
    80001ee6:	892a                	mv	s2,a0
    80001ee8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001eea:	c129                	beqz	a0,80001f2c <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001eec:	07000613          	li	a2,112
    80001ef0:	4581                	li	a1,0
    80001ef2:	06048513          	addi	a0,s1,96
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	fae080e7          	jalr	-82(ra) # 80000ea4 <memset>
  p->context.ra = (uint64)forkret;
    80001efe:	00000797          	auipc	a5,0x0
    80001f02:	db478793          	addi	a5,a5,-588 # 80001cb2 <forkret>
    80001f06:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f08:	60bc                	ld	a5,64(s1)
    80001f0a:	6705                	lui	a4,0x1
    80001f0c:	97ba                	add	a5,a5,a4
    80001f0e:	f4bc                	sd	a5,104(s1)
}
    80001f10:	8526                	mv	a0,s1
    80001f12:	60e2                	ld	ra,24(sp)
    80001f14:	6442                	ld	s0,16(sp)
    80001f16:	64a2                	ld	s1,8(sp)
    80001f18:	6902                	ld	s2,0(sp)
    80001f1a:	6105                	addi	sp,sp,32
    80001f1c:	8082                	ret
    release(&p->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	f3c080e7          	jalr	-196(ra) # 80000e5c <release>
    return 0;
    80001f28:	84ca                	mv	s1,s2
    80001f2a:	b7dd                	j	80001f10 <allocproc+0x8c>
    freeproc(p);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	00000097          	auipc	ra,0x0
    80001f32:	efe080e7          	jalr	-258(ra) # 80001e2c <freeproc>
    release(&p->lock);
    80001f36:	8526                	mv	a0,s1
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	f24080e7          	jalr	-220(ra) # 80000e5c <release>
    return 0;
    80001f40:	84ca                	mv	s1,s2
    80001f42:	b7f9                	j	80001f10 <allocproc+0x8c>

0000000080001f44 <userinit>:
{
    80001f44:	1101                	addi	sp,sp,-32
    80001f46:	ec06                	sd	ra,24(sp)
    80001f48:	e822                	sd	s0,16(sp)
    80001f4a:	e426                	sd	s1,8(sp)
    80001f4c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f4e:	00000097          	auipc	ra,0x0
    80001f52:	f36080e7          	jalr	-202(ra) # 80001e84 <allocproc>
    80001f56:	84aa                	mv	s1,a0
  initproc = p;
    80001f58:	00007797          	auipc	a5,0x7
    80001f5c:	0ca7b023          	sd	a0,192(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f60:	03400613          	li	a2,52
    80001f64:	00007597          	auipc	a1,0x7
    80001f68:	8fc58593          	addi	a1,a1,-1796 # 80008860 <initcode>
    80001f6c:	6928                	ld	a0,80(a0)
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	5f2080e7          	jalr	1522(ra) # 80001560 <uvminit>
  p->sz = PGSIZE;
    80001f76:	6785                	lui	a5,0x1
    80001f78:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f7a:	6cb8                	ld	a4,88(s1)
    80001f7c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f80:	6cb8                	ld	a4,88(s1)
    80001f82:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f84:	4641                	li	a2,16
    80001f86:	00006597          	auipc	a1,0x6
    80001f8a:	29a58593          	addi	a1,a1,666 # 80008220 <digits+0x1e0>
    80001f8e:	15848513          	addi	a0,s1,344
    80001f92:	fffff097          	auipc	ra,0xfffff
    80001f96:	068080e7          	jalr	104(ra) # 80000ffa <safestrcpy>
  p->cwd = namei("/");
    80001f9a:	00006517          	auipc	a0,0x6
    80001f9e:	29650513          	addi	a0,a0,662 # 80008230 <digits+0x1f0>
    80001fa2:	00002097          	auipc	ra,0x2
    80001fa6:	0f6080e7          	jalr	246(ra) # 80004098 <namei>
    80001faa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001fae:	4789                	li	a5,2
    80001fb0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	ea8080e7          	jalr	-344(ra) # 80000e5c <release>
}
    80001fbc:	60e2                	ld	ra,24(sp)
    80001fbe:	6442                	ld	s0,16(sp)
    80001fc0:	64a2                	ld	s1,8(sp)
    80001fc2:	6105                	addi	sp,sp,32
    80001fc4:	8082                	ret

0000000080001fc6 <growproc>:
{
    80001fc6:	1101                	addi	sp,sp,-32
    80001fc8:	ec06                	sd	ra,24(sp)
    80001fca:	e822                	sd	s0,16(sp)
    80001fcc:	e426                	sd	s1,8(sp)
    80001fce:	e04a                	sd	s2,0(sp)
    80001fd0:	1000                	addi	s0,sp,32
    80001fd2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	ca6080e7          	jalr	-858(ra) # 80001c7a <myproc>
    80001fdc:	892a                	mv	s2,a0
  sz = p->sz;
    80001fde:	652c                	ld	a1,72(a0)
    80001fe0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fe4:	00904f63          	bgtz	s1,80002002 <growproc+0x3c>
  } else if(n < 0){
    80001fe8:	0204cc63          	bltz	s1,80002020 <growproc+0x5a>
  p->sz = sz;
    80001fec:	1602                	slli	a2,a2,0x20
    80001fee:	9201                	srli	a2,a2,0x20
    80001ff0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ff4:	4501                	li	a0,0
}
    80001ff6:	60e2                	ld	ra,24(sp)
    80001ff8:	6442                	ld	s0,16(sp)
    80001ffa:	64a2                	ld	s1,8(sp)
    80001ffc:	6902                	ld	s2,0(sp)
    80001ffe:	6105                	addi	sp,sp,32
    80002000:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002002:	9e25                	addw	a2,a2,s1
    80002004:	1602                	slli	a2,a2,0x20
    80002006:	9201                	srli	a2,a2,0x20
    80002008:	1582                	slli	a1,a1,0x20
    8000200a:	9181                	srli	a1,a1,0x20
    8000200c:	6928                	ld	a0,80(a0)
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	60c080e7          	jalr	1548(ra) # 8000161a <uvmalloc>
    80002016:	0005061b          	sext.w	a2,a0
    8000201a:	fa69                	bnez	a2,80001fec <growproc+0x26>
      return -1;
    8000201c:	557d                	li	a0,-1
    8000201e:	bfe1                	j	80001ff6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002020:	9e25                	addw	a2,a2,s1
    80002022:	1602                	slli	a2,a2,0x20
    80002024:	9201                	srli	a2,a2,0x20
    80002026:	1582                	slli	a1,a1,0x20
    80002028:	9181                	srli	a1,a1,0x20
    8000202a:	6928                	ld	a0,80(a0)
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	5a6080e7          	jalr	1446(ra) # 800015d2 <uvmdealloc>
    80002034:	0005061b          	sext.w	a2,a0
    80002038:	bf55                	j	80001fec <growproc+0x26>

000000008000203a <fork>:
{
    8000203a:	7179                	addi	sp,sp,-48
    8000203c:	f406                	sd	ra,40(sp)
    8000203e:	f022                	sd	s0,32(sp)
    80002040:	ec26                	sd	s1,24(sp)
    80002042:	e84a                	sd	s2,16(sp)
    80002044:	e44e                	sd	s3,8(sp)
    80002046:	e052                	sd	s4,0(sp)
    80002048:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	c30080e7          	jalr	-976(ra) # 80001c7a <myproc>
    80002052:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002054:	00000097          	auipc	ra,0x0
    80002058:	e30080e7          	jalr	-464(ra) # 80001e84 <allocproc>
    8000205c:	c175                	beqz	a0,80002140 <fork+0x106>
    8000205e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002060:	04893603          	ld	a2,72(s2)
    80002064:	692c                	ld	a1,80(a0)
    80002066:	05093503          	ld	a0,80(s2)
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	6fc080e7          	jalr	1788(ra) # 80001766 <uvmcopy>
    80002072:	04054863          	bltz	a0,800020c2 <fork+0x88>
  np->sz = p->sz;
    80002076:	04893783          	ld	a5,72(s2)
    8000207a:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    8000207e:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002082:	05893683          	ld	a3,88(s2)
    80002086:	87b6                	mv	a5,a3
    80002088:	0589b703          	ld	a4,88(s3)
    8000208c:	12068693          	addi	a3,a3,288
    80002090:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002094:	6788                	ld	a0,8(a5)
    80002096:	6b8c                	ld	a1,16(a5)
    80002098:	6f90                	ld	a2,24(a5)
    8000209a:	01073023          	sd	a6,0(a4)
    8000209e:	e708                	sd	a0,8(a4)
    800020a0:	eb0c                	sd	a1,16(a4)
    800020a2:	ef10                	sd	a2,24(a4)
    800020a4:	02078793          	addi	a5,a5,32
    800020a8:	02070713          	addi	a4,a4,32
    800020ac:	fed792e3          	bne	a5,a3,80002090 <fork+0x56>
  np->trapframe->a0 = 0;
    800020b0:	0589b783          	ld	a5,88(s3)
    800020b4:	0607b823          	sd	zero,112(a5)
    800020b8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800020bc:	15000a13          	li	s4,336
    800020c0:	a03d                	j	800020ee <fork+0xb4>
    freeproc(np);
    800020c2:	854e                	mv	a0,s3
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	d68080e7          	jalr	-664(ra) # 80001e2c <freeproc>
    release(&np->lock);
    800020cc:	854e                	mv	a0,s3
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	d8e080e7          	jalr	-626(ra) # 80000e5c <release>
    return -1;
    800020d6:	54fd                	li	s1,-1
    800020d8:	a899                	j	8000212e <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    800020da:	00002097          	auipc	ra,0x2
    800020de:	64a080e7          	jalr	1610(ra) # 80004724 <filedup>
    800020e2:	009987b3          	add	a5,s3,s1
    800020e6:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800020e8:	04a1                	addi	s1,s1,8
    800020ea:	01448763          	beq	s1,s4,800020f8 <fork+0xbe>
    if(p->ofile[i])
    800020ee:	009907b3          	add	a5,s2,s1
    800020f2:	6388                	ld	a0,0(a5)
    800020f4:	f17d                	bnez	a0,800020da <fork+0xa0>
    800020f6:	bfcd                	j	800020e8 <fork+0xae>
  np->cwd = idup(p->cwd);
    800020f8:	15093503          	ld	a0,336(s2)
    800020fc:	00001097          	auipc	ra,0x1
    80002100:	7aa080e7          	jalr	1962(ra) # 800038a6 <idup>
    80002104:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002108:	4641                	li	a2,16
    8000210a:	15890593          	addi	a1,s2,344
    8000210e:	15898513          	addi	a0,s3,344
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	ee8080e7          	jalr	-280(ra) # 80000ffa <safestrcpy>
  pid = np->pid;
    8000211a:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    8000211e:	4789                	li	a5,2
    80002120:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002124:	854e                	mv	a0,s3
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	d36080e7          	jalr	-714(ra) # 80000e5c <release>
}
    8000212e:	8526                	mv	a0,s1
    80002130:	70a2                	ld	ra,40(sp)
    80002132:	7402                	ld	s0,32(sp)
    80002134:	64e2                	ld	s1,24(sp)
    80002136:	6942                	ld	s2,16(sp)
    80002138:	69a2                	ld	s3,8(sp)
    8000213a:	6a02                	ld	s4,0(sp)
    8000213c:	6145                	addi	sp,sp,48
    8000213e:	8082                	ret
    return -1;
    80002140:	54fd                	li	s1,-1
    80002142:	b7f5                	j	8000212e <fork+0xf4>

0000000080002144 <reparent>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	e052                	sd	s4,0(sp)
    80002152:	1800                	addi	s0,sp,48
    80002154:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002156:	00030497          	auipc	s1,0x30
    8000215a:	c2a48493          	addi	s1,s1,-982 # 80031d80 <proc>
      pp->parent = initproc;
    8000215e:	00007a17          	auipc	s4,0x7
    80002162:	ebaa0a13          	addi	s4,s4,-326 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	00035997          	auipc	s3,0x35
    8000216a:	61a98993          	addi	s3,s3,1562 # 80037780 <tickslock>
    8000216e:	a029                	j	80002178 <reparent+0x34>
    80002170:	16848493          	addi	s1,s1,360
    80002174:	03348363          	beq	s1,s3,8000219a <reparent+0x56>
    if(pp->parent == p){
    80002178:	709c                	ld	a5,32(s1)
    8000217a:	ff279be3          	bne	a5,s2,80002170 <reparent+0x2c>
      acquire(&pp->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	c28080e7          	jalr	-984(ra) # 80000da8 <acquire>
      pp->parent = initproc;
    80002188:	000a3783          	ld	a5,0(s4)
    8000218c:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	ccc080e7          	jalr	-820(ra) # 80000e5c <release>
    80002198:	bfe1                	j	80002170 <reparent+0x2c>
}
    8000219a:	70a2                	ld	ra,40(sp)
    8000219c:	7402                	ld	s0,32(sp)
    8000219e:	64e2                	ld	s1,24(sp)
    800021a0:	6942                	ld	s2,16(sp)
    800021a2:	69a2                	ld	s3,8(sp)
    800021a4:	6a02                	ld	s4,0(sp)
    800021a6:	6145                	addi	sp,sp,48
    800021a8:	8082                	ret

00000000800021aa <scheduler>:
{
    800021aa:	711d                	addi	sp,sp,-96
    800021ac:	ec86                	sd	ra,88(sp)
    800021ae:	e8a2                	sd	s0,80(sp)
    800021b0:	e4a6                	sd	s1,72(sp)
    800021b2:	e0ca                	sd	s2,64(sp)
    800021b4:	fc4e                	sd	s3,56(sp)
    800021b6:	f852                	sd	s4,48(sp)
    800021b8:	f456                	sd	s5,40(sp)
    800021ba:	f05a                	sd	s6,32(sp)
    800021bc:	ec5e                	sd	s7,24(sp)
    800021be:	e862                	sd	s8,16(sp)
    800021c0:	e466                	sd	s9,8(sp)
    800021c2:	1080                	addi	s0,sp,96
    800021c4:	8792                	mv	a5,tp
  int id = r_tp();
    800021c6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800021c8:	00779c13          	slli	s8,a5,0x7
    800021cc:	0002f717          	auipc	a4,0x2f
    800021d0:	79c70713          	addi	a4,a4,1948 # 80031968 <pid_lock>
    800021d4:	9762                	add	a4,a4,s8
    800021d6:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800021da:	0002f717          	auipc	a4,0x2f
    800021de:	7ae70713          	addi	a4,a4,1966 # 80031988 <cpus+0x8>
    800021e2:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800021e4:	4a89                	li	s5,2
        c->proc = p;
    800021e6:	079e                	slli	a5,a5,0x7
    800021e8:	0002fb17          	auipc	s6,0x2f
    800021ec:	780b0b13          	addi	s6,s6,1920 # 80031968 <pid_lock>
    800021f0:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800021f2:	00035a17          	auipc	s4,0x35
    800021f6:	58ea0a13          	addi	s4,s4,1422 # 80037780 <tickslock>
    int nproc = 0;
    800021fa:	4c81                	li	s9,0
    800021fc:	a8a1                	j	80002254 <scheduler+0xaa>
        p->state = RUNNING;
    800021fe:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002202:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002206:	06048593          	addi	a1,s1,96
    8000220a:	8562                	mv	a0,s8
    8000220c:	00000097          	auipc	ra,0x0
    80002210:	63a080e7          	jalr	1594(ra) # 80002846 <swtch>
        c->proc = 0;
    80002214:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002218:	8526                	mv	a0,s1
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	c42080e7          	jalr	-958(ra) # 80000e5c <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002222:	16848493          	addi	s1,s1,360
    80002226:	01448d63          	beq	s1,s4,80002240 <scheduler+0x96>
      acquire(&p->lock);
    8000222a:	8526                	mv	a0,s1
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	b7c080e7          	jalr	-1156(ra) # 80000da8 <acquire>
      if(p->state != UNUSED) {
    80002234:	4c9c                	lw	a5,24(s1)
    80002236:	d3ed                	beqz	a5,80002218 <scheduler+0x6e>
        nproc++;
    80002238:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000223a:	fd579fe3          	bne	a5,s5,80002218 <scheduler+0x6e>
    8000223e:	b7c1                	j	800021fe <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002240:	013aca63          	blt	s5,s3,80002254 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002244:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002248:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000224c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002250:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002254:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002258:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000225c:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002260:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002262:	00030497          	auipc	s1,0x30
    80002266:	b1e48493          	addi	s1,s1,-1250 # 80031d80 <proc>
        p->state = RUNNING;
    8000226a:	4b8d                	li	s7,3
    8000226c:	bf7d                	j	8000222a <scheduler+0x80>

000000008000226e <sched>:
{
    8000226e:	7179                	addi	sp,sp,-48
    80002270:	f406                	sd	ra,40(sp)
    80002272:	f022                	sd	s0,32(sp)
    80002274:	ec26                	sd	s1,24(sp)
    80002276:	e84a                	sd	s2,16(sp)
    80002278:	e44e                	sd	s3,8(sp)
    8000227a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	9fe080e7          	jalr	-1538(ra) # 80001c7a <myproc>
    80002284:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	aa8080e7          	jalr	-1368(ra) # 80000d2e <holding>
    8000228e:	c93d                	beqz	a0,80002304 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002290:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002292:	2781                	sext.w	a5,a5
    80002294:	079e                	slli	a5,a5,0x7
    80002296:	0002f717          	auipc	a4,0x2f
    8000229a:	6d270713          	addi	a4,a4,1746 # 80031968 <pid_lock>
    8000229e:	97ba                	add	a5,a5,a4
    800022a0:	0907a703          	lw	a4,144(a5)
    800022a4:	4785                	li	a5,1
    800022a6:	06f71763          	bne	a4,a5,80002314 <sched+0xa6>
  if(p->state == RUNNING)
    800022aa:	4c98                	lw	a4,24(s1)
    800022ac:	478d                	li	a5,3
    800022ae:	06f70b63          	beq	a4,a5,80002324 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022b6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800022b8:	efb5                	bnez	a5,80002334 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022bc:	0002f917          	auipc	s2,0x2f
    800022c0:	6ac90913          	addi	s2,s2,1708 # 80031968 <pid_lock>
    800022c4:	2781                	sext.w	a5,a5
    800022c6:	079e                	slli	a5,a5,0x7
    800022c8:	97ca                	add	a5,a5,s2
    800022ca:	0947a983          	lw	s3,148(a5)
    800022ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d0:	2781                	sext.w	a5,a5
    800022d2:	079e                	slli	a5,a5,0x7
    800022d4:	0002f597          	auipc	a1,0x2f
    800022d8:	6b458593          	addi	a1,a1,1716 # 80031988 <cpus+0x8>
    800022dc:	95be                	add	a1,a1,a5
    800022de:	06048513          	addi	a0,s1,96
    800022e2:	00000097          	auipc	ra,0x0
    800022e6:	564080e7          	jalr	1380(ra) # 80002846 <swtch>
    800022ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022ec:	2781                	sext.w	a5,a5
    800022ee:	079e                	slli	a5,a5,0x7
    800022f0:	97ca                	add	a5,a5,s2
    800022f2:	0937aa23          	sw	s3,148(a5)
}
    800022f6:	70a2                	ld	ra,40(sp)
    800022f8:	7402                	ld	s0,32(sp)
    800022fa:	64e2                	ld	s1,24(sp)
    800022fc:	6942                	ld	s2,16(sp)
    800022fe:	69a2                	ld	s3,8(sp)
    80002300:	6145                	addi	sp,sp,48
    80002302:	8082                	ret
    panic("sched p->lock");
    80002304:	00006517          	auipc	a0,0x6
    80002308:	f3450513          	addi	a0,a0,-204 # 80008238 <digits+0x1f8>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	24a080e7          	jalr	586(ra) # 80000556 <panic>
    panic("sched locks");
    80002314:	00006517          	auipc	a0,0x6
    80002318:	f3450513          	addi	a0,a0,-204 # 80008248 <digits+0x208>
    8000231c:	ffffe097          	auipc	ra,0xffffe
    80002320:	23a080e7          	jalr	570(ra) # 80000556 <panic>
    panic("sched running");
    80002324:	00006517          	auipc	a0,0x6
    80002328:	f3450513          	addi	a0,a0,-204 # 80008258 <digits+0x218>
    8000232c:	ffffe097          	auipc	ra,0xffffe
    80002330:	22a080e7          	jalr	554(ra) # 80000556 <panic>
    panic("sched interruptible");
    80002334:	00006517          	auipc	a0,0x6
    80002338:	f3450513          	addi	a0,a0,-204 # 80008268 <digits+0x228>
    8000233c:	ffffe097          	auipc	ra,0xffffe
    80002340:	21a080e7          	jalr	538(ra) # 80000556 <panic>

0000000080002344 <exit>:
{
    80002344:	7179                	addi	sp,sp,-48
    80002346:	f406                	sd	ra,40(sp)
    80002348:	f022                	sd	s0,32(sp)
    8000234a:	ec26                	sd	s1,24(sp)
    8000234c:	e84a                	sd	s2,16(sp)
    8000234e:	e44e                	sd	s3,8(sp)
    80002350:	e052                	sd	s4,0(sp)
    80002352:	1800                	addi	s0,sp,48
    80002354:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	924080e7          	jalr	-1756(ra) # 80001c7a <myproc>
    8000235e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002360:	00007797          	auipc	a5,0x7
    80002364:	cb87b783          	ld	a5,-840(a5) # 80009018 <initproc>
    80002368:	0d050493          	addi	s1,a0,208
    8000236c:	15050913          	addi	s2,a0,336
    80002370:	02a79363          	bne	a5,a0,80002396 <exit+0x52>
    panic("init exiting");
    80002374:	00006517          	auipc	a0,0x6
    80002378:	f0c50513          	addi	a0,a0,-244 # 80008280 <digits+0x240>
    8000237c:	ffffe097          	auipc	ra,0xffffe
    80002380:	1da080e7          	jalr	474(ra) # 80000556 <panic>
      fileclose(f);
    80002384:	00002097          	auipc	ra,0x2
    80002388:	3f2080e7          	jalr	1010(ra) # 80004776 <fileclose>
      p->ofile[fd] = 0;
    8000238c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002390:	04a1                	addi	s1,s1,8
    80002392:	01248563          	beq	s1,s2,8000239c <exit+0x58>
    if(p->ofile[fd]){
    80002396:	6088                	ld	a0,0(s1)
    80002398:	f575                	bnez	a0,80002384 <exit+0x40>
    8000239a:	bfdd                	j	80002390 <exit+0x4c>
  begin_op();
    8000239c:	00002097          	auipc	ra,0x2
    800023a0:	f08080e7          	jalr	-248(ra) # 800042a4 <begin_op>
  iput(p->cwd);
    800023a4:	1509b503          	ld	a0,336(s3)
    800023a8:	00001097          	auipc	ra,0x1
    800023ac:	6f6080e7          	jalr	1782(ra) # 80003a9e <iput>
  end_op();
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	f74080e7          	jalr	-140(ra) # 80004324 <end_op>
  p->cwd = 0;
    800023b8:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800023bc:	00007497          	auipc	s1,0x7
    800023c0:	c5c48493          	addi	s1,s1,-932 # 80009018 <initproc>
    800023c4:	6088                	ld	a0,0(s1)
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	9e2080e7          	jalr	-1566(ra) # 80000da8 <acquire>
  wakeup1(initproc);
    800023ce:	6088                	ld	a0,0(s1)
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	76a080e7          	jalr	1898(ra) # 80001b3a <wakeup1>
  release(&initproc->lock);
    800023d8:	6088                	ld	a0,0(s1)
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	a82080e7          	jalr	-1406(ra) # 80000e5c <release>
  acquire(&p->lock);
    800023e2:	854e                	mv	a0,s3
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	9c4080e7          	jalr	-1596(ra) # 80000da8 <acquire>
  struct proc *original_parent = p->parent;
    800023ec:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800023f0:	854e                	mv	a0,s3
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	a6a080e7          	jalr	-1430(ra) # 80000e5c <release>
  acquire(&original_parent->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	9ac080e7          	jalr	-1620(ra) # 80000da8 <acquire>
  acquire(&p->lock);
    80002404:	854e                	mv	a0,s3
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	9a2080e7          	jalr	-1630(ra) # 80000da8 <acquire>
  reparent(p);
    8000240e:	854e                	mv	a0,s3
    80002410:	00000097          	auipc	ra,0x0
    80002414:	d34080e7          	jalr	-716(ra) # 80002144 <reparent>
  wakeup1(original_parent);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	720080e7          	jalr	1824(ra) # 80001b3a <wakeup1>
  p->xstate = status;
    80002422:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002426:	4791                	li	a5,4
    80002428:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	a2e080e7          	jalr	-1490(ra) # 80000e5c <release>
  sched();
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	e38080e7          	jalr	-456(ra) # 8000226e <sched>
  panic("zombie exit");
    8000243e:	00006517          	auipc	a0,0x6
    80002442:	e5250513          	addi	a0,a0,-430 # 80008290 <digits+0x250>
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	110080e7          	jalr	272(ra) # 80000556 <panic>

000000008000244e <yield>:
{
    8000244e:	1101                	addi	sp,sp,-32
    80002450:	ec06                	sd	ra,24(sp)
    80002452:	e822                	sd	s0,16(sp)
    80002454:	e426                	sd	s1,8(sp)
    80002456:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002458:	00000097          	auipc	ra,0x0
    8000245c:	822080e7          	jalr	-2014(ra) # 80001c7a <myproc>
    80002460:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	946080e7          	jalr	-1722(ra) # 80000da8 <acquire>
  p->state = RUNNABLE;
    8000246a:	4789                	li	a5,2
    8000246c:	cc9c                	sw	a5,24(s1)
  sched();
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	e00080e7          	jalr	-512(ra) # 8000226e <sched>
  release(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	9e4080e7          	jalr	-1564(ra) # 80000e5c <release>
}
    80002480:	60e2                	ld	ra,24(sp)
    80002482:	6442                	ld	s0,16(sp)
    80002484:	64a2                	ld	s1,8(sp)
    80002486:	6105                	addi	sp,sp,32
    80002488:	8082                	ret

000000008000248a <sleep>:
{
    8000248a:	7179                	addi	sp,sp,-48
    8000248c:	f406                	sd	ra,40(sp)
    8000248e:	f022                	sd	s0,32(sp)
    80002490:	ec26                	sd	s1,24(sp)
    80002492:	e84a                	sd	s2,16(sp)
    80002494:	e44e                	sd	s3,8(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	89aa                	mv	s3,a0
    8000249a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	7de080e7          	jalr	2014(ra) # 80001c7a <myproc>
    800024a4:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800024a6:	05250663          	beq	a0,s2,800024f2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	8fe080e7          	jalr	-1794(ra) # 80000da8 <acquire>
    release(lk);
    800024b2:	854a                	mv	a0,s2
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	9a8080e7          	jalr	-1624(ra) # 80000e5c <release>
  p->chan = chan;
    800024bc:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800024c0:	4785                	li	a5,1
    800024c2:	cc9c                	sw	a5,24(s1)
  sched();
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	daa080e7          	jalr	-598(ra) # 8000226e <sched>
  p->chan = 0;
    800024cc:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	98a080e7          	jalr	-1654(ra) # 80000e5c <release>
    acquire(lk);
    800024da:	854a                	mv	a0,s2
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	8cc080e7          	jalr	-1844(ra) # 80000da8 <acquire>
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6145                	addi	sp,sp,48
    800024f0:	8082                	ret
  p->chan = chan;
    800024f2:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800024f6:	4785                	li	a5,1
    800024f8:	cd1c                	sw	a5,24(a0)
  sched();
    800024fa:	00000097          	auipc	ra,0x0
    800024fe:	d74080e7          	jalr	-652(ra) # 8000226e <sched>
  p->chan = 0;
    80002502:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002506:	bff9                	j	800024e4 <sleep+0x5a>

0000000080002508 <wait>:
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	e062                	sd	s8,0(sp)
    8000251e:	0880                	addi	s0,sp,80
    80002520:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	758080e7          	jalr	1880(ra) # 80001c7a <myproc>
    8000252a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000252c:	8c2a                	mv	s8,a0
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	87a080e7          	jalr	-1926(ra) # 80000da8 <acquire>
    havekids = 0;
    80002536:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002538:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000253a:	00035997          	auipc	s3,0x35
    8000253e:	24698993          	addi	s3,s3,582 # 80037780 <tickslock>
        havekids = 1;
    80002542:	4a85                	li	s5,1
    havekids = 0;
    80002544:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002546:	00030497          	auipc	s1,0x30
    8000254a:	83a48493          	addi	s1,s1,-1990 # 80031d80 <proc>
    8000254e:	a08d                	j	800025b0 <wait+0xa8>
          pid = np->pid;
    80002550:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002554:	000b0e63          	beqz	s6,80002570 <wait+0x68>
    80002558:	4691                	li	a3,4
    8000255a:	03448613          	addi	a2,s1,52
    8000255e:	85da                	mv	a1,s6
    80002560:	05093503          	ld	a0,80(s2)
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	530080e7          	jalr	1328(ra) # 80001a94 <copyout>
    8000256c:	02054263          	bltz	a0,80002590 <wait+0x88>
          freeproc(np);
    80002570:	8526                	mv	a0,s1
    80002572:	00000097          	auipc	ra,0x0
    80002576:	8ba080e7          	jalr	-1862(ra) # 80001e2c <freeproc>
          release(&np->lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	8e0080e7          	jalr	-1824(ra) # 80000e5c <release>
          release(&p->lock);
    80002584:	854a                	mv	a0,s2
    80002586:	fffff097          	auipc	ra,0xfffff
    8000258a:	8d6080e7          	jalr	-1834(ra) # 80000e5c <release>
          return pid;
    8000258e:	a8a9                	j	800025e8 <wait+0xe0>
            release(&np->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	8ca080e7          	jalr	-1846(ra) # 80000e5c <release>
            release(&p->lock);
    8000259a:	854a                	mv	a0,s2
    8000259c:	fffff097          	auipc	ra,0xfffff
    800025a0:	8c0080e7          	jalr	-1856(ra) # 80000e5c <release>
            return -1;
    800025a4:	59fd                	li	s3,-1
    800025a6:	a089                	j	800025e8 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800025a8:	16848493          	addi	s1,s1,360
    800025ac:	03348463          	beq	s1,s3,800025d4 <wait+0xcc>
      if(np->parent == p){
    800025b0:	709c                	ld	a5,32(s1)
    800025b2:	ff279be3          	bne	a5,s2,800025a8 <wait+0xa0>
        acquire(&np->lock);
    800025b6:	8526                	mv	a0,s1
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	7f0080e7          	jalr	2032(ra) # 80000da8 <acquire>
        if(np->state == ZOMBIE){
    800025c0:	4c9c                	lw	a5,24(s1)
    800025c2:	f94787e3          	beq	a5,s4,80002550 <wait+0x48>
        release(&np->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	fffff097          	auipc	ra,0xfffff
    800025cc:	894080e7          	jalr	-1900(ra) # 80000e5c <release>
        havekids = 1;
    800025d0:	8756                	mv	a4,s5
    800025d2:	bfd9                	j	800025a8 <wait+0xa0>
    if(!havekids || p->killed){
    800025d4:	c701                	beqz	a4,800025dc <wait+0xd4>
    800025d6:	03092783          	lw	a5,48(s2)
    800025da:	c785                	beqz	a5,80002602 <wait+0xfa>
      release(&p->lock);
    800025dc:	854a                	mv	a0,s2
    800025de:	fffff097          	auipc	ra,0xfffff
    800025e2:	87e080e7          	jalr	-1922(ra) # 80000e5c <release>
      return -1;
    800025e6:	59fd                	li	s3,-1
}
    800025e8:	854e                	mv	a0,s3
    800025ea:	60a6                	ld	ra,72(sp)
    800025ec:	6406                	ld	s0,64(sp)
    800025ee:	74e2                	ld	s1,56(sp)
    800025f0:	7942                	ld	s2,48(sp)
    800025f2:	79a2                	ld	s3,40(sp)
    800025f4:	7a02                	ld	s4,32(sp)
    800025f6:	6ae2                	ld	s5,24(sp)
    800025f8:	6b42                	ld	s6,16(sp)
    800025fa:	6ba2                	ld	s7,8(sp)
    800025fc:	6c02                	ld	s8,0(sp)
    800025fe:	6161                	addi	sp,sp,80
    80002600:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002602:	85e2                	mv	a1,s8
    80002604:	854a                	mv	a0,s2
    80002606:	00000097          	auipc	ra,0x0
    8000260a:	e84080e7          	jalr	-380(ra) # 8000248a <sleep>
    havekids = 0;
    8000260e:	bf1d                	j	80002544 <wait+0x3c>

0000000080002610 <wakeup>:
{
    80002610:	7139                	addi	sp,sp,-64
    80002612:	fc06                	sd	ra,56(sp)
    80002614:	f822                	sd	s0,48(sp)
    80002616:	f426                	sd	s1,40(sp)
    80002618:	f04a                	sd	s2,32(sp)
    8000261a:	ec4e                	sd	s3,24(sp)
    8000261c:	e852                	sd	s4,16(sp)
    8000261e:	e456                	sd	s5,8(sp)
    80002620:	0080                	addi	s0,sp,64
    80002622:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002624:	0002f497          	auipc	s1,0x2f
    80002628:	75c48493          	addi	s1,s1,1884 # 80031d80 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000262c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000262e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002630:	00035917          	auipc	s2,0x35
    80002634:	15090913          	addi	s2,s2,336 # 80037780 <tickslock>
    80002638:	a821                	j	80002650 <wakeup+0x40>
      p->state = RUNNABLE;
    8000263a:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	81c080e7          	jalr	-2020(ra) # 80000e5c <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002648:	16848493          	addi	s1,s1,360
    8000264c:	01248e63          	beq	s1,s2,80002668 <wakeup+0x58>
    acquire(&p->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	756080e7          	jalr	1878(ra) # 80000da8 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000265a:	4c9c                	lw	a5,24(s1)
    8000265c:	ff3791e3          	bne	a5,s3,8000263e <wakeup+0x2e>
    80002660:	749c                	ld	a5,40(s1)
    80002662:	fd479ee3          	bne	a5,s4,8000263e <wakeup+0x2e>
    80002666:	bfd1                	j	8000263a <wakeup+0x2a>
}
    80002668:	70e2                	ld	ra,56(sp)
    8000266a:	7442                	ld	s0,48(sp)
    8000266c:	74a2                	ld	s1,40(sp)
    8000266e:	7902                	ld	s2,32(sp)
    80002670:	69e2                	ld	s3,24(sp)
    80002672:	6a42                	ld	s4,16(sp)
    80002674:	6aa2                	ld	s5,8(sp)
    80002676:	6121                	addi	sp,sp,64
    80002678:	8082                	ret

000000008000267a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000267a:	7179                	addi	sp,sp,-48
    8000267c:	f406                	sd	ra,40(sp)
    8000267e:	f022                	sd	s0,32(sp)
    80002680:	ec26                	sd	s1,24(sp)
    80002682:	e84a                	sd	s2,16(sp)
    80002684:	e44e                	sd	s3,8(sp)
    80002686:	1800                	addi	s0,sp,48
    80002688:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000268a:	0002f497          	auipc	s1,0x2f
    8000268e:	6f648493          	addi	s1,s1,1782 # 80031d80 <proc>
    80002692:	00035997          	auipc	s3,0x35
    80002696:	0ee98993          	addi	s3,s3,238 # 80037780 <tickslock>
    acquire(&p->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	70c080e7          	jalr	1804(ra) # 80000da8 <acquire>
    if(p->pid == pid){
    800026a4:	5c9c                	lw	a5,56(s1)
    800026a6:	01278d63          	beq	a5,s2,800026c0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	7b0080e7          	jalr	1968(ra) # 80000e5c <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b4:	16848493          	addi	s1,s1,360
    800026b8:	ff3491e3          	bne	s1,s3,8000269a <kill+0x20>
  }
  return -1;
    800026bc:	557d                	li	a0,-1
    800026be:	a829                	j	800026d8 <kill+0x5e>
      p->killed = 1;
    800026c0:	4785                	li	a5,1
    800026c2:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800026c4:	4c98                	lw	a4,24(s1)
    800026c6:	4785                	li	a5,1
    800026c8:	00f70f63          	beq	a4,a5,800026e6 <kill+0x6c>
      release(&p->lock);
    800026cc:	8526                	mv	a0,s1
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	78e080e7          	jalr	1934(ra) # 80000e5c <release>
      return 0;
    800026d6:	4501                	li	a0,0
}
    800026d8:	70a2                	ld	ra,40(sp)
    800026da:	7402                	ld	s0,32(sp)
    800026dc:	64e2                	ld	s1,24(sp)
    800026de:	6942                	ld	s2,16(sp)
    800026e0:	69a2                	ld	s3,8(sp)
    800026e2:	6145                	addi	sp,sp,48
    800026e4:	8082                	ret
        p->state = RUNNABLE;
    800026e6:	4789                	li	a5,2
    800026e8:	cc9c                	sw	a5,24(s1)
    800026ea:	b7cd                	j	800026cc <kill+0x52>

00000000800026ec <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026ec:	7179                	addi	sp,sp,-48
    800026ee:	f406                	sd	ra,40(sp)
    800026f0:	f022                	sd	s0,32(sp)
    800026f2:	ec26                	sd	s1,24(sp)
    800026f4:	e84a                	sd	s2,16(sp)
    800026f6:	e44e                	sd	s3,8(sp)
    800026f8:	e052                	sd	s4,0(sp)
    800026fa:	1800                	addi	s0,sp,48
    800026fc:	84aa                	mv	s1,a0
    800026fe:	892e                	mv	s2,a1
    80002700:	89b2                	mv	s3,a2
    80002702:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002704:	fffff097          	auipc	ra,0xfffff
    80002708:	576080e7          	jalr	1398(ra) # 80001c7a <myproc>
  if(user_dst){
    8000270c:	c08d                	beqz	s1,8000272e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000270e:	86d2                	mv	a3,s4
    80002710:	864e                	mv	a2,s3
    80002712:	85ca                	mv	a1,s2
    80002714:	6928                	ld	a0,80(a0)
    80002716:	fffff097          	auipc	ra,0xfffff
    8000271a:	37e080e7          	jalr	894(ra) # 80001a94 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000271e:	70a2                	ld	ra,40(sp)
    80002720:	7402                	ld	s0,32(sp)
    80002722:	64e2                	ld	s1,24(sp)
    80002724:	6942                	ld	s2,16(sp)
    80002726:	69a2                	ld	s3,8(sp)
    80002728:	6a02                	ld	s4,0(sp)
    8000272a:	6145                	addi	sp,sp,48
    8000272c:	8082                	ret
    memmove((char *)dst, src, len);
    8000272e:	000a061b          	sext.w	a2,s4
    80002732:	85ce                	mv	a1,s3
    80002734:	854a                	mv	a0,s2
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	7ce080e7          	jalr	1998(ra) # 80000f04 <memmove>
    return 0;
    8000273e:	8526                	mv	a0,s1
    80002740:	bff9                	j	8000271e <either_copyout+0x32>

0000000080002742 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002742:	7179                	addi	sp,sp,-48
    80002744:	f406                	sd	ra,40(sp)
    80002746:	f022                	sd	s0,32(sp)
    80002748:	ec26                	sd	s1,24(sp)
    8000274a:	e84a                	sd	s2,16(sp)
    8000274c:	e44e                	sd	s3,8(sp)
    8000274e:	e052                	sd	s4,0(sp)
    80002750:	1800                	addi	s0,sp,48
    80002752:	892a                	mv	s2,a0
    80002754:	84ae                	mv	s1,a1
    80002756:	89b2                	mv	s3,a2
    80002758:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000275a:	fffff097          	auipc	ra,0xfffff
    8000275e:	520080e7          	jalr	1312(ra) # 80001c7a <myproc>
  if(user_src){
    80002762:	c08d                	beqz	s1,80002784 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002764:	86d2                	mv	a3,s4
    80002766:	864e                	mv	a2,s3
    80002768:	85ca                	mv	a1,s2
    8000276a:	6928                	ld	a0,80(a0)
    8000276c:	fffff097          	auipc	ra,0xfffff
    80002770:	0ec080e7          	jalr	236(ra) # 80001858 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002774:	70a2                	ld	ra,40(sp)
    80002776:	7402                	ld	s0,32(sp)
    80002778:	64e2                	ld	s1,24(sp)
    8000277a:	6942                	ld	s2,16(sp)
    8000277c:	69a2                	ld	s3,8(sp)
    8000277e:	6a02                	ld	s4,0(sp)
    80002780:	6145                	addi	sp,sp,48
    80002782:	8082                	ret
    memmove(dst, (char*)src, len);
    80002784:	000a061b          	sext.w	a2,s4
    80002788:	85ce                	mv	a1,s3
    8000278a:	854a                	mv	a0,s2
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	778080e7          	jalr	1912(ra) # 80000f04 <memmove>
    return 0;
    80002794:	8526                	mv	a0,s1
    80002796:	bff9                	j	80002774 <either_copyin+0x32>

0000000080002798 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002798:	715d                	addi	sp,sp,-80
    8000279a:	e486                	sd	ra,72(sp)
    8000279c:	e0a2                	sd	s0,64(sp)
    8000279e:	fc26                	sd	s1,56(sp)
    800027a0:	f84a                	sd	s2,48(sp)
    800027a2:	f44e                	sd	s3,40(sp)
    800027a4:	f052                	sd	s4,32(sp)
    800027a6:	ec56                	sd	s5,24(sp)
    800027a8:	e85a                	sd	s6,16(sp)
    800027aa:	e45e                	sd	s7,8(sp)
    800027ac:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027ae:	00006517          	auipc	a0,0x6
    800027b2:	92250513          	addi	a0,a0,-1758 # 800080d0 <digits+0x90>
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dea080e7          	jalr	-534(ra) # 800005a0 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027be:	0002f497          	auipc	s1,0x2f
    800027c2:	71a48493          	addi	s1,s1,1818 # 80031ed8 <proc+0x158>
    800027c6:	00035917          	auipc	s2,0x35
    800027ca:	11290913          	addi	s2,s2,274 # 800378d8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ce:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800027d0:	00006997          	auipc	s3,0x6
    800027d4:	ad098993          	addi	s3,s3,-1328 # 800082a0 <digits+0x260>
    printf("%d %s %s", p->pid, state, p->name);
    800027d8:	00006a97          	auipc	s5,0x6
    800027dc:	ad0a8a93          	addi	s5,s5,-1328 # 800082a8 <digits+0x268>
    printf("\n");
    800027e0:	00006a17          	auipc	s4,0x6
    800027e4:	8f0a0a13          	addi	s4,s4,-1808 # 800080d0 <digits+0x90>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027e8:	00006b97          	auipc	s7,0x6
    800027ec:	af8b8b93          	addi	s7,s7,-1288 # 800082e0 <states.1716>
    800027f0:	a00d                	j	80002812 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027f2:	ee06a583          	lw	a1,-288(a3)
    800027f6:	8556                	mv	a0,s5
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	da8080e7          	jalr	-600(ra) # 800005a0 <printf>
    printf("\n");
    80002800:	8552                	mv	a0,s4
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	d9e080e7          	jalr	-610(ra) # 800005a0 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000280a:	16848493          	addi	s1,s1,360
    8000280e:	03248163          	beq	s1,s2,80002830 <procdump+0x98>
    if(p->state == UNUSED)
    80002812:	86a6                	mv	a3,s1
    80002814:	ec04a783          	lw	a5,-320(s1)
    80002818:	dbed                	beqz	a5,8000280a <procdump+0x72>
      state = "???";
    8000281a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000281c:	fcfb6be3          	bltu	s6,a5,800027f2 <procdump+0x5a>
    80002820:	1782                	slli	a5,a5,0x20
    80002822:	9381                	srli	a5,a5,0x20
    80002824:	078e                	slli	a5,a5,0x3
    80002826:	97de                	add	a5,a5,s7
    80002828:	6390                	ld	a2,0(a5)
    8000282a:	f661                	bnez	a2,800027f2 <procdump+0x5a>
      state = "???";
    8000282c:	864e                	mv	a2,s3
    8000282e:	b7d1                	j	800027f2 <procdump+0x5a>
  }
}
    80002830:	60a6                	ld	ra,72(sp)
    80002832:	6406                	ld	s0,64(sp)
    80002834:	74e2                	ld	s1,56(sp)
    80002836:	7942                	ld	s2,48(sp)
    80002838:	79a2                	ld	s3,40(sp)
    8000283a:	7a02                	ld	s4,32(sp)
    8000283c:	6ae2                	ld	s5,24(sp)
    8000283e:	6b42                	ld	s6,16(sp)
    80002840:	6ba2                	ld	s7,8(sp)
    80002842:	6161                	addi	sp,sp,80
    80002844:	8082                	ret

0000000080002846 <swtch>:
    80002846:	00153023          	sd	ra,0(a0)
    8000284a:	00253423          	sd	sp,8(a0)
    8000284e:	e900                	sd	s0,16(a0)
    80002850:	ed04                	sd	s1,24(a0)
    80002852:	03253023          	sd	s2,32(a0)
    80002856:	03353423          	sd	s3,40(a0)
    8000285a:	03453823          	sd	s4,48(a0)
    8000285e:	03553c23          	sd	s5,56(a0)
    80002862:	05653023          	sd	s6,64(a0)
    80002866:	05753423          	sd	s7,72(a0)
    8000286a:	05853823          	sd	s8,80(a0)
    8000286e:	05953c23          	sd	s9,88(a0)
    80002872:	07a53023          	sd	s10,96(a0)
    80002876:	07b53423          	sd	s11,104(a0)
    8000287a:	0005b083          	ld	ra,0(a1)
    8000287e:	0085b103          	ld	sp,8(a1)
    80002882:	6980                	ld	s0,16(a1)
    80002884:	6d84                	ld	s1,24(a1)
    80002886:	0205b903          	ld	s2,32(a1)
    8000288a:	0285b983          	ld	s3,40(a1)
    8000288e:	0305ba03          	ld	s4,48(a1)
    80002892:	0385ba83          	ld	s5,56(a1)
    80002896:	0405bb03          	ld	s6,64(a1)
    8000289a:	0485bb83          	ld	s7,72(a1)
    8000289e:	0505bc03          	ld	s8,80(a1)
    800028a2:	0585bc83          	ld	s9,88(a1)
    800028a6:	0605bd03          	ld	s10,96(a1)
    800028aa:	0685bd83          	ld	s11,104(a1)
    800028ae:	8082                	ret

00000000800028b0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028b0:	1141                	addi	sp,sp,-16
    800028b2:	e406                	sd	ra,8(sp)
    800028b4:	e022                	sd	s0,0(sp)
    800028b6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028b8:	00006597          	auipc	a1,0x6
    800028bc:	a5058593          	addi	a1,a1,-1456 # 80008308 <states.1716+0x28>
    800028c0:	00035517          	auipc	a0,0x35
    800028c4:	ec050513          	addi	a0,a0,-320 # 80037780 <tickslock>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	450080e7          	jalr	1104(ra) # 80000d18 <initlock>
}
    800028d0:	60a2                	ld	ra,8(sp)
    800028d2:	6402                	ld	s0,0(sp)
    800028d4:	0141                	addi	sp,sp,16
    800028d6:	8082                	ret

00000000800028d8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800028d8:	1141                	addi	sp,sp,-16
    800028da:	e422                	sd	s0,8(sp)
    800028dc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028de:	00003797          	auipc	a5,0x3
    800028e2:	50278793          	addi	a5,a5,1282 # 80005de0 <kernelvec>
    800028e6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028ea:	6422                	ld	s0,8(sp)
    800028ec:	0141                	addi	sp,sp,16
    800028ee:	8082                	ret

00000000800028f0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028f0:	1141                	addi	sp,sp,-16
    800028f2:	e406                	sd	ra,8(sp)
    800028f4:	e022                	sd	s0,0(sp)
    800028f6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028f8:	fffff097          	auipc	ra,0xfffff
    800028fc:	382080e7          	jalr	898(ra) # 80001c7a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002900:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002904:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002906:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000290a:	00004617          	auipc	a2,0x4
    8000290e:	6f660613          	addi	a2,a2,1782 # 80007000 <_trampoline>
    80002912:	00004697          	auipc	a3,0x4
    80002916:	6ee68693          	addi	a3,a3,1774 # 80007000 <_trampoline>
    8000291a:	8e91                	sub	a3,a3,a2
    8000291c:	040007b7          	lui	a5,0x4000
    80002920:	17fd                	addi	a5,a5,-1
    80002922:	07b2                	slli	a5,a5,0xc
    80002924:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002926:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000292a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000292c:	180026f3          	csrr	a3,satp
    80002930:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002932:	6d38                	ld	a4,88(a0)
    80002934:	6134                	ld	a3,64(a0)
    80002936:	6585                	lui	a1,0x1
    80002938:	96ae                	add	a3,a3,a1
    8000293a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000293c:	6d38                	ld	a4,88(a0)
    8000293e:	00000697          	auipc	a3,0x0
    80002942:	13868693          	addi	a3,a3,312 # 80002a76 <usertrap>
    80002946:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002948:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000294a:	8692                	mv	a3,tp
    8000294c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002952:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002956:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000295e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002960:	6f18                	ld	a4,24(a4)
    80002962:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002966:	692c                	ld	a1,80(a0)
    80002968:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000296a:	00004717          	auipc	a4,0x4
    8000296e:	72670713          	addi	a4,a4,1830 # 80007090 <userret>
    80002972:	8f11                	sub	a4,a4,a2
    80002974:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002976:	577d                	li	a4,-1
    80002978:	177e                	slli	a4,a4,0x3f
    8000297a:	8dd9                	or	a1,a1,a4
    8000297c:	02000537          	lui	a0,0x2000
    80002980:	157d                	addi	a0,a0,-1
    80002982:	0536                	slli	a0,a0,0xd
    80002984:	9782                	jalr	a5
}
    80002986:	60a2                	ld	ra,8(sp)
    80002988:	6402                	ld	s0,0(sp)
    8000298a:	0141                	addi	sp,sp,16
    8000298c:	8082                	ret

000000008000298e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000298e:	1101                	addi	sp,sp,-32
    80002990:	ec06                	sd	ra,24(sp)
    80002992:	e822                	sd	s0,16(sp)
    80002994:	e426                	sd	s1,8(sp)
    80002996:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002998:	00035497          	auipc	s1,0x35
    8000299c:	de848493          	addi	s1,s1,-536 # 80037780 <tickslock>
    800029a0:	8526                	mv	a0,s1
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	406080e7          	jalr	1030(ra) # 80000da8 <acquire>
  ticks++;
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	67650513          	addi	a0,a0,1654 # 80009020 <ticks>
    800029b2:	411c                	lw	a5,0(a0)
    800029b4:	2785                	addiw	a5,a5,1
    800029b6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029b8:	00000097          	auipc	ra,0x0
    800029bc:	c58080e7          	jalr	-936(ra) # 80002610 <wakeup>
  release(&tickslock);
    800029c0:	8526                	mv	a0,s1
    800029c2:	ffffe097          	auipc	ra,0xffffe
    800029c6:	49a080e7          	jalr	1178(ra) # 80000e5c <release>
}
    800029ca:	60e2                	ld	ra,24(sp)
    800029cc:	6442                	ld	s0,16(sp)
    800029ce:	64a2                	ld	s1,8(sp)
    800029d0:	6105                	addi	sp,sp,32
    800029d2:	8082                	ret

00000000800029d4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800029d4:	1101                	addi	sp,sp,-32
    800029d6:	ec06                	sd	ra,24(sp)
    800029d8:	e822                	sd	s0,16(sp)
    800029da:	e426                	sd	s1,8(sp)
    800029dc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029de:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800029e2:	00074d63          	bltz	a4,800029fc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029e6:	57fd                	li	a5,-1
    800029e8:	17fe                	slli	a5,a5,0x3f
    800029ea:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029ec:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029ee:	06f70363          	beq	a4,a5,80002a54 <devintr+0x80>
  }
}
    800029f2:	60e2                	ld	ra,24(sp)
    800029f4:	6442                	ld	s0,16(sp)
    800029f6:	64a2                	ld	s1,8(sp)
    800029f8:	6105                	addi	sp,sp,32
    800029fa:	8082                	ret
     (scause & 0xff) == 9){
    800029fc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a00:	46a5                	li	a3,9
    80002a02:	fed792e3          	bne	a5,a3,800029e6 <devintr+0x12>
    int irq = plic_claim();
    80002a06:	00003097          	auipc	ra,0x3
    80002a0a:	4fe080e7          	jalr	1278(ra) # 80005f04 <plic_claim>
    80002a0e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a10:	47a9                	li	a5,10
    80002a12:	02f50763          	beq	a0,a5,80002a40 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a16:	4785                	li	a5,1
    80002a18:	02f50963          	beq	a0,a5,80002a4a <devintr+0x76>
    return 1;
    80002a1c:	4505                	li	a0,1
    } else if(irq){
    80002a1e:	d8f1                	beqz	s1,800029f2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a20:	85a6                	mv	a1,s1
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	8ee50513          	addi	a0,a0,-1810 # 80008310 <states.1716+0x30>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b76080e7          	jalr	-1162(ra) # 800005a0 <printf>
      plic_complete(irq);
    80002a32:	8526                	mv	a0,s1
    80002a34:	00003097          	auipc	ra,0x3
    80002a38:	4f4080e7          	jalr	1268(ra) # 80005f28 <plic_complete>
    return 1;
    80002a3c:	4505                	li	a0,1
    80002a3e:	bf55                	j	800029f2 <devintr+0x1e>
      uartintr();
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	fa2080e7          	jalr	-94(ra) # 800009e2 <uartintr>
    80002a48:	b7ed                	j	80002a32 <devintr+0x5e>
      virtio_disk_intr();
    80002a4a:	00004097          	auipc	ra,0x4
    80002a4e:	978080e7          	jalr	-1672(ra) # 800063c2 <virtio_disk_intr>
    80002a52:	b7c5                	j	80002a32 <devintr+0x5e>
    if(cpuid() == 0){
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	1fa080e7          	jalr	506(ra) # 80001c4e <cpuid>
    80002a5c:	c901                	beqz	a0,80002a6c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a5e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a62:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a64:	14479073          	csrw	sip,a5
    return 2;
    80002a68:	4509                	li	a0,2
    80002a6a:	b761                	j	800029f2 <devintr+0x1e>
      clockintr();
    80002a6c:	00000097          	auipc	ra,0x0
    80002a70:	f22080e7          	jalr	-222(ra) # 8000298e <clockintr>
    80002a74:	b7ed                	j	80002a5e <devintr+0x8a>

0000000080002a76 <usertrap>:
{
    80002a76:	1101                	addi	sp,sp,-32
    80002a78:	ec06                	sd	ra,24(sp)
    80002a7a:	e822                	sd	s0,16(sp)
    80002a7c:	e426                	sd	s1,8(sp)
    80002a7e:	e04a                	sd	s2,0(sp)
    80002a80:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a82:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a86:	1007f793          	andi	a5,a5,256
    80002a8a:	e3ad                	bnez	a5,80002aec <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a8c:	00003797          	auipc	a5,0x3
    80002a90:	35478793          	addi	a5,a5,852 # 80005de0 <kernelvec>
    80002a94:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	1e2080e7          	jalr	482(ra) # 80001c7a <myproc>
    80002aa0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002aa2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa4:	14102773          	csrr	a4,sepc
    80002aa8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aaa:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002aae:	47a1                	li	a5,8
    80002ab0:	04f71c63          	bne	a4,a5,80002b08 <usertrap+0x92>
    if(p->killed)
    80002ab4:	591c                	lw	a5,48(a0)
    80002ab6:	e3b9                	bnez	a5,80002afc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ab8:	6cb8                	ld	a4,88(s1)
    80002aba:	6f1c                	ld	a5,24(a4)
    80002abc:	0791                	addi	a5,a5,4
    80002abe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ac4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ac8:	10079073          	csrw	sstatus,a5
    syscall();
    80002acc:	00000097          	auipc	ra,0x0
    80002ad0:	31a080e7          	jalr	794(ra) # 80002de6 <syscall>
  if(p->killed)
    80002ad4:	589c                	lw	a5,48(s1)
    80002ad6:	e7e9                	bnez	a5,80002ba0 <usertrap+0x12a>
  usertrapret();
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	e18080e7          	jalr	-488(ra) # 800028f0 <usertrapret>
}
    80002ae0:	60e2                	ld	ra,24(sp)
    80002ae2:	6442                	ld	s0,16(sp)
    80002ae4:	64a2                	ld	s1,8(sp)
    80002ae6:	6902                	ld	s2,0(sp)
    80002ae8:	6105                	addi	sp,sp,32
    80002aea:	8082                	ret
    panic("usertrap: not from user mode");
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	84450513          	addi	a0,a0,-1980 # 80008330 <states.1716+0x50>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a62080e7          	jalr	-1438(ra) # 80000556 <panic>
      exit(-1);
    80002afc:	557d                	li	a0,-1
    80002afe:	00000097          	auipc	ra,0x0
    80002b02:	846080e7          	jalr	-1978(ra) # 80002344 <exit>
    80002b06:	bf4d                	j	80002ab8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	ecc080e7          	jalr	-308(ra) # 800029d4 <devintr>
    80002b10:	892a                	mv	s2,a0
    80002b12:	e541                	bnez	a0,80002b9a <usertrap+0x124>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b14:	14202773          	csrr	a4,scause
  } else if((r_scause() == 13 || r_scause() == 15) && uvmcheckcowpage(r_stval())) { // copy-on-write
    80002b18:	47b5                	li	a5,13
    80002b1a:	04f70d63          	beq	a4,a5,80002b74 <usertrap+0xfe>
    80002b1e:	14202773          	csrr	a4,scause
    80002b22:	47bd                	li	a5,15
    80002b24:	04f70863          	beq	a4,a5,80002b74 <usertrap+0xfe>
    80002b28:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b2c:	5c90                	lw	a2,56(s1)
    80002b2e:	00006517          	auipc	a0,0x6
    80002b32:	82250513          	addi	a0,a0,-2014 # 80008350 <states.1716+0x70>
    80002b36:	ffffe097          	auipc	ra,0xffffe
    80002b3a:	a6a080e7          	jalr	-1430(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b42:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b46:	00006517          	auipc	a0,0x6
    80002b4a:	83a50513          	addi	a0,a0,-1990 # 80008380 <states.1716+0xa0>
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	a52080e7          	jalr	-1454(ra) # 800005a0 <printf>
    p->killed = 1;
    80002b56:	4785                	li	a5,1
    80002b58:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002b5a:	557d                	li	a0,-1
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	7e8080e7          	jalr	2024(ra) # 80002344 <exit>
  if(which_dev == 2)
    80002b64:	4789                	li	a5,2
    80002b66:	f6f919e3          	bne	s2,a5,80002ad8 <usertrap+0x62>
    yield();
    80002b6a:	00000097          	auipc	ra,0x0
    80002b6e:	8e4080e7          	jalr	-1820(ra) # 8000244e <yield>
    80002b72:	b79d                	j	80002ad8 <usertrap+0x62>
    80002b74:	14302573          	csrr	a0,stval
  } else if((r_scause() == 13 || r_scause() == 15) && uvmcheckcowpage(r_stval())) { // copy-on-write
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	e20080e7          	jalr	-480(ra) # 80001998 <uvmcheckcowpage>
    80002b80:	d545                	beqz	a0,80002b28 <usertrap+0xb2>
    80002b82:	14302573          	csrr	a0,stval
    if(uvmcowcopy(r_stval()) == -1){
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	e5c080e7          	jalr	-420(ra) # 800019e2 <uvmcowcopy>
    80002b8e:	57fd                	li	a5,-1
    80002b90:	f4f512e3          	bne	a0,a5,80002ad4 <usertrap+0x5e>
      p->killed = 1;
    80002b94:	4785                	li	a5,1
    80002b96:	d89c                	sw	a5,48(s1)
    80002b98:	b7c9                	j	80002b5a <usertrap+0xe4>
  if(p->killed)
    80002b9a:	589c                	lw	a5,48(s1)
    80002b9c:	d7e1                	beqz	a5,80002b64 <usertrap+0xee>
    80002b9e:	bf75                	j	80002b5a <usertrap+0xe4>
    80002ba0:	4901                	li	s2,0
    80002ba2:	bf65                	j	80002b5a <usertrap+0xe4>

0000000080002ba4 <kerneltrap>:
{
    80002ba4:	7179                	addi	sp,sp,-48
    80002ba6:	f406                	sd	ra,40(sp)
    80002ba8:	f022                	sd	s0,32(sp)
    80002baa:	ec26                	sd	s1,24(sp)
    80002bac:	e84a                	sd	s2,16(sp)
    80002bae:	e44e                	sd	s3,8(sp)
    80002bb0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bbe:	1004f793          	andi	a5,s1,256
    80002bc2:	cb85                	beqz	a5,80002bf2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bc8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bca:	ef85                	bnez	a5,80002c02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	e08080e7          	jalr	-504(ra) # 800029d4 <devintr>
    80002bd4:	cd1d                	beqz	a0,80002c12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bd6:	4789                	li	a5,2
    80002bd8:	06f50a63          	beq	a0,a5,80002c4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bdc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be0:	10049073          	csrw	sstatus,s1
}
    80002be4:	70a2                	ld	ra,40(sp)
    80002be6:	7402                	ld	s0,32(sp)
    80002be8:	64e2                	ld	s1,24(sp)
    80002bea:	6942                	ld	s2,16(sp)
    80002bec:	69a2                	ld	s3,8(sp)
    80002bee:	6145                	addi	sp,sp,48
    80002bf0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002bf2:	00005517          	auipc	a0,0x5
    80002bf6:	7ae50513          	addi	a0,a0,1966 # 800083a0 <states.1716+0xc0>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	95c080e7          	jalr	-1700(ra) # 80000556 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	7c650513          	addi	a0,a0,1990 # 800083c8 <states.1716+0xe8>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	94c080e7          	jalr	-1716(ra) # 80000556 <panic>
    printf("scause %p\n", scause);
    80002c12:	85ce                	mv	a1,s3
    80002c14:	00005517          	auipc	a0,0x5
    80002c18:	7d450513          	addi	a0,a0,2004 # 800083e8 <states.1716+0x108>
    80002c1c:	ffffe097          	auipc	ra,0xffffe
    80002c20:	984080e7          	jalr	-1660(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c2c:	00005517          	auipc	a0,0x5
    80002c30:	7cc50513          	addi	a0,a0,1996 # 800083f8 <states.1716+0x118>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	96c080e7          	jalr	-1684(ra) # 800005a0 <printf>
    panic("kerneltrap");
    80002c3c:	00005517          	auipc	a0,0x5
    80002c40:	7d450513          	addi	a0,a0,2004 # 80008410 <states.1716+0x130>
    80002c44:	ffffe097          	auipc	ra,0xffffe
    80002c48:	912080e7          	jalr	-1774(ra) # 80000556 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	02e080e7          	jalr	46(ra) # 80001c7a <myproc>
    80002c54:	d541                	beqz	a0,80002bdc <kerneltrap+0x38>
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	024080e7          	jalr	36(ra) # 80001c7a <myproc>
    80002c5e:	4d18                	lw	a4,24(a0)
    80002c60:	478d                	li	a5,3
    80002c62:	f6f71de3          	bne	a4,a5,80002bdc <kerneltrap+0x38>
    yield();
    80002c66:	fffff097          	auipc	ra,0xfffff
    80002c6a:	7e8080e7          	jalr	2024(ra) # 8000244e <yield>
    80002c6e:	b7bd                	j	80002bdc <kerneltrap+0x38>

0000000080002c70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c70:	1101                	addi	sp,sp,-32
    80002c72:	ec06                	sd	ra,24(sp)
    80002c74:	e822                	sd	s0,16(sp)
    80002c76:	e426                	sd	s1,8(sp)
    80002c78:	1000                	addi	s0,sp,32
    80002c7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	ffe080e7          	jalr	-2(ra) # 80001c7a <myproc>
  switch (n) {
    80002c84:	4795                	li	a5,5
    80002c86:	0497e163          	bltu	a5,s1,80002cc8 <argraw+0x58>
    80002c8a:	048a                	slli	s1,s1,0x2
    80002c8c:	00005717          	auipc	a4,0x5
    80002c90:	7bc70713          	addi	a4,a4,1980 # 80008448 <states.1716+0x168>
    80002c94:	94ba                	add	s1,s1,a4
    80002c96:	409c                	lw	a5,0(s1)
    80002c98:	97ba                	add	a5,a5,a4
    80002c9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c9c:	6d3c                	ld	a5,88(a0)
    80002c9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	64a2                	ld	s1,8(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret
    return p->trapframe->a1;
    80002caa:	6d3c                	ld	a5,88(a0)
    80002cac:	7fa8                	ld	a0,120(a5)
    80002cae:	bfcd                	j	80002ca0 <argraw+0x30>
    return p->trapframe->a2;
    80002cb0:	6d3c                	ld	a5,88(a0)
    80002cb2:	63c8                	ld	a0,128(a5)
    80002cb4:	b7f5                	j	80002ca0 <argraw+0x30>
    return p->trapframe->a3;
    80002cb6:	6d3c                	ld	a5,88(a0)
    80002cb8:	67c8                	ld	a0,136(a5)
    80002cba:	b7dd                	j	80002ca0 <argraw+0x30>
    return p->trapframe->a4;
    80002cbc:	6d3c                	ld	a5,88(a0)
    80002cbe:	6bc8                	ld	a0,144(a5)
    80002cc0:	b7c5                	j	80002ca0 <argraw+0x30>
    return p->trapframe->a5;
    80002cc2:	6d3c                	ld	a5,88(a0)
    80002cc4:	6fc8                	ld	a0,152(a5)
    80002cc6:	bfe9                	j	80002ca0 <argraw+0x30>
  panic("argraw");
    80002cc8:	00005517          	auipc	a0,0x5
    80002ccc:	75850513          	addi	a0,a0,1880 # 80008420 <states.1716+0x140>
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	886080e7          	jalr	-1914(ra) # 80000556 <panic>

0000000080002cd8 <fetchaddr>:
{
    80002cd8:	1101                	addi	sp,sp,-32
    80002cda:	ec06                	sd	ra,24(sp)
    80002cdc:	e822                	sd	s0,16(sp)
    80002cde:	e426                	sd	s1,8(sp)
    80002ce0:	e04a                	sd	s2,0(sp)
    80002ce2:	1000                	addi	s0,sp,32
    80002ce4:	84aa                	mv	s1,a0
    80002ce6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	f92080e7          	jalr	-110(ra) # 80001c7a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002cf0:	653c                	ld	a5,72(a0)
    80002cf2:	02f4f863          	bgeu	s1,a5,80002d22 <fetchaddr+0x4a>
    80002cf6:	00848713          	addi	a4,s1,8
    80002cfa:	02e7e663          	bltu	a5,a4,80002d26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cfe:	46a1                	li	a3,8
    80002d00:	8626                	mv	a2,s1
    80002d02:	85ca                	mv	a1,s2
    80002d04:	6928                	ld	a0,80(a0)
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	b52080e7          	jalr	-1198(ra) # 80001858 <copyin>
    80002d0e:	00a03533          	snez	a0,a0
    80002d12:	40a00533          	neg	a0,a0
}
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	64a2                	ld	s1,8(sp)
    80002d1c:	6902                	ld	s2,0(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret
    return -1;
    80002d22:	557d                	li	a0,-1
    80002d24:	bfcd                	j	80002d16 <fetchaddr+0x3e>
    80002d26:	557d                	li	a0,-1
    80002d28:	b7fd                	j	80002d16 <fetchaddr+0x3e>

0000000080002d2a <fetchstr>:
{
    80002d2a:	7179                	addi	sp,sp,-48
    80002d2c:	f406                	sd	ra,40(sp)
    80002d2e:	f022                	sd	s0,32(sp)
    80002d30:	ec26                	sd	s1,24(sp)
    80002d32:	e84a                	sd	s2,16(sp)
    80002d34:	e44e                	sd	s3,8(sp)
    80002d36:	1800                	addi	s0,sp,48
    80002d38:	892a                	mv	s2,a0
    80002d3a:	84ae                	mv	s1,a1
    80002d3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	f3c080e7          	jalr	-196(ra) # 80001c7a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d46:	86ce                	mv	a3,s3
    80002d48:	864a                	mv	a2,s2
    80002d4a:	85a6                	mv	a1,s1
    80002d4c:	6928                	ld	a0,80(a0)
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	b96080e7          	jalr	-1130(ra) # 800018e4 <copyinstr>
  if(err < 0)
    80002d56:	00054763          	bltz	a0,80002d64 <fetchstr+0x3a>
  return strlen(buf);
    80002d5a:	8526                	mv	a0,s1
    80002d5c:	ffffe097          	auipc	ra,0xffffe
    80002d60:	2d0080e7          	jalr	720(ra) # 8000102c <strlen>
}
    80002d64:	70a2                	ld	ra,40(sp)
    80002d66:	7402                	ld	s0,32(sp)
    80002d68:	64e2                	ld	s1,24(sp)
    80002d6a:	6942                	ld	s2,16(sp)
    80002d6c:	69a2                	ld	s3,8(sp)
    80002d6e:	6145                	addi	sp,sp,48
    80002d70:	8082                	ret

0000000080002d72 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	1000                	addi	s0,sp,32
    80002d7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	ef2080e7          	jalr	-270(ra) # 80002c70 <argraw>
    80002d86:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d88:	4501                	li	a0,0
    80002d8a:	60e2                	ld	ra,24(sp)
    80002d8c:	6442                	ld	s0,16(sp)
    80002d8e:	64a2                	ld	s1,8(sp)
    80002d90:	6105                	addi	sp,sp,32
    80002d92:	8082                	ret

0000000080002d94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002d94:	1101                	addi	sp,sp,-32
    80002d96:	ec06                	sd	ra,24(sp)
    80002d98:	e822                	sd	s0,16(sp)
    80002d9a:	e426                	sd	s1,8(sp)
    80002d9c:	1000                	addi	s0,sp,32
    80002d9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	ed0080e7          	jalr	-304(ra) # 80002c70 <argraw>
    80002da8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002daa:	4501                	li	a0,0
    80002dac:	60e2                	ld	ra,24(sp)
    80002dae:	6442                	ld	s0,16(sp)
    80002db0:	64a2                	ld	s1,8(sp)
    80002db2:	6105                	addi	sp,sp,32
    80002db4:	8082                	ret

0000000080002db6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002db6:	1101                	addi	sp,sp,-32
    80002db8:	ec06                	sd	ra,24(sp)
    80002dba:	e822                	sd	s0,16(sp)
    80002dbc:	e426                	sd	s1,8(sp)
    80002dbe:	e04a                	sd	s2,0(sp)
    80002dc0:	1000                	addi	s0,sp,32
    80002dc2:	84ae                	mv	s1,a1
    80002dc4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dc6:	00000097          	auipc	ra,0x0
    80002dca:	eaa080e7          	jalr	-342(ra) # 80002c70 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dce:	864a                	mv	a2,s2
    80002dd0:	85a6                	mv	a1,s1
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	f58080e7          	jalr	-168(ra) # 80002d2a <fetchstr>
}
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6902                	ld	s2,0(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	e04a                	sd	s2,0(sp)
    80002df0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	e88080e7          	jalr	-376(ra) # 80001c7a <myproc>
    80002dfa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002dfc:	05853903          	ld	s2,88(a0)
    80002e00:	0a893783          	ld	a5,168(s2)
    80002e04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e08:	37fd                	addiw	a5,a5,-1
    80002e0a:	4751                	li	a4,20
    80002e0c:	00f76f63          	bltu	a4,a5,80002e2a <syscall+0x44>
    80002e10:	00369713          	slli	a4,a3,0x3
    80002e14:	00005797          	auipc	a5,0x5
    80002e18:	64c78793          	addi	a5,a5,1612 # 80008460 <syscalls>
    80002e1c:	97ba                	add	a5,a5,a4
    80002e1e:	639c                	ld	a5,0(a5)
    80002e20:	c789                	beqz	a5,80002e2a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e22:	9782                	jalr	a5
    80002e24:	06a93823          	sd	a0,112(s2)
    80002e28:	a839                	j	80002e46 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e2a:	15848613          	addi	a2,s1,344
    80002e2e:	5c8c                	lw	a1,56(s1)
    80002e30:	00005517          	auipc	a0,0x5
    80002e34:	5f850513          	addi	a0,a0,1528 # 80008428 <states.1716+0x148>
    80002e38:	ffffd097          	auipc	ra,0xffffd
    80002e3c:	768080e7          	jalr	1896(ra) # 800005a0 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e40:	6cbc                	ld	a5,88(s1)
    80002e42:	577d                	li	a4,-1
    80002e44:	fbb8                	sd	a4,112(a5)
  }
}
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	64a2                	ld	s1,8(sp)
    80002e4c:	6902                	ld	s2,0(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e52:	1101                	addi	sp,sp,-32
    80002e54:	ec06                	sd	ra,24(sp)
    80002e56:	e822                	sd	s0,16(sp)
    80002e58:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e5a:	fec40593          	addi	a1,s0,-20
    80002e5e:	4501                	li	a0,0
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	f12080e7          	jalr	-238(ra) # 80002d72 <argint>
    return -1;
    80002e68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e6a:	00054963          	bltz	a0,80002e7c <sys_exit+0x2a>
  exit(n);
    80002e6e:	fec42503          	lw	a0,-20(s0)
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	4d2080e7          	jalr	1234(ra) # 80002344 <exit>
  return 0;  // not reached
    80002e7a:	4781                	li	a5,0
}
    80002e7c:	853e                	mv	a0,a5
    80002e7e:	60e2                	ld	ra,24(sp)
    80002e80:	6442                	ld	s0,16(sp)
    80002e82:	6105                	addi	sp,sp,32
    80002e84:	8082                	ret

0000000080002e86 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e86:	1141                	addi	sp,sp,-16
    80002e88:	e406                	sd	ra,8(sp)
    80002e8a:	e022                	sd	s0,0(sp)
    80002e8c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e8e:	fffff097          	auipc	ra,0xfffff
    80002e92:	dec080e7          	jalr	-532(ra) # 80001c7a <myproc>
}
    80002e96:	5d08                	lw	a0,56(a0)
    80002e98:	60a2                	ld	ra,8(sp)
    80002e9a:	6402                	ld	s0,0(sp)
    80002e9c:	0141                	addi	sp,sp,16
    80002e9e:	8082                	ret

0000000080002ea0 <sys_fork>:

uint64
sys_fork(void)
{
    80002ea0:	1141                	addi	sp,sp,-16
    80002ea2:	e406                	sd	ra,8(sp)
    80002ea4:	e022                	sd	s0,0(sp)
    80002ea6:	0800                	addi	s0,sp,16
  return fork();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	192080e7          	jalr	402(ra) # 8000203a <fork>
}
    80002eb0:	60a2                	ld	ra,8(sp)
    80002eb2:	6402                	ld	s0,0(sp)
    80002eb4:	0141                	addi	sp,sp,16
    80002eb6:	8082                	ret

0000000080002eb8 <sys_wait>:

uint64
sys_wait(void)
{
    80002eb8:	1101                	addi	sp,sp,-32
    80002eba:	ec06                	sd	ra,24(sp)
    80002ebc:	e822                	sd	s0,16(sp)
    80002ebe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ec0:	fe840593          	addi	a1,s0,-24
    80002ec4:	4501                	li	a0,0
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	ece080e7          	jalr	-306(ra) # 80002d94 <argaddr>
    80002ece:	87aa                	mv	a5,a0
    return -1;
    80002ed0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ed2:	0007c863          	bltz	a5,80002ee2 <sys_wait+0x2a>
  return wait(p);
    80002ed6:	fe843503          	ld	a0,-24(s0)
    80002eda:	fffff097          	auipc	ra,0xfffff
    80002ede:	62e080e7          	jalr	1582(ra) # 80002508 <wait>
}
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret

0000000080002eea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002eea:	7179                	addi	sp,sp,-48
    80002eec:	f406                	sd	ra,40(sp)
    80002eee:	f022                	sd	s0,32(sp)
    80002ef0:	ec26                	sd	s1,24(sp)
    80002ef2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ef4:	fdc40593          	addi	a1,s0,-36
    80002ef8:	4501                	li	a0,0
    80002efa:	00000097          	auipc	ra,0x0
    80002efe:	e78080e7          	jalr	-392(ra) # 80002d72 <argint>
    80002f02:	87aa                	mv	a5,a0
    return -1;
    80002f04:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f06:	0207c063          	bltz	a5,80002f26 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	d70080e7          	jalr	-656(ra) # 80001c7a <myproc>
    80002f12:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f14:	fdc42503          	lw	a0,-36(s0)
    80002f18:	fffff097          	auipc	ra,0xfffff
    80002f1c:	0ae080e7          	jalr	174(ra) # 80001fc6 <growproc>
    80002f20:	00054863          	bltz	a0,80002f30 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f24:	8526                	mv	a0,s1
}
    80002f26:	70a2                	ld	ra,40(sp)
    80002f28:	7402                	ld	s0,32(sp)
    80002f2a:	64e2                	ld	s1,24(sp)
    80002f2c:	6145                	addi	sp,sp,48
    80002f2e:	8082                	ret
    return -1;
    80002f30:	557d                	li	a0,-1
    80002f32:	bfd5                	j	80002f26 <sys_sbrk+0x3c>

0000000080002f34 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f34:	7139                	addi	sp,sp,-64
    80002f36:	fc06                	sd	ra,56(sp)
    80002f38:	f822                	sd	s0,48(sp)
    80002f3a:	f426                	sd	s1,40(sp)
    80002f3c:	f04a                	sd	s2,32(sp)
    80002f3e:	ec4e                	sd	s3,24(sp)
    80002f40:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f42:	fcc40593          	addi	a1,s0,-52
    80002f46:	4501                	li	a0,0
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	e2a080e7          	jalr	-470(ra) # 80002d72 <argint>
    return -1;
    80002f50:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f52:	06054563          	bltz	a0,80002fbc <sys_sleep+0x88>
  acquire(&tickslock);
    80002f56:	00035517          	auipc	a0,0x35
    80002f5a:	82a50513          	addi	a0,a0,-2006 # 80037780 <tickslock>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	e4a080e7          	jalr	-438(ra) # 80000da8 <acquire>
  ticks0 = ticks;
    80002f66:	00006917          	auipc	s2,0x6
    80002f6a:	0ba92903          	lw	s2,186(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f6e:	fcc42783          	lw	a5,-52(s0)
    80002f72:	cf85                	beqz	a5,80002faa <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f74:	00035997          	auipc	s3,0x35
    80002f78:	80c98993          	addi	s3,s3,-2036 # 80037780 <tickslock>
    80002f7c:	00006497          	auipc	s1,0x6
    80002f80:	0a448493          	addi	s1,s1,164 # 80009020 <ticks>
    if(myproc()->killed){
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	cf6080e7          	jalr	-778(ra) # 80001c7a <myproc>
    80002f8c:	591c                	lw	a5,48(a0)
    80002f8e:	ef9d                	bnez	a5,80002fcc <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002f90:	85ce                	mv	a1,s3
    80002f92:	8526                	mv	a0,s1
    80002f94:	fffff097          	auipc	ra,0xfffff
    80002f98:	4f6080e7          	jalr	1270(ra) # 8000248a <sleep>
  while(ticks - ticks0 < n){
    80002f9c:	409c                	lw	a5,0(s1)
    80002f9e:	412787bb          	subw	a5,a5,s2
    80002fa2:	fcc42703          	lw	a4,-52(s0)
    80002fa6:	fce7efe3          	bltu	a5,a4,80002f84 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002faa:	00034517          	auipc	a0,0x34
    80002fae:	7d650513          	addi	a0,a0,2006 # 80037780 <tickslock>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	eaa080e7          	jalr	-342(ra) # 80000e5c <release>
  return 0;
    80002fba:	4781                	li	a5,0
}
    80002fbc:	853e                	mv	a0,a5
    80002fbe:	70e2                	ld	ra,56(sp)
    80002fc0:	7442                	ld	s0,48(sp)
    80002fc2:	74a2                	ld	s1,40(sp)
    80002fc4:	7902                	ld	s2,32(sp)
    80002fc6:	69e2                	ld	s3,24(sp)
    80002fc8:	6121                	addi	sp,sp,64
    80002fca:	8082                	ret
      release(&tickslock);
    80002fcc:	00034517          	auipc	a0,0x34
    80002fd0:	7b450513          	addi	a0,a0,1972 # 80037780 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	e88080e7          	jalr	-376(ra) # 80000e5c <release>
      return -1;
    80002fdc:	57fd                	li	a5,-1
    80002fde:	bff9                	j	80002fbc <sys_sleep+0x88>

0000000080002fe0 <sys_kill>:

uint64
sys_kill(void)
{
    80002fe0:	1101                	addi	sp,sp,-32
    80002fe2:	ec06                	sd	ra,24(sp)
    80002fe4:	e822                	sd	s0,16(sp)
    80002fe6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002fe8:	fec40593          	addi	a1,s0,-20
    80002fec:	4501                	li	a0,0
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	d84080e7          	jalr	-636(ra) # 80002d72 <argint>
    80002ff6:	87aa                	mv	a5,a0
    return -1;
    80002ff8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ffa:	0007c863          	bltz	a5,8000300a <sys_kill+0x2a>
  return kill(pid);
    80002ffe:	fec42503          	lw	a0,-20(s0)
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	678080e7          	jalr	1656(ra) # 8000267a <kill>
}
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003012:	1101                	addi	sp,sp,-32
    80003014:	ec06                	sd	ra,24(sp)
    80003016:	e822                	sd	s0,16(sp)
    80003018:	e426                	sd	s1,8(sp)
    8000301a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000301c:	00034517          	auipc	a0,0x34
    80003020:	76450513          	addi	a0,a0,1892 # 80037780 <tickslock>
    80003024:	ffffe097          	auipc	ra,0xffffe
    80003028:	d84080e7          	jalr	-636(ra) # 80000da8 <acquire>
  xticks = ticks;
    8000302c:	00006497          	auipc	s1,0x6
    80003030:	ff44a483          	lw	s1,-12(s1) # 80009020 <ticks>
  release(&tickslock);
    80003034:	00034517          	auipc	a0,0x34
    80003038:	74c50513          	addi	a0,a0,1868 # 80037780 <tickslock>
    8000303c:	ffffe097          	auipc	ra,0xffffe
    80003040:	e20080e7          	jalr	-480(ra) # 80000e5c <release>
  return xticks;
}
    80003044:	02049513          	slli	a0,s1,0x20
    80003048:	9101                	srli	a0,a0,0x20
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	64a2                	ld	s1,8(sp)
    80003050:	6105                	addi	sp,sp,32
    80003052:	8082                	ret

0000000080003054 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003054:	7179                	addi	sp,sp,-48
    80003056:	f406                	sd	ra,40(sp)
    80003058:	f022                	sd	s0,32(sp)
    8000305a:	ec26                	sd	s1,24(sp)
    8000305c:	e84a                	sd	s2,16(sp)
    8000305e:	e44e                	sd	s3,8(sp)
    80003060:	e052                	sd	s4,0(sp)
    80003062:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003064:	00005597          	auipc	a1,0x5
    80003068:	4ac58593          	addi	a1,a1,1196 # 80008510 <syscalls+0xb0>
    8000306c:	00034517          	auipc	a0,0x34
    80003070:	72c50513          	addi	a0,a0,1836 # 80037798 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	ca4080e7          	jalr	-860(ra) # 80000d18 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000307c:	0003c797          	auipc	a5,0x3c
    80003080:	71c78793          	addi	a5,a5,1820 # 8003f798 <bcache+0x8000>
    80003084:	0003d717          	auipc	a4,0x3d
    80003088:	97c70713          	addi	a4,a4,-1668 # 8003fa00 <bcache+0x8268>
    8000308c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003090:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003094:	00034497          	auipc	s1,0x34
    80003098:	71c48493          	addi	s1,s1,1820 # 800377b0 <bcache+0x18>
    b->next = bcache.head.next;
    8000309c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000309e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030a0:	00005a17          	auipc	s4,0x5
    800030a4:	478a0a13          	addi	s4,s4,1144 # 80008518 <syscalls+0xb8>
    b->next = bcache.head.next;
    800030a8:	2b893783          	ld	a5,696(s2)
    800030ac:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030ae:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030b2:	85d2                	mv	a1,s4
    800030b4:	01048513          	addi	a0,s1,16
    800030b8:	00001097          	auipc	ra,0x1
    800030bc:	4b0080e7          	jalr	1200(ra) # 80004568 <initsleeplock>
    bcache.head.next->prev = b;
    800030c0:	2b893783          	ld	a5,696(s2)
    800030c4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030c6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ca:	45848493          	addi	s1,s1,1112
    800030ce:	fd349de3          	bne	s1,s3,800030a8 <binit+0x54>
  }
}
    800030d2:	70a2                	ld	ra,40(sp)
    800030d4:	7402                	ld	s0,32(sp)
    800030d6:	64e2                	ld	s1,24(sp)
    800030d8:	6942                	ld	s2,16(sp)
    800030da:	69a2                	ld	s3,8(sp)
    800030dc:	6a02                	ld	s4,0(sp)
    800030de:	6145                	addi	sp,sp,48
    800030e0:	8082                	ret

00000000800030e2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030e2:	7179                	addi	sp,sp,-48
    800030e4:	f406                	sd	ra,40(sp)
    800030e6:	f022                	sd	s0,32(sp)
    800030e8:	ec26                	sd	s1,24(sp)
    800030ea:	e84a                	sd	s2,16(sp)
    800030ec:	e44e                	sd	s3,8(sp)
    800030ee:	1800                	addi	s0,sp,48
    800030f0:	89aa                	mv	s3,a0
    800030f2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030f4:	00034517          	auipc	a0,0x34
    800030f8:	6a450513          	addi	a0,a0,1700 # 80037798 <bcache>
    800030fc:	ffffe097          	auipc	ra,0xffffe
    80003100:	cac080e7          	jalr	-852(ra) # 80000da8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003104:	0003d497          	auipc	s1,0x3d
    80003108:	94c4b483          	ld	s1,-1716(s1) # 8003fa50 <bcache+0x82b8>
    8000310c:	0003d797          	auipc	a5,0x3d
    80003110:	8f478793          	addi	a5,a5,-1804 # 8003fa00 <bcache+0x8268>
    80003114:	02f48f63          	beq	s1,a5,80003152 <bread+0x70>
    80003118:	873e                	mv	a4,a5
    8000311a:	a021                	j	80003122 <bread+0x40>
    8000311c:	68a4                	ld	s1,80(s1)
    8000311e:	02e48a63          	beq	s1,a4,80003152 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003122:	449c                	lw	a5,8(s1)
    80003124:	ff379ce3          	bne	a5,s3,8000311c <bread+0x3a>
    80003128:	44dc                	lw	a5,12(s1)
    8000312a:	ff2799e3          	bne	a5,s2,8000311c <bread+0x3a>
      b->refcnt++;
    8000312e:	40bc                	lw	a5,64(s1)
    80003130:	2785                	addiw	a5,a5,1
    80003132:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003134:	00034517          	auipc	a0,0x34
    80003138:	66450513          	addi	a0,a0,1636 # 80037798 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	d20080e7          	jalr	-736(ra) # 80000e5c <release>
      acquiresleep(&b->lock);
    80003144:	01048513          	addi	a0,s1,16
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	45a080e7          	jalr	1114(ra) # 800045a2 <acquiresleep>
      return b;
    80003150:	a8b9                	j	800031ae <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003152:	0003d497          	auipc	s1,0x3d
    80003156:	8f64b483          	ld	s1,-1802(s1) # 8003fa48 <bcache+0x82b0>
    8000315a:	0003d797          	auipc	a5,0x3d
    8000315e:	8a678793          	addi	a5,a5,-1882 # 8003fa00 <bcache+0x8268>
    80003162:	00f48863          	beq	s1,a5,80003172 <bread+0x90>
    80003166:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003168:	40bc                	lw	a5,64(s1)
    8000316a:	cf81                	beqz	a5,80003182 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000316c:	64a4                	ld	s1,72(s1)
    8000316e:	fee49de3          	bne	s1,a4,80003168 <bread+0x86>
  panic("bget: no buffers");
    80003172:	00005517          	auipc	a0,0x5
    80003176:	3ae50513          	addi	a0,a0,942 # 80008520 <syscalls+0xc0>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	3dc080e7          	jalr	988(ra) # 80000556 <panic>
      b->dev = dev;
    80003182:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003186:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000318a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000318e:	4785                	li	a5,1
    80003190:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003192:	00034517          	auipc	a0,0x34
    80003196:	60650513          	addi	a0,a0,1542 # 80037798 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	cc2080e7          	jalr	-830(ra) # 80000e5c <release>
      acquiresleep(&b->lock);
    800031a2:	01048513          	addi	a0,s1,16
    800031a6:	00001097          	auipc	ra,0x1
    800031aa:	3fc080e7          	jalr	1020(ra) # 800045a2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031ae:	409c                	lw	a5,0(s1)
    800031b0:	cb89                	beqz	a5,800031c2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031b2:	8526                	mv	a0,s1
    800031b4:	70a2                	ld	ra,40(sp)
    800031b6:	7402                	ld	s0,32(sp)
    800031b8:	64e2                	ld	s1,24(sp)
    800031ba:	6942                	ld	s2,16(sp)
    800031bc:	69a2                	ld	s3,8(sp)
    800031be:	6145                	addi	sp,sp,48
    800031c0:	8082                	ret
    virtio_disk_rw(b, 0);
    800031c2:	4581                	li	a1,0
    800031c4:	8526                	mv	a0,s1
    800031c6:	00003097          	auipc	ra,0x3
    800031ca:	f52080e7          	jalr	-174(ra) # 80006118 <virtio_disk_rw>
    b->valid = 1;
    800031ce:	4785                	li	a5,1
    800031d0:	c09c                	sw	a5,0(s1)
  return b;
    800031d2:	b7c5                	j	800031b2 <bread+0xd0>

00000000800031d4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031d4:	1101                	addi	sp,sp,-32
    800031d6:	ec06                	sd	ra,24(sp)
    800031d8:	e822                	sd	s0,16(sp)
    800031da:	e426                	sd	s1,8(sp)
    800031dc:	1000                	addi	s0,sp,32
    800031de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031e0:	0541                	addi	a0,a0,16
    800031e2:	00001097          	auipc	ra,0x1
    800031e6:	45a080e7          	jalr	1114(ra) # 8000463c <holdingsleep>
    800031ea:	cd01                	beqz	a0,80003202 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031ec:	4585                	li	a1,1
    800031ee:	8526                	mv	a0,s1
    800031f0:	00003097          	auipc	ra,0x3
    800031f4:	f28080e7          	jalr	-216(ra) # 80006118 <virtio_disk_rw>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret
    panic("bwrite");
    80003202:	00005517          	auipc	a0,0x5
    80003206:	33650513          	addi	a0,a0,822 # 80008538 <syscalls+0xd8>
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	34c080e7          	jalr	844(ra) # 80000556 <panic>

0000000080003212 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003212:	1101                	addi	sp,sp,-32
    80003214:	ec06                	sd	ra,24(sp)
    80003216:	e822                	sd	s0,16(sp)
    80003218:	e426                	sd	s1,8(sp)
    8000321a:	e04a                	sd	s2,0(sp)
    8000321c:	1000                	addi	s0,sp,32
    8000321e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003220:	01050913          	addi	s2,a0,16
    80003224:	854a                	mv	a0,s2
    80003226:	00001097          	auipc	ra,0x1
    8000322a:	416080e7          	jalr	1046(ra) # 8000463c <holdingsleep>
    8000322e:	c92d                	beqz	a0,800032a0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003230:	854a                	mv	a0,s2
    80003232:	00001097          	auipc	ra,0x1
    80003236:	3c6080e7          	jalr	966(ra) # 800045f8 <releasesleep>

  acquire(&bcache.lock);
    8000323a:	00034517          	auipc	a0,0x34
    8000323e:	55e50513          	addi	a0,a0,1374 # 80037798 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	b66080e7          	jalr	-1178(ra) # 80000da8 <acquire>
  b->refcnt--;
    8000324a:	40bc                	lw	a5,64(s1)
    8000324c:	37fd                	addiw	a5,a5,-1
    8000324e:	0007871b          	sext.w	a4,a5
    80003252:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003254:	eb05                	bnez	a4,80003284 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003256:	68bc                	ld	a5,80(s1)
    80003258:	64b8                	ld	a4,72(s1)
    8000325a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000325c:	64bc                	ld	a5,72(s1)
    8000325e:	68b8                	ld	a4,80(s1)
    80003260:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003262:	0003c797          	auipc	a5,0x3c
    80003266:	53678793          	addi	a5,a5,1334 # 8003f798 <bcache+0x8000>
    8000326a:	2b87b703          	ld	a4,696(a5)
    8000326e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003270:	0003c717          	auipc	a4,0x3c
    80003274:	79070713          	addi	a4,a4,1936 # 8003fa00 <bcache+0x8268>
    80003278:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000327a:	2b87b703          	ld	a4,696(a5)
    8000327e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003280:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003284:	00034517          	auipc	a0,0x34
    80003288:	51450513          	addi	a0,a0,1300 # 80037798 <bcache>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	bd0080e7          	jalr	-1072(ra) # 80000e5c <release>
}
    80003294:	60e2                	ld	ra,24(sp)
    80003296:	6442                	ld	s0,16(sp)
    80003298:	64a2                	ld	s1,8(sp)
    8000329a:	6902                	ld	s2,0(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret
    panic("brelse");
    800032a0:	00005517          	auipc	a0,0x5
    800032a4:	2a050513          	addi	a0,a0,672 # 80008540 <syscalls+0xe0>
    800032a8:	ffffd097          	auipc	ra,0xffffd
    800032ac:	2ae080e7          	jalr	686(ra) # 80000556 <panic>

00000000800032b0 <bpin>:

void
bpin(struct buf *b) {
    800032b0:	1101                	addi	sp,sp,-32
    800032b2:	ec06                	sd	ra,24(sp)
    800032b4:	e822                	sd	s0,16(sp)
    800032b6:	e426                	sd	s1,8(sp)
    800032b8:	1000                	addi	s0,sp,32
    800032ba:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032bc:	00034517          	auipc	a0,0x34
    800032c0:	4dc50513          	addi	a0,a0,1244 # 80037798 <bcache>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	ae4080e7          	jalr	-1308(ra) # 80000da8 <acquire>
  b->refcnt++;
    800032cc:	40bc                	lw	a5,64(s1)
    800032ce:	2785                	addiw	a5,a5,1
    800032d0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032d2:	00034517          	auipc	a0,0x34
    800032d6:	4c650513          	addi	a0,a0,1222 # 80037798 <bcache>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	b82080e7          	jalr	-1150(ra) # 80000e5c <release>
}
    800032e2:	60e2                	ld	ra,24(sp)
    800032e4:	6442                	ld	s0,16(sp)
    800032e6:	64a2                	ld	s1,8(sp)
    800032e8:	6105                	addi	sp,sp,32
    800032ea:	8082                	ret

00000000800032ec <bunpin>:

void
bunpin(struct buf *b) {
    800032ec:	1101                	addi	sp,sp,-32
    800032ee:	ec06                	sd	ra,24(sp)
    800032f0:	e822                	sd	s0,16(sp)
    800032f2:	e426                	sd	s1,8(sp)
    800032f4:	1000                	addi	s0,sp,32
    800032f6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032f8:	00034517          	auipc	a0,0x34
    800032fc:	4a050513          	addi	a0,a0,1184 # 80037798 <bcache>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	aa8080e7          	jalr	-1368(ra) # 80000da8 <acquire>
  b->refcnt--;
    80003308:	40bc                	lw	a5,64(s1)
    8000330a:	37fd                	addiw	a5,a5,-1
    8000330c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000330e:	00034517          	auipc	a0,0x34
    80003312:	48a50513          	addi	a0,a0,1162 # 80037798 <bcache>
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	b46080e7          	jalr	-1210(ra) # 80000e5c <release>
}
    8000331e:	60e2                	ld	ra,24(sp)
    80003320:	6442                	ld	s0,16(sp)
    80003322:	64a2                	ld	s1,8(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret

0000000080003328 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003328:	1101                	addi	sp,sp,-32
    8000332a:	ec06                	sd	ra,24(sp)
    8000332c:	e822                	sd	s0,16(sp)
    8000332e:	e426                	sd	s1,8(sp)
    80003330:	e04a                	sd	s2,0(sp)
    80003332:	1000                	addi	s0,sp,32
    80003334:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003336:	00d5d59b          	srliw	a1,a1,0xd
    8000333a:	0003d797          	auipc	a5,0x3d
    8000333e:	b3a7a783          	lw	a5,-1222(a5) # 8003fe74 <sb+0x1c>
    80003342:	9dbd                	addw	a1,a1,a5
    80003344:	00000097          	auipc	ra,0x0
    80003348:	d9e080e7          	jalr	-610(ra) # 800030e2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000334c:	0074f713          	andi	a4,s1,7
    80003350:	4785                	li	a5,1
    80003352:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003356:	14ce                	slli	s1,s1,0x33
    80003358:	90d9                	srli	s1,s1,0x36
    8000335a:	00950733          	add	a4,a0,s1
    8000335e:	05874703          	lbu	a4,88(a4)
    80003362:	00e7f6b3          	and	a3,a5,a4
    80003366:	c69d                	beqz	a3,80003394 <bfree+0x6c>
    80003368:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000336a:	94aa                	add	s1,s1,a0
    8000336c:	fff7c793          	not	a5,a5
    80003370:	8ff9                	and	a5,a5,a4
    80003372:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003376:	00001097          	auipc	ra,0x1
    8000337a:	104080e7          	jalr	260(ra) # 8000447a <log_write>
  brelse(bp);
    8000337e:	854a                	mv	a0,s2
    80003380:	00000097          	auipc	ra,0x0
    80003384:	e92080e7          	jalr	-366(ra) # 80003212 <brelse>
}
    80003388:	60e2                	ld	ra,24(sp)
    8000338a:	6442                	ld	s0,16(sp)
    8000338c:	64a2                	ld	s1,8(sp)
    8000338e:	6902                	ld	s2,0(sp)
    80003390:	6105                	addi	sp,sp,32
    80003392:	8082                	ret
    panic("freeing free block");
    80003394:	00005517          	auipc	a0,0x5
    80003398:	1b450513          	addi	a0,a0,436 # 80008548 <syscalls+0xe8>
    8000339c:	ffffd097          	auipc	ra,0xffffd
    800033a0:	1ba080e7          	jalr	442(ra) # 80000556 <panic>

00000000800033a4 <balloc>:
{
    800033a4:	711d                	addi	sp,sp,-96
    800033a6:	ec86                	sd	ra,88(sp)
    800033a8:	e8a2                	sd	s0,80(sp)
    800033aa:	e4a6                	sd	s1,72(sp)
    800033ac:	e0ca                	sd	s2,64(sp)
    800033ae:	fc4e                	sd	s3,56(sp)
    800033b0:	f852                	sd	s4,48(sp)
    800033b2:	f456                	sd	s5,40(sp)
    800033b4:	f05a                	sd	s6,32(sp)
    800033b6:	ec5e                	sd	s7,24(sp)
    800033b8:	e862                	sd	s8,16(sp)
    800033ba:	e466                	sd	s9,8(sp)
    800033bc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033be:	0003d797          	auipc	a5,0x3d
    800033c2:	a9e7a783          	lw	a5,-1378(a5) # 8003fe5c <sb+0x4>
    800033c6:	cbd1                	beqz	a5,8000345a <balloc+0xb6>
    800033c8:	8baa                	mv	s7,a0
    800033ca:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033cc:	0003db17          	auipc	s6,0x3d
    800033d0:	a8cb0b13          	addi	s6,s6,-1396 # 8003fe58 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033d6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033d8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033da:	6c89                	lui	s9,0x2
    800033dc:	a831                	j	800033f8 <balloc+0x54>
    brelse(bp);
    800033de:	854a                	mv	a0,s2
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	e32080e7          	jalr	-462(ra) # 80003212 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033e8:	015c87bb          	addw	a5,s9,s5
    800033ec:	00078a9b          	sext.w	s5,a5
    800033f0:	004b2703          	lw	a4,4(s6)
    800033f4:	06eaf363          	bgeu	s5,a4,8000345a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800033f8:	41fad79b          	sraiw	a5,s5,0x1f
    800033fc:	0137d79b          	srliw	a5,a5,0x13
    80003400:	015787bb          	addw	a5,a5,s5
    80003404:	40d7d79b          	sraiw	a5,a5,0xd
    80003408:	01cb2583          	lw	a1,28(s6)
    8000340c:	9dbd                	addw	a1,a1,a5
    8000340e:	855e                	mv	a0,s7
    80003410:	00000097          	auipc	ra,0x0
    80003414:	cd2080e7          	jalr	-814(ra) # 800030e2 <bread>
    80003418:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000341a:	004b2503          	lw	a0,4(s6)
    8000341e:	000a849b          	sext.w	s1,s5
    80003422:	8662                	mv	a2,s8
    80003424:	faa4fde3          	bgeu	s1,a0,800033de <balloc+0x3a>
      m = 1 << (bi % 8);
    80003428:	41f6579b          	sraiw	a5,a2,0x1f
    8000342c:	01d7d69b          	srliw	a3,a5,0x1d
    80003430:	00c6873b          	addw	a4,a3,a2
    80003434:	00777793          	andi	a5,a4,7
    80003438:	9f95                	subw	a5,a5,a3
    8000343a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000343e:	4037571b          	sraiw	a4,a4,0x3
    80003442:	00e906b3          	add	a3,s2,a4
    80003446:	0586c683          	lbu	a3,88(a3)
    8000344a:	00d7f5b3          	and	a1,a5,a3
    8000344e:	cd91                	beqz	a1,8000346a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003450:	2605                	addiw	a2,a2,1
    80003452:	2485                	addiw	s1,s1,1
    80003454:	fd4618e3          	bne	a2,s4,80003424 <balloc+0x80>
    80003458:	b759                	j	800033de <balloc+0x3a>
  panic("balloc: out of blocks");
    8000345a:	00005517          	auipc	a0,0x5
    8000345e:	10650513          	addi	a0,a0,262 # 80008560 <syscalls+0x100>
    80003462:	ffffd097          	auipc	ra,0xffffd
    80003466:	0f4080e7          	jalr	244(ra) # 80000556 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000346a:	974a                	add	a4,a4,s2
    8000346c:	8fd5                	or	a5,a5,a3
    8000346e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003472:	854a                	mv	a0,s2
    80003474:	00001097          	auipc	ra,0x1
    80003478:	006080e7          	jalr	6(ra) # 8000447a <log_write>
        brelse(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	d94080e7          	jalr	-620(ra) # 80003212 <brelse>
  bp = bread(dev, bno);
    80003486:	85a6                	mv	a1,s1
    80003488:	855e                	mv	a0,s7
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	c58080e7          	jalr	-936(ra) # 800030e2 <bread>
    80003492:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003494:	40000613          	li	a2,1024
    80003498:	4581                	li	a1,0
    8000349a:	05850513          	addi	a0,a0,88
    8000349e:	ffffe097          	auipc	ra,0xffffe
    800034a2:	a06080e7          	jalr	-1530(ra) # 80000ea4 <memset>
  log_write(bp);
    800034a6:	854a                	mv	a0,s2
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	fd2080e7          	jalr	-46(ra) # 8000447a <log_write>
  brelse(bp);
    800034b0:	854a                	mv	a0,s2
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	d60080e7          	jalr	-672(ra) # 80003212 <brelse>
}
    800034ba:	8526                	mv	a0,s1
    800034bc:	60e6                	ld	ra,88(sp)
    800034be:	6446                	ld	s0,80(sp)
    800034c0:	64a6                	ld	s1,72(sp)
    800034c2:	6906                	ld	s2,64(sp)
    800034c4:	79e2                	ld	s3,56(sp)
    800034c6:	7a42                	ld	s4,48(sp)
    800034c8:	7aa2                	ld	s5,40(sp)
    800034ca:	7b02                	ld	s6,32(sp)
    800034cc:	6be2                	ld	s7,24(sp)
    800034ce:	6c42                	ld	s8,16(sp)
    800034d0:	6ca2                	ld	s9,8(sp)
    800034d2:	6125                	addi	sp,sp,96
    800034d4:	8082                	ret

00000000800034d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034d6:	7179                	addi	sp,sp,-48
    800034d8:	f406                	sd	ra,40(sp)
    800034da:	f022                	sd	s0,32(sp)
    800034dc:	ec26                	sd	s1,24(sp)
    800034de:	e84a                	sd	s2,16(sp)
    800034e0:	e44e                	sd	s3,8(sp)
    800034e2:	e052                	sd	s4,0(sp)
    800034e4:	1800                	addi	s0,sp,48
    800034e6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034e8:	47ad                	li	a5,11
    800034ea:	04b7fe63          	bgeu	a5,a1,80003546 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034ee:	ff45849b          	addiw	s1,a1,-12
    800034f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034f6:	0ff00793          	li	a5,255
    800034fa:	0ae7e363          	bltu	a5,a4,800035a0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034fe:	08052583          	lw	a1,128(a0)
    80003502:	c5ad                	beqz	a1,8000356c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003504:	00092503          	lw	a0,0(s2)
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	bda080e7          	jalr	-1062(ra) # 800030e2 <bread>
    80003510:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003512:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003516:	02049593          	slli	a1,s1,0x20
    8000351a:	9181                	srli	a1,a1,0x20
    8000351c:	058a                	slli	a1,a1,0x2
    8000351e:	00b784b3          	add	s1,a5,a1
    80003522:	0004a983          	lw	s3,0(s1)
    80003526:	04098d63          	beqz	s3,80003580 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000352a:	8552                	mv	a0,s4
    8000352c:	00000097          	auipc	ra,0x0
    80003530:	ce6080e7          	jalr	-794(ra) # 80003212 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003534:	854e                	mv	a0,s3
    80003536:	70a2                	ld	ra,40(sp)
    80003538:	7402                	ld	s0,32(sp)
    8000353a:	64e2                	ld	s1,24(sp)
    8000353c:	6942                	ld	s2,16(sp)
    8000353e:	69a2                	ld	s3,8(sp)
    80003540:	6a02                	ld	s4,0(sp)
    80003542:	6145                	addi	sp,sp,48
    80003544:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003546:	02059493          	slli	s1,a1,0x20
    8000354a:	9081                	srli	s1,s1,0x20
    8000354c:	048a                	slli	s1,s1,0x2
    8000354e:	94aa                	add	s1,s1,a0
    80003550:	0504a983          	lw	s3,80(s1)
    80003554:	fe0990e3          	bnez	s3,80003534 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003558:	4108                	lw	a0,0(a0)
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	e4a080e7          	jalr	-438(ra) # 800033a4 <balloc>
    80003562:	0005099b          	sext.w	s3,a0
    80003566:	0534a823          	sw	s3,80(s1)
    8000356a:	b7e9                	j	80003534 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000356c:	4108                	lw	a0,0(a0)
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	e36080e7          	jalr	-458(ra) # 800033a4 <balloc>
    80003576:	0005059b          	sext.w	a1,a0
    8000357a:	08b92023          	sw	a1,128(s2)
    8000357e:	b759                	j	80003504 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003580:	00092503          	lw	a0,0(s2)
    80003584:	00000097          	auipc	ra,0x0
    80003588:	e20080e7          	jalr	-480(ra) # 800033a4 <balloc>
    8000358c:	0005099b          	sext.w	s3,a0
    80003590:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003594:	8552                	mv	a0,s4
    80003596:	00001097          	auipc	ra,0x1
    8000359a:	ee4080e7          	jalr	-284(ra) # 8000447a <log_write>
    8000359e:	b771                	j	8000352a <bmap+0x54>
  panic("bmap: out of range");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	fd850513          	addi	a0,a0,-40 # 80008578 <syscalls+0x118>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	fae080e7          	jalr	-82(ra) # 80000556 <panic>

00000000800035b0 <iget>:
{
    800035b0:	7179                	addi	sp,sp,-48
    800035b2:	f406                	sd	ra,40(sp)
    800035b4:	f022                	sd	s0,32(sp)
    800035b6:	ec26                	sd	s1,24(sp)
    800035b8:	e84a                	sd	s2,16(sp)
    800035ba:	e44e                	sd	s3,8(sp)
    800035bc:	e052                	sd	s4,0(sp)
    800035be:	1800                	addi	s0,sp,48
    800035c0:	89aa                	mv	s3,a0
    800035c2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035c4:	0003d517          	auipc	a0,0x3d
    800035c8:	8b450513          	addi	a0,a0,-1868 # 8003fe78 <icache>
    800035cc:	ffffd097          	auipc	ra,0xffffd
    800035d0:	7dc080e7          	jalr	2012(ra) # 80000da8 <acquire>
  empty = 0;
    800035d4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035d6:	0003d497          	auipc	s1,0x3d
    800035da:	8ba48493          	addi	s1,s1,-1862 # 8003fe90 <icache+0x18>
    800035de:	0003e697          	auipc	a3,0x3e
    800035e2:	34268693          	addi	a3,a3,834 # 80041920 <log>
    800035e6:	a039                	j	800035f4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e8:	02090b63          	beqz	s2,8000361e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035ec:	08848493          	addi	s1,s1,136
    800035f0:	02d48a63          	beq	s1,a3,80003624 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035f4:	449c                	lw	a5,8(s1)
    800035f6:	fef059e3          	blez	a5,800035e8 <iget+0x38>
    800035fa:	4098                	lw	a4,0(s1)
    800035fc:	ff3716e3          	bne	a4,s3,800035e8 <iget+0x38>
    80003600:	40d8                	lw	a4,4(s1)
    80003602:	ff4713e3          	bne	a4,s4,800035e8 <iget+0x38>
      ip->ref++;
    80003606:	2785                	addiw	a5,a5,1
    80003608:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000360a:	0003d517          	auipc	a0,0x3d
    8000360e:	86e50513          	addi	a0,a0,-1938 # 8003fe78 <icache>
    80003612:	ffffe097          	auipc	ra,0xffffe
    80003616:	84a080e7          	jalr	-1974(ra) # 80000e5c <release>
      return ip;
    8000361a:	8926                	mv	s2,s1
    8000361c:	a03d                	j	8000364a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000361e:	f7f9                	bnez	a5,800035ec <iget+0x3c>
    80003620:	8926                	mv	s2,s1
    80003622:	b7e9                	j	800035ec <iget+0x3c>
  if(empty == 0)
    80003624:	02090c63          	beqz	s2,8000365c <iget+0xac>
  ip->dev = dev;
    80003628:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000362c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003630:	4785                	li	a5,1
    80003632:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003636:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000363a:	0003d517          	auipc	a0,0x3d
    8000363e:	83e50513          	addi	a0,a0,-1986 # 8003fe78 <icache>
    80003642:	ffffe097          	auipc	ra,0xffffe
    80003646:	81a080e7          	jalr	-2022(ra) # 80000e5c <release>
}
    8000364a:	854a                	mv	a0,s2
    8000364c:	70a2                	ld	ra,40(sp)
    8000364e:	7402                	ld	s0,32(sp)
    80003650:	64e2                	ld	s1,24(sp)
    80003652:	6942                	ld	s2,16(sp)
    80003654:	69a2                	ld	s3,8(sp)
    80003656:	6a02                	ld	s4,0(sp)
    80003658:	6145                	addi	sp,sp,48
    8000365a:	8082                	ret
    panic("iget: no inodes");
    8000365c:	00005517          	auipc	a0,0x5
    80003660:	f3450513          	addi	a0,a0,-204 # 80008590 <syscalls+0x130>
    80003664:	ffffd097          	auipc	ra,0xffffd
    80003668:	ef2080e7          	jalr	-270(ra) # 80000556 <panic>

000000008000366c <fsinit>:
fsinit(int dev) {
    8000366c:	7179                	addi	sp,sp,-48
    8000366e:	f406                	sd	ra,40(sp)
    80003670:	f022                	sd	s0,32(sp)
    80003672:	ec26                	sd	s1,24(sp)
    80003674:	e84a                	sd	s2,16(sp)
    80003676:	e44e                	sd	s3,8(sp)
    80003678:	1800                	addi	s0,sp,48
    8000367a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000367c:	4585                	li	a1,1
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	a64080e7          	jalr	-1436(ra) # 800030e2 <bread>
    80003686:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003688:	0003c997          	auipc	s3,0x3c
    8000368c:	7d098993          	addi	s3,s3,2000 # 8003fe58 <sb>
    80003690:	02000613          	li	a2,32
    80003694:	05850593          	addi	a1,a0,88
    80003698:	854e                	mv	a0,s3
    8000369a:	ffffe097          	auipc	ra,0xffffe
    8000369e:	86a080e7          	jalr	-1942(ra) # 80000f04 <memmove>
  brelse(bp);
    800036a2:	8526                	mv	a0,s1
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	b6e080e7          	jalr	-1170(ra) # 80003212 <brelse>
  if(sb.magic != FSMAGIC)
    800036ac:	0009a703          	lw	a4,0(s3)
    800036b0:	102037b7          	lui	a5,0x10203
    800036b4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036b8:	02f71263          	bne	a4,a5,800036dc <fsinit+0x70>
  initlog(dev, &sb);
    800036bc:	0003c597          	auipc	a1,0x3c
    800036c0:	79c58593          	addi	a1,a1,1948 # 8003fe58 <sb>
    800036c4:	854a                	mv	a0,s2
    800036c6:	00001097          	auipc	ra,0x1
    800036ca:	b3c080e7          	jalr	-1220(ra) # 80004202 <initlog>
}
    800036ce:	70a2                	ld	ra,40(sp)
    800036d0:	7402                	ld	s0,32(sp)
    800036d2:	64e2                	ld	s1,24(sp)
    800036d4:	6942                	ld	s2,16(sp)
    800036d6:	69a2                	ld	s3,8(sp)
    800036d8:	6145                	addi	sp,sp,48
    800036da:	8082                	ret
    panic("invalid file system");
    800036dc:	00005517          	auipc	a0,0x5
    800036e0:	ec450513          	addi	a0,a0,-316 # 800085a0 <syscalls+0x140>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	e72080e7          	jalr	-398(ra) # 80000556 <panic>

00000000800036ec <iinit>:
{
    800036ec:	7179                	addi	sp,sp,-48
    800036ee:	f406                	sd	ra,40(sp)
    800036f0:	f022                	sd	s0,32(sp)
    800036f2:	ec26                	sd	s1,24(sp)
    800036f4:	e84a                	sd	s2,16(sp)
    800036f6:	e44e                	sd	s3,8(sp)
    800036f8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036fa:	00005597          	auipc	a1,0x5
    800036fe:	ebe58593          	addi	a1,a1,-322 # 800085b8 <syscalls+0x158>
    80003702:	0003c517          	auipc	a0,0x3c
    80003706:	77650513          	addi	a0,a0,1910 # 8003fe78 <icache>
    8000370a:	ffffd097          	auipc	ra,0xffffd
    8000370e:	60e080e7          	jalr	1550(ra) # 80000d18 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003712:	0003c497          	auipc	s1,0x3c
    80003716:	78e48493          	addi	s1,s1,1934 # 8003fea0 <icache+0x28>
    8000371a:	0003e997          	auipc	s3,0x3e
    8000371e:	21698993          	addi	s3,s3,534 # 80041930 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003722:	00005917          	auipc	s2,0x5
    80003726:	e9e90913          	addi	s2,s2,-354 # 800085c0 <syscalls+0x160>
    8000372a:	85ca                	mv	a1,s2
    8000372c:	8526                	mv	a0,s1
    8000372e:	00001097          	auipc	ra,0x1
    80003732:	e3a080e7          	jalr	-454(ra) # 80004568 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003736:	08848493          	addi	s1,s1,136
    8000373a:	ff3498e3          	bne	s1,s3,8000372a <iinit+0x3e>
}
    8000373e:	70a2                	ld	ra,40(sp)
    80003740:	7402                	ld	s0,32(sp)
    80003742:	64e2                	ld	s1,24(sp)
    80003744:	6942                	ld	s2,16(sp)
    80003746:	69a2                	ld	s3,8(sp)
    80003748:	6145                	addi	sp,sp,48
    8000374a:	8082                	ret

000000008000374c <ialloc>:
{
    8000374c:	715d                	addi	sp,sp,-80
    8000374e:	e486                	sd	ra,72(sp)
    80003750:	e0a2                	sd	s0,64(sp)
    80003752:	fc26                	sd	s1,56(sp)
    80003754:	f84a                	sd	s2,48(sp)
    80003756:	f44e                	sd	s3,40(sp)
    80003758:	f052                	sd	s4,32(sp)
    8000375a:	ec56                	sd	s5,24(sp)
    8000375c:	e85a                	sd	s6,16(sp)
    8000375e:	e45e                	sd	s7,8(sp)
    80003760:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003762:	0003c717          	auipc	a4,0x3c
    80003766:	70272703          	lw	a4,1794(a4) # 8003fe64 <sb+0xc>
    8000376a:	4785                	li	a5,1
    8000376c:	04e7fa63          	bgeu	a5,a4,800037c0 <ialloc+0x74>
    80003770:	8aaa                	mv	s5,a0
    80003772:	8bae                	mv	s7,a1
    80003774:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003776:	0003ca17          	auipc	s4,0x3c
    8000377a:	6e2a0a13          	addi	s4,s4,1762 # 8003fe58 <sb>
    8000377e:	00048b1b          	sext.w	s6,s1
    80003782:	0044d593          	srli	a1,s1,0x4
    80003786:	018a2783          	lw	a5,24(s4)
    8000378a:	9dbd                	addw	a1,a1,a5
    8000378c:	8556                	mv	a0,s5
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	954080e7          	jalr	-1708(ra) # 800030e2 <bread>
    80003796:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003798:	05850993          	addi	s3,a0,88
    8000379c:	00f4f793          	andi	a5,s1,15
    800037a0:	079a                	slli	a5,a5,0x6
    800037a2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037a4:	00099783          	lh	a5,0(s3)
    800037a8:	c785                	beqz	a5,800037d0 <ialloc+0x84>
    brelse(bp);
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	a68080e7          	jalr	-1432(ra) # 80003212 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b2:	0485                	addi	s1,s1,1
    800037b4:	00ca2703          	lw	a4,12(s4)
    800037b8:	0004879b          	sext.w	a5,s1
    800037bc:	fce7e1e3          	bltu	a5,a4,8000377e <ialloc+0x32>
  panic("ialloc: no inodes");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	e0850513          	addi	a0,a0,-504 # 800085c8 <syscalls+0x168>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d8e080e7          	jalr	-626(ra) # 80000556 <panic>
      memset(dip, 0, sizeof(*dip));
    800037d0:	04000613          	li	a2,64
    800037d4:	4581                	li	a1,0
    800037d6:	854e                	mv	a0,s3
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	6cc080e7          	jalr	1740(ra) # 80000ea4 <memset>
      dip->type = type;
    800037e0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037e4:	854a                	mv	a0,s2
    800037e6:	00001097          	auipc	ra,0x1
    800037ea:	c94080e7          	jalr	-876(ra) # 8000447a <log_write>
      brelse(bp);
    800037ee:	854a                	mv	a0,s2
    800037f0:	00000097          	auipc	ra,0x0
    800037f4:	a22080e7          	jalr	-1502(ra) # 80003212 <brelse>
      return iget(dev, inum);
    800037f8:	85da                	mv	a1,s6
    800037fa:	8556                	mv	a0,s5
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	db4080e7          	jalr	-588(ra) # 800035b0 <iget>
}
    80003804:	60a6                	ld	ra,72(sp)
    80003806:	6406                	ld	s0,64(sp)
    80003808:	74e2                	ld	s1,56(sp)
    8000380a:	7942                	ld	s2,48(sp)
    8000380c:	79a2                	ld	s3,40(sp)
    8000380e:	7a02                	ld	s4,32(sp)
    80003810:	6ae2                	ld	s5,24(sp)
    80003812:	6b42                	ld	s6,16(sp)
    80003814:	6ba2                	ld	s7,8(sp)
    80003816:	6161                	addi	sp,sp,80
    80003818:	8082                	ret

000000008000381a <iupdate>:
{
    8000381a:	1101                	addi	sp,sp,-32
    8000381c:	ec06                	sd	ra,24(sp)
    8000381e:	e822                	sd	s0,16(sp)
    80003820:	e426                	sd	s1,8(sp)
    80003822:	e04a                	sd	s2,0(sp)
    80003824:	1000                	addi	s0,sp,32
    80003826:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003828:	415c                	lw	a5,4(a0)
    8000382a:	0047d79b          	srliw	a5,a5,0x4
    8000382e:	0003c597          	auipc	a1,0x3c
    80003832:	6425a583          	lw	a1,1602(a1) # 8003fe70 <sb+0x18>
    80003836:	9dbd                	addw	a1,a1,a5
    80003838:	4108                	lw	a0,0(a0)
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	8a8080e7          	jalr	-1880(ra) # 800030e2 <bread>
    80003842:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003844:	05850793          	addi	a5,a0,88
    80003848:	40c8                	lw	a0,4(s1)
    8000384a:	893d                	andi	a0,a0,15
    8000384c:	051a                	slli	a0,a0,0x6
    8000384e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003850:	04449703          	lh	a4,68(s1)
    80003854:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003858:	04649703          	lh	a4,70(s1)
    8000385c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003860:	04849703          	lh	a4,72(s1)
    80003864:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003868:	04a49703          	lh	a4,74(s1)
    8000386c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003870:	44f8                	lw	a4,76(s1)
    80003872:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003874:	03400613          	li	a2,52
    80003878:	05048593          	addi	a1,s1,80
    8000387c:	0531                	addi	a0,a0,12
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	686080e7          	jalr	1670(ra) # 80000f04 <memmove>
  log_write(bp);
    80003886:	854a                	mv	a0,s2
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	bf2080e7          	jalr	-1038(ra) # 8000447a <log_write>
  brelse(bp);
    80003890:	854a                	mv	a0,s2
    80003892:	00000097          	auipc	ra,0x0
    80003896:	980080e7          	jalr	-1664(ra) # 80003212 <brelse>
}
    8000389a:	60e2                	ld	ra,24(sp)
    8000389c:	6442                	ld	s0,16(sp)
    8000389e:	64a2                	ld	s1,8(sp)
    800038a0:	6902                	ld	s2,0(sp)
    800038a2:	6105                	addi	sp,sp,32
    800038a4:	8082                	ret

00000000800038a6 <idup>:
{
    800038a6:	1101                	addi	sp,sp,-32
    800038a8:	ec06                	sd	ra,24(sp)
    800038aa:	e822                	sd	s0,16(sp)
    800038ac:	e426                	sd	s1,8(sp)
    800038ae:	1000                	addi	s0,sp,32
    800038b0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038b2:	0003c517          	auipc	a0,0x3c
    800038b6:	5c650513          	addi	a0,a0,1478 # 8003fe78 <icache>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	4ee080e7          	jalr	1262(ra) # 80000da8 <acquire>
  ip->ref++;
    800038c2:	449c                	lw	a5,8(s1)
    800038c4:	2785                	addiw	a5,a5,1
    800038c6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038c8:	0003c517          	auipc	a0,0x3c
    800038cc:	5b050513          	addi	a0,a0,1456 # 8003fe78 <icache>
    800038d0:	ffffd097          	auipc	ra,0xffffd
    800038d4:	58c080e7          	jalr	1420(ra) # 80000e5c <release>
}
    800038d8:	8526                	mv	a0,s1
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6105                	addi	sp,sp,32
    800038e2:	8082                	ret

00000000800038e4 <ilock>:
{
    800038e4:	1101                	addi	sp,sp,-32
    800038e6:	ec06                	sd	ra,24(sp)
    800038e8:	e822                	sd	s0,16(sp)
    800038ea:	e426                	sd	s1,8(sp)
    800038ec:	e04a                	sd	s2,0(sp)
    800038ee:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038f0:	c115                	beqz	a0,80003914 <ilock+0x30>
    800038f2:	84aa                	mv	s1,a0
    800038f4:	451c                	lw	a5,8(a0)
    800038f6:	00f05f63          	blez	a5,80003914 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038fa:	0541                	addi	a0,a0,16
    800038fc:	00001097          	auipc	ra,0x1
    80003900:	ca6080e7          	jalr	-858(ra) # 800045a2 <acquiresleep>
  if(ip->valid == 0){
    80003904:	40bc                	lw	a5,64(s1)
    80003906:	cf99                	beqz	a5,80003924 <ilock+0x40>
}
    80003908:	60e2                	ld	ra,24(sp)
    8000390a:	6442                	ld	s0,16(sp)
    8000390c:	64a2                	ld	s1,8(sp)
    8000390e:	6902                	ld	s2,0(sp)
    80003910:	6105                	addi	sp,sp,32
    80003912:	8082                	ret
    panic("ilock");
    80003914:	00005517          	auipc	a0,0x5
    80003918:	ccc50513          	addi	a0,a0,-820 # 800085e0 <syscalls+0x180>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	c3a080e7          	jalr	-966(ra) # 80000556 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003924:	40dc                	lw	a5,4(s1)
    80003926:	0047d79b          	srliw	a5,a5,0x4
    8000392a:	0003c597          	auipc	a1,0x3c
    8000392e:	5465a583          	lw	a1,1350(a1) # 8003fe70 <sb+0x18>
    80003932:	9dbd                	addw	a1,a1,a5
    80003934:	4088                	lw	a0,0(s1)
    80003936:	fffff097          	auipc	ra,0xfffff
    8000393a:	7ac080e7          	jalr	1964(ra) # 800030e2 <bread>
    8000393e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003940:	05850593          	addi	a1,a0,88
    80003944:	40dc                	lw	a5,4(s1)
    80003946:	8bbd                	andi	a5,a5,15
    80003948:	079a                	slli	a5,a5,0x6
    8000394a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000394c:	00059783          	lh	a5,0(a1)
    80003950:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003954:	00259783          	lh	a5,2(a1)
    80003958:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000395c:	00459783          	lh	a5,4(a1)
    80003960:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003964:	00659783          	lh	a5,6(a1)
    80003968:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000396c:	459c                	lw	a5,8(a1)
    8000396e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003970:	03400613          	li	a2,52
    80003974:	05b1                	addi	a1,a1,12
    80003976:	05048513          	addi	a0,s1,80
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	58a080e7          	jalr	1418(ra) # 80000f04 <memmove>
    brelse(bp);
    80003982:	854a                	mv	a0,s2
    80003984:	00000097          	auipc	ra,0x0
    80003988:	88e080e7          	jalr	-1906(ra) # 80003212 <brelse>
    ip->valid = 1;
    8000398c:	4785                	li	a5,1
    8000398e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003990:	04449783          	lh	a5,68(s1)
    80003994:	fbb5                	bnez	a5,80003908 <ilock+0x24>
      panic("ilock: no type");
    80003996:	00005517          	auipc	a0,0x5
    8000399a:	c5250513          	addi	a0,a0,-942 # 800085e8 <syscalls+0x188>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	bb8080e7          	jalr	-1096(ra) # 80000556 <panic>

00000000800039a6 <iunlock>:
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	e04a                	sd	s2,0(sp)
    800039b0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039b2:	c905                	beqz	a0,800039e2 <iunlock+0x3c>
    800039b4:	84aa                	mv	s1,a0
    800039b6:	01050913          	addi	s2,a0,16
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	c80080e7          	jalr	-896(ra) # 8000463c <holdingsleep>
    800039c4:	cd19                	beqz	a0,800039e2 <iunlock+0x3c>
    800039c6:	449c                	lw	a5,8(s1)
    800039c8:	00f05d63          	blez	a5,800039e2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00001097          	auipc	ra,0x1
    800039d2:	c2a080e7          	jalr	-982(ra) # 800045f8 <releasesleep>
}
    800039d6:	60e2                	ld	ra,24(sp)
    800039d8:	6442                	ld	s0,16(sp)
    800039da:	64a2                	ld	s1,8(sp)
    800039dc:	6902                	ld	s2,0(sp)
    800039de:	6105                	addi	sp,sp,32
    800039e0:	8082                	ret
    panic("iunlock");
    800039e2:	00005517          	auipc	a0,0x5
    800039e6:	c1650513          	addi	a0,a0,-1002 # 800085f8 <syscalls+0x198>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	b6c080e7          	jalr	-1172(ra) # 80000556 <panic>

00000000800039f2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039f2:	7179                	addi	sp,sp,-48
    800039f4:	f406                	sd	ra,40(sp)
    800039f6:	f022                	sd	s0,32(sp)
    800039f8:	ec26                	sd	s1,24(sp)
    800039fa:	e84a                	sd	s2,16(sp)
    800039fc:	e44e                	sd	s3,8(sp)
    800039fe:	e052                	sd	s4,0(sp)
    80003a00:	1800                	addi	s0,sp,48
    80003a02:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a04:	05050493          	addi	s1,a0,80
    80003a08:	08050913          	addi	s2,a0,128
    80003a0c:	a021                	j	80003a14 <itrunc+0x22>
    80003a0e:	0491                	addi	s1,s1,4
    80003a10:	01248d63          	beq	s1,s2,80003a2a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a14:	408c                	lw	a1,0(s1)
    80003a16:	dde5                	beqz	a1,80003a0e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a18:	0009a503          	lw	a0,0(s3)
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	90c080e7          	jalr	-1780(ra) # 80003328 <bfree>
      ip->addrs[i] = 0;
    80003a24:	0004a023          	sw	zero,0(s1)
    80003a28:	b7dd                	j	80003a0e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a2a:	0809a583          	lw	a1,128(s3)
    80003a2e:	e185                	bnez	a1,80003a4e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a30:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a34:	854e                	mv	a0,s3
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	de4080e7          	jalr	-540(ra) # 8000381a <iupdate>
}
    80003a3e:	70a2                	ld	ra,40(sp)
    80003a40:	7402                	ld	s0,32(sp)
    80003a42:	64e2                	ld	s1,24(sp)
    80003a44:	6942                	ld	s2,16(sp)
    80003a46:	69a2                	ld	s3,8(sp)
    80003a48:	6a02                	ld	s4,0(sp)
    80003a4a:	6145                	addi	sp,sp,48
    80003a4c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a4e:	0009a503          	lw	a0,0(s3)
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	690080e7          	jalr	1680(ra) # 800030e2 <bread>
    80003a5a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a5c:	05850493          	addi	s1,a0,88
    80003a60:	45850913          	addi	s2,a0,1112
    80003a64:	a811                	j	80003a78 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a66:	0009a503          	lw	a0,0(s3)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	8be080e7          	jalr	-1858(ra) # 80003328 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a72:	0491                	addi	s1,s1,4
    80003a74:	01248563          	beq	s1,s2,80003a7e <itrunc+0x8c>
      if(a[j])
    80003a78:	408c                	lw	a1,0(s1)
    80003a7a:	dde5                	beqz	a1,80003a72 <itrunc+0x80>
    80003a7c:	b7ed                	j	80003a66 <itrunc+0x74>
    brelse(bp);
    80003a7e:	8552                	mv	a0,s4
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	792080e7          	jalr	1938(ra) # 80003212 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a88:	0809a583          	lw	a1,128(s3)
    80003a8c:	0009a503          	lw	a0,0(s3)
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	898080e7          	jalr	-1896(ra) # 80003328 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a98:	0809a023          	sw	zero,128(s3)
    80003a9c:	bf51                	j	80003a30 <itrunc+0x3e>

0000000080003a9e <iput>:
{
    80003a9e:	1101                	addi	sp,sp,-32
    80003aa0:	ec06                	sd	ra,24(sp)
    80003aa2:	e822                	sd	s0,16(sp)
    80003aa4:	e426                	sd	s1,8(sp)
    80003aa6:	e04a                	sd	s2,0(sp)
    80003aa8:	1000                	addi	s0,sp,32
    80003aaa:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003aac:	0003c517          	auipc	a0,0x3c
    80003ab0:	3cc50513          	addi	a0,a0,972 # 8003fe78 <icache>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	2f4080e7          	jalr	756(ra) # 80000da8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003abc:	4498                	lw	a4,8(s1)
    80003abe:	4785                	li	a5,1
    80003ac0:	02f70363          	beq	a4,a5,80003ae6 <iput+0x48>
  ip->ref--;
    80003ac4:	449c                	lw	a5,8(s1)
    80003ac6:	37fd                	addiw	a5,a5,-1
    80003ac8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003aca:	0003c517          	auipc	a0,0x3c
    80003ace:	3ae50513          	addi	a0,a0,942 # 8003fe78 <icache>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	38a080e7          	jalr	906(ra) # 80000e5c <release>
}
    80003ada:	60e2                	ld	ra,24(sp)
    80003adc:	6442                	ld	s0,16(sp)
    80003ade:	64a2                	ld	s1,8(sp)
    80003ae0:	6902                	ld	s2,0(sp)
    80003ae2:	6105                	addi	sp,sp,32
    80003ae4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae6:	40bc                	lw	a5,64(s1)
    80003ae8:	dff1                	beqz	a5,80003ac4 <iput+0x26>
    80003aea:	04a49783          	lh	a5,74(s1)
    80003aee:	fbf9                	bnez	a5,80003ac4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003af0:	01048913          	addi	s2,s1,16
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	aac080e7          	jalr	-1364(ra) # 800045a2 <acquiresleep>
    release(&icache.lock);
    80003afe:	0003c517          	auipc	a0,0x3c
    80003b02:	37a50513          	addi	a0,a0,890 # 8003fe78 <icache>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	356080e7          	jalr	854(ra) # 80000e5c <release>
    itrunc(ip);
    80003b0e:	8526                	mv	a0,s1
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	ee2080e7          	jalr	-286(ra) # 800039f2 <itrunc>
    ip->type = 0;
    80003b18:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	cfc080e7          	jalr	-772(ra) # 8000381a <iupdate>
    ip->valid = 0;
    80003b26:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	acc080e7          	jalr	-1332(ra) # 800045f8 <releasesleep>
    acquire(&icache.lock);
    80003b34:	0003c517          	auipc	a0,0x3c
    80003b38:	34450513          	addi	a0,a0,836 # 8003fe78 <icache>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	26c080e7          	jalr	620(ra) # 80000da8 <acquire>
    80003b44:	b741                	j	80003ac4 <iput+0x26>

0000000080003b46 <iunlockput>:
{
    80003b46:	1101                	addi	sp,sp,-32
    80003b48:	ec06                	sd	ra,24(sp)
    80003b4a:	e822                	sd	s0,16(sp)
    80003b4c:	e426                	sd	s1,8(sp)
    80003b4e:	1000                	addi	s0,sp,32
    80003b50:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	e54080e7          	jalr	-428(ra) # 800039a6 <iunlock>
  iput(ip);
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	f42080e7          	jalr	-190(ra) # 80003a9e <iput>
}
    80003b64:	60e2                	ld	ra,24(sp)
    80003b66:	6442                	ld	s0,16(sp)
    80003b68:	64a2                	ld	s1,8(sp)
    80003b6a:	6105                	addi	sp,sp,32
    80003b6c:	8082                	ret

0000000080003b6e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b6e:	1141                	addi	sp,sp,-16
    80003b70:	e422                	sd	s0,8(sp)
    80003b72:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b74:	411c                	lw	a5,0(a0)
    80003b76:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b78:	415c                	lw	a5,4(a0)
    80003b7a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b7c:	04451783          	lh	a5,68(a0)
    80003b80:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b84:	04a51783          	lh	a5,74(a0)
    80003b88:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b8c:	04c56783          	lwu	a5,76(a0)
    80003b90:	e99c                	sd	a5,16(a1)
}
    80003b92:	6422                	ld	s0,8(sp)
    80003b94:	0141                	addi	sp,sp,16
    80003b96:	8082                	ret

0000000080003b98 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b98:	457c                	lw	a5,76(a0)
    80003b9a:	0ed7e963          	bltu	a5,a3,80003c8c <readi+0xf4>
{
    80003b9e:	7159                	addi	sp,sp,-112
    80003ba0:	f486                	sd	ra,104(sp)
    80003ba2:	f0a2                	sd	s0,96(sp)
    80003ba4:	eca6                	sd	s1,88(sp)
    80003ba6:	e8ca                	sd	s2,80(sp)
    80003ba8:	e4ce                	sd	s3,72(sp)
    80003baa:	e0d2                	sd	s4,64(sp)
    80003bac:	fc56                	sd	s5,56(sp)
    80003bae:	f85a                	sd	s6,48(sp)
    80003bb0:	f45e                	sd	s7,40(sp)
    80003bb2:	f062                	sd	s8,32(sp)
    80003bb4:	ec66                	sd	s9,24(sp)
    80003bb6:	e86a                	sd	s10,16(sp)
    80003bb8:	e46e                	sd	s11,8(sp)
    80003bba:	1880                	addi	s0,sp,112
    80003bbc:	8baa                	mv	s7,a0
    80003bbe:	8c2e                	mv	s8,a1
    80003bc0:	8ab2                	mv	s5,a2
    80003bc2:	84b6                	mv	s1,a3
    80003bc4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc6:	9f35                	addw	a4,a4,a3
    return 0;
    80003bc8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bca:	0ad76063          	bltu	a4,a3,80003c6a <readi+0xd2>
  if(off + n > ip->size)
    80003bce:	00e7f463          	bgeu	a5,a4,80003bd6 <readi+0x3e>
    n = ip->size - off;
    80003bd2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd6:	0a0b0963          	beqz	s6,80003c88 <readi+0xf0>
    80003bda:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bdc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003be0:	5cfd                	li	s9,-1
    80003be2:	a82d                	j	80003c1c <readi+0x84>
    80003be4:	020a1d93          	slli	s11,s4,0x20
    80003be8:	020ddd93          	srli	s11,s11,0x20
    80003bec:	05890613          	addi	a2,s2,88
    80003bf0:	86ee                	mv	a3,s11
    80003bf2:	963a                	add	a2,a2,a4
    80003bf4:	85d6                	mv	a1,s5
    80003bf6:	8562                	mv	a0,s8
    80003bf8:	fffff097          	auipc	ra,0xfffff
    80003bfc:	af4080e7          	jalr	-1292(ra) # 800026ec <either_copyout>
    80003c00:	05950d63          	beq	a0,s9,80003c5a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c04:	854a                	mv	a0,s2
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	60c080e7          	jalr	1548(ra) # 80003212 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c0e:	013a09bb          	addw	s3,s4,s3
    80003c12:	009a04bb          	addw	s1,s4,s1
    80003c16:	9aee                	add	s5,s5,s11
    80003c18:	0569f763          	bgeu	s3,s6,80003c66 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c1c:	000ba903          	lw	s2,0(s7)
    80003c20:	00a4d59b          	srliw	a1,s1,0xa
    80003c24:	855e                	mv	a0,s7
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	8b0080e7          	jalr	-1872(ra) # 800034d6 <bmap>
    80003c2e:	0005059b          	sext.w	a1,a0
    80003c32:	854a                	mv	a0,s2
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	4ae080e7          	jalr	1198(ra) # 800030e2 <bread>
    80003c3c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3e:	3ff4f713          	andi	a4,s1,1023
    80003c42:	40ed07bb          	subw	a5,s10,a4
    80003c46:	413b06bb          	subw	a3,s6,s3
    80003c4a:	8a3e                	mv	s4,a5
    80003c4c:	2781                	sext.w	a5,a5
    80003c4e:	0006861b          	sext.w	a2,a3
    80003c52:	f8f679e3          	bgeu	a2,a5,80003be4 <readi+0x4c>
    80003c56:	8a36                	mv	s4,a3
    80003c58:	b771                	j	80003be4 <readi+0x4c>
      brelse(bp);
    80003c5a:	854a                	mv	a0,s2
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	5b6080e7          	jalr	1462(ra) # 80003212 <brelse>
      tot = -1;
    80003c64:	59fd                	li	s3,-1
  }
  return tot;
    80003c66:	0009851b          	sext.w	a0,s3
}
    80003c6a:	70a6                	ld	ra,104(sp)
    80003c6c:	7406                	ld	s0,96(sp)
    80003c6e:	64e6                	ld	s1,88(sp)
    80003c70:	6946                	ld	s2,80(sp)
    80003c72:	69a6                	ld	s3,72(sp)
    80003c74:	6a06                	ld	s4,64(sp)
    80003c76:	7ae2                	ld	s5,56(sp)
    80003c78:	7b42                	ld	s6,48(sp)
    80003c7a:	7ba2                	ld	s7,40(sp)
    80003c7c:	7c02                	ld	s8,32(sp)
    80003c7e:	6ce2                	ld	s9,24(sp)
    80003c80:	6d42                	ld	s10,16(sp)
    80003c82:	6da2                	ld	s11,8(sp)
    80003c84:	6165                	addi	sp,sp,112
    80003c86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c88:	89da                	mv	s3,s6
    80003c8a:	bff1                	j	80003c66 <readi+0xce>
    return 0;
    80003c8c:	4501                	li	a0,0
}
    80003c8e:	8082                	ret

0000000080003c90 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c90:	457c                	lw	a5,76(a0)
    80003c92:	10d7e763          	bltu	a5,a3,80003da0 <writei+0x110>
{
    80003c96:	7159                	addi	sp,sp,-112
    80003c98:	f486                	sd	ra,104(sp)
    80003c9a:	f0a2                	sd	s0,96(sp)
    80003c9c:	eca6                	sd	s1,88(sp)
    80003c9e:	e8ca                	sd	s2,80(sp)
    80003ca0:	e4ce                	sd	s3,72(sp)
    80003ca2:	e0d2                	sd	s4,64(sp)
    80003ca4:	fc56                	sd	s5,56(sp)
    80003ca6:	f85a                	sd	s6,48(sp)
    80003ca8:	f45e                	sd	s7,40(sp)
    80003caa:	f062                	sd	s8,32(sp)
    80003cac:	ec66                	sd	s9,24(sp)
    80003cae:	e86a                	sd	s10,16(sp)
    80003cb0:	e46e                	sd	s11,8(sp)
    80003cb2:	1880                	addi	s0,sp,112
    80003cb4:	8baa                	mv	s7,a0
    80003cb6:	8c2e                	mv	s8,a1
    80003cb8:	8ab2                	mv	s5,a2
    80003cba:	8936                	mv	s2,a3
    80003cbc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cbe:	00e687bb          	addw	a5,a3,a4
    80003cc2:	0ed7e163          	bltu	a5,a3,80003da4 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cc6:	00043737          	lui	a4,0x43
    80003cca:	0cf76f63          	bltu	a4,a5,80003da8 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cce:	0a0b0863          	beqz	s6,80003d7e <writei+0xee>
    80003cd2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cd8:	5cfd                	li	s9,-1
    80003cda:	a091                	j	80003d1e <writei+0x8e>
    80003cdc:	02099d93          	slli	s11,s3,0x20
    80003ce0:	020ddd93          	srli	s11,s11,0x20
    80003ce4:	05848513          	addi	a0,s1,88
    80003ce8:	86ee                	mv	a3,s11
    80003cea:	8656                	mv	a2,s5
    80003cec:	85e2                	mv	a1,s8
    80003cee:	953a                	add	a0,a0,a4
    80003cf0:	fffff097          	auipc	ra,0xfffff
    80003cf4:	a52080e7          	jalr	-1454(ra) # 80002742 <either_copyin>
    80003cf8:	07950263          	beq	a0,s9,80003d5c <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	00000097          	auipc	ra,0x0
    80003d02:	77c080e7          	jalr	1916(ra) # 8000447a <log_write>
    brelse(bp);
    80003d06:	8526                	mv	a0,s1
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	50a080e7          	jalr	1290(ra) # 80003212 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d10:	01498a3b          	addw	s4,s3,s4
    80003d14:	0129893b          	addw	s2,s3,s2
    80003d18:	9aee                	add	s5,s5,s11
    80003d1a:	056a7763          	bgeu	s4,s6,80003d68 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d1e:	000ba483          	lw	s1,0(s7)
    80003d22:	00a9559b          	srliw	a1,s2,0xa
    80003d26:	855e                	mv	a0,s7
    80003d28:	fffff097          	auipc	ra,0xfffff
    80003d2c:	7ae080e7          	jalr	1966(ra) # 800034d6 <bmap>
    80003d30:	0005059b          	sext.w	a1,a0
    80003d34:	8526                	mv	a0,s1
    80003d36:	fffff097          	auipc	ra,0xfffff
    80003d3a:	3ac080e7          	jalr	940(ra) # 800030e2 <bread>
    80003d3e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d40:	3ff97713          	andi	a4,s2,1023
    80003d44:	40ed07bb          	subw	a5,s10,a4
    80003d48:	414b06bb          	subw	a3,s6,s4
    80003d4c:	89be                	mv	s3,a5
    80003d4e:	2781                	sext.w	a5,a5
    80003d50:	0006861b          	sext.w	a2,a3
    80003d54:	f8f674e3          	bgeu	a2,a5,80003cdc <writei+0x4c>
    80003d58:	89b6                	mv	s3,a3
    80003d5a:	b749                	j	80003cdc <writei+0x4c>
      brelse(bp);
    80003d5c:	8526                	mv	a0,s1
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	4b4080e7          	jalr	1204(ra) # 80003212 <brelse>
      n = -1;
    80003d66:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003d68:	04cba783          	lw	a5,76(s7)
    80003d6c:	0127f463          	bgeu	a5,s2,80003d74 <writei+0xe4>
      ip->size = off;
    80003d70:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d74:	855e                	mv	a0,s7
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	aa4080e7          	jalr	-1372(ra) # 8000381a <iupdate>
  }

  return n;
    80003d7e:	000b051b          	sext.w	a0,s6
}
    80003d82:	70a6                	ld	ra,104(sp)
    80003d84:	7406                	ld	s0,96(sp)
    80003d86:	64e6                	ld	s1,88(sp)
    80003d88:	6946                	ld	s2,80(sp)
    80003d8a:	69a6                	ld	s3,72(sp)
    80003d8c:	6a06                	ld	s4,64(sp)
    80003d8e:	7ae2                	ld	s5,56(sp)
    80003d90:	7b42                	ld	s6,48(sp)
    80003d92:	7ba2                	ld	s7,40(sp)
    80003d94:	7c02                	ld	s8,32(sp)
    80003d96:	6ce2                	ld	s9,24(sp)
    80003d98:	6d42                	ld	s10,16(sp)
    80003d9a:	6da2                	ld	s11,8(sp)
    80003d9c:	6165                	addi	sp,sp,112
    80003d9e:	8082                	ret
    return -1;
    80003da0:	557d                	li	a0,-1
}
    80003da2:	8082                	ret
    return -1;
    80003da4:	557d                	li	a0,-1
    80003da6:	bff1                	j	80003d82 <writei+0xf2>
    return -1;
    80003da8:	557d                	li	a0,-1
    80003daa:	bfe1                	j	80003d82 <writei+0xf2>

0000000080003dac <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dac:	1141                	addi	sp,sp,-16
    80003dae:	e406                	sd	ra,8(sp)
    80003db0:	e022                	sd	s0,0(sp)
    80003db2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db4:	4639                	li	a2,14
    80003db6:	ffffd097          	auipc	ra,0xffffd
    80003dba:	1ca080e7          	jalr	458(ra) # 80000f80 <strncmp>
}
    80003dbe:	60a2                	ld	ra,8(sp)
    80003dc0:	6402                	ld	s0,0(sp)
    80003dc2:	0141                	addi	sp,sp,16
    80003dc4:	8082                	ret

0000000080003dc6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc6:	7139                	addi	sp,sp,-64
    80003dc8:	fc06                	sd	ra,56(sp)
    80003dca:	f822                	sd	s0,48(sp)
    80003dcc:	f426                	sd	s1,40(sp)
    80003dce:	f04a                	sd	s2,32(sp)
    80003dd0:	ec4e                	sd	s3,24(sp)
    80003dd2:	e852                	sd	s4,16(sp)
    80003dd4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd6:	04451703          	lh	a4,68(a0)
    80003dda:	4785                	li	a5,1
    80003ddc:	00f71a63          	bne	a4,a5,80003df0 <dirlookup+0x2a>
    80003de0:	892a                	mv	s2,a0
    80003de2:	89ae                	mv	s3,a1
    80003de4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de6:	457c                	lw	a5,76(a0)
    80003de8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dea:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dec:	e79d                	bnez	a5,80003e1a <dirlookup+0x54>
    80003dee:	a8a5                	j	80003e66 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003df0:	00005517          	auipc	a0,0x5
    80003df4:	81050513          	addi	a0,a0,-2032 # 80008600 <syscalls+0x1a0>
    80003df8:	ffffc097          	auipc	ra,0xffffc
    80003dfc:	75e080e7          	jalr	1886(ra) # 80000556 <panic>
      panic("dirlookup read");
    80003e00:	00005517          	auipc	a0,0x5
    80003e04:	81850513          	addi	a0,a0,-2024 # 80008618 <syscalls+0x1b8>
    80003e08:	ffffc097          	auipc	ra,0xffffc
    80003e0c:	74e080e7          	jalr	1870(ra) # 80000556 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e10:	24c1                	addiw	s1,s1,16
    80003e12:	04c92783          	lw	a5,76(s2)
    80003e16:	04f4f763          	bgeu	s1,a5,80003e64 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e1a:	4741                	li	a4,16
    80003e1c:	86a6                	mv	a3,s1
    80003e1e:	fc040613          	addi	a2,s0,-64
    80003e22:	4581                	li	a1,0
    80003e24:	854a                	mv	a0,s2
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	d72080e7          	jalr	-654(ra) # 80003b98 <readi>
    80003e2e:	47c1                	li	a5,16
    80003e30:	fcf518e3          	bne	a0,a5,80003e00 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e34:	fc045783          	lhu	a5,-64(s0)
    80003e38:	dfe1                	beqz	a5,80003e10 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e3a:	fc240593          	addi	a1,s0,-62
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	f6c080e7          	jalr	-148(ra) # 80003dac <namecmp>
    80003e48:	f561                	bnez	a0,80003e10 <dirlookup+0x4a>
      if(poff)
    80003e4a:	000a0463          	beqz	s4,80003e52 <dirlookup+0x8c>
        *poff = off;
    80003e4e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e52:	fc045583          	lhu	a1,-64(s0)
    80003e56:	00092503          	lw	a0,0(s2)
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	756080e7          	jalr	1878(ra) # 800035b0 <iget>
    80003e62:	a011                	j	80003e66 <dirlookup+0xa0>
  return 0;
    80003e64:	4501                	li	a0,0
}
    80003e66:	70e2                	ld	ra,56(sp)
    80003e68:	7442                	ld	s0,48(sp)
    80003e6a:	74a2                	ld	s1,40(sp)
    80003e6c:	7902                	ld	s2,32(sp)
    80003e6e:	69e2                	ld	s3,24(sp)
    80003e70:	6a42                	ld	s4,16(sp)
    80003e72:	6121                	addi	sp,sp,64
    80003e74:	8082                	ret

0000000080003e76 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e76:	711d                	addi	sp,sp,-96
    80003e78:	ec86                	sd	ra,88(sp)
    80003e7a:	e8a2                	sd	s0,80(sp)
    80003e7c:	e4a6                	sd	s1,72(sp)
    80003e7e:	e0ca                	sd	s2,64(sp)
    80003e80:	fc4e                	sd	s3,56(sp)
    80003e82:	f852                	sd	s4,48(sp)
    80003e84:	f456                	sd	s5,40(sp)
    80003e86:	f05a                	sd	s6,32(sp)
    80003e88:	ec5e                	sd	s7,24(sp)
    80003e8a:	e862                	sd	s8,16(sp)
    80003e8c:	e466                	sd	s9,8(sp)
    80003e8e:	1080                	addi	s0,sp,96
    80003e90:	84aa                	mv	s1,a0
    80003e92:	8b2e                	mv	s6,a1
    80003e94:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e96:	00054703          	lbu	a4,0(a0)
    80003e9a:	02f00793          	li	a5,47
    80003e9e:	02f70363          	beq	a4,a5,80003ec4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ea2:	ffffe097          	auipc	ra,0xffffe
    80003ea6:	dd8080e7          	jalr	-552(ra) # 80001c7a <myproc>
    80003eaa:	15053503          	ld	a0,336(a0)
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	9f8080e7          	jalr	-1544(ra) # 800038a6 <idup>
    80003eb6:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eb8:	02f00913          	li	s2,47
  len = path - s;
    80003ebc:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ebe:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ec0:	4c05                	li	s8,1
    80003ec2:	a865                	j	80003f7a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ec4:	4585                	li	a1,1
    80003ec6:	4505                	li	a0,1
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	6e8080e7          	jalr	1768(ra) # 800035b0 <iget>
    80003ed0:	89aa                	mv	s3,a0
    80003ed2:	b7dd                	j	80003eb8 <namex+0x42>
      iunlockput(ip);
    80003ed4:	854e                	mv	a0,s3
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	c70080e7          	jalr	-912(ra) # 80003b46 <iunlockput>
      return 0;
    80003ede:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ee0:	854e                	mv	a0,s3
    80003ee2:	60e6                	ld	ra,88(sp)
    80003ee4:	6446                	ld	s0,80(sp)
    80003ee6:	64a6                	ld	s1,72(sp)
    80003ee8:	6906                	ld	s2,64(sp)
    80003eea:	79e2                	ld	s3,56(sp)
    80003eec:	7a42                	ld	s4,48(sp)
    80003eee:	7aa2                	ld	s5,40(sp)
    80003ef0:	7b02                	ld	s6,32(sp)
    80003ef2:	6be2                	ld	s7,24(sp)
    80003ef4:	6c42                	ld	s8,16(sp)
    80003ef6:	6ca2                	ld	s9,8(sp)
    80003ef8:	6125                	addi	sp,sp,96
    80003efa:	8082                	ret
      iunlock(ip);
    80003efc:	854e                	mv	a0,s3
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	aa8080e7          	jalr	-1368(ra) # 800039a6 <iunlock>
      return ip;
    80003f06:	bfe9                	j	80003ee0 <namex+0x6a>
      iunlockput(ip);
    80003f08:	854e                	mv	a0,s3
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	c3c080e7          	jalr	-964(ra) # 80003b46 <iunlockput>
      return 0;
    80003f12:	89d2                	mv	s3,s4
    80003f14:	b7f1                	j	80003ee0 <namex+0x6a>
  len = path - s;
    80003f16:	40b48633          	sub	a2,s1,a1
    80003f1a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f1e:	094cd463          	bge	s9,s4,80003fa6 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f22:	4639                	li	a2,14
    80003f24:	8556                	mv	a0,s5
    80003f26:	ffffd097          	auipc	ra,0xffffd
    80003f2a:	fde080e7          	jalr	-34(ra) # 80000f04 <memmove>
  while(*path == '/')
    80003f2e:	0004c783          	lbu	a5,0(s1)
    80003f32:	01279763          	bne	a5,s2,80003f40 <namex+0xca>
    path++;
    80003f36:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f38:	0004c783          	lbu	a5,0(s1)
    80003f3c:	ff278de3          	beq	a5,s2,80003f36 <namex+0xc0>
    ilock(ip);
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	9a2080e7          	jalr	-1630(ra) # 800038e4 <ilock>
    if(ip->type != T_DIR){
    80003f4a:	04499783          	lh	a5,68(s3)
    80003f4e:	f98793e3          	bne	a5,s8,80003ed4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f52:	000b0563          	beqz	s6,80003f5c <namex+0xe6>
    80003f56:	0004c783          	lbu	a5,0(s1)
    80003f5a:	d3cd                	beqz	a5,80003efc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f5c:	865e                	mv	a2,s7
    80003f5e:	85d6                	mv	a1,s5
    80003f60:	854e                	mv	a0,s3
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	e64080e7          	jalr	-412(ra) # 80003dc6 <dirlookup>
    80003f6a:	8a2a                	mv	s4,a0
    80003f6c:	dd51                	beqz	a0,80003f08 <namex+0x92>
    iunlockput(ip);
    80003f6e:	854e                	mv	a0,s3
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	bd6080e7          	jalr	-1066(ra) # 80003b46 <iunlockput>
    ip = next;
    80003f78:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f7a:	0004c783          	lbu	a5,0(s1)
    80003f7e:	05279763          	bne	a5,s2,80003fcc <namex+0x156>
    path++;
    80003f82:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f84:	0004c783          	lbu	a5,0(s1)
    80003f88:	ff278de3          	beq	a5,s2,80003f82 <namex+0x10c>
  if(*path == 0)
    80003f8c:	c79d                	beqz	a5,80003fba <namex+0x144>
    path++;
    80003f8e:	85a6                	mv	a1,s1
  len = path - s;
    80003f90:	8a5e                	mv	s4,s7
    80003f92:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f94:	01278963          	beq	a5,s2,80003fa6 <namex+0x130>
    80003f98:	dfbd                	beqz	a5,80003f16 <namex+0xa0>
    path++;
    80003f9a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f9c:	0004c783          	lbu	a5,0(s1)
    80003fa0:	ff279ce3          	bne	a5,s2,80003f98 <namex+0x122>
    80003fa4:	bf8d                	j	80003f16 <namex+0xa0>
    memmove(name, s, len);
    80003fa6:	2601                	sext.w	a2,a2
    80003fa8:	8556                	mv	a0,s5
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	f5a080e7          	jalr	-166(ra) # 80000f04 <memmove>
    name[len] = 0;
    80003fb2:	9a56                	add	s4,s4,s5
    80003fb4:	000a0023          	sb	zero,0(s4)
    80003fb8:	bf9d                	j	80003f2e <namex+0xb8>
  if(nameiparent){
    80003fba:	f20b03e3          	beqz	s6,80003ee0 <namex+0x6a>
    iput(ip);
    80003fbe:	854e                	mv	a0,s3
    80003fc0:	00000097          	auipc	ra,0x0
    80003fc4:	ade080e7          	jalr	-1314(ra) # 80003a9e <iput>
    return 0;
    80003fc8:	4981                	li	s3,0
    80003fca:	bf19                	j	80003ee0 <namex+0x6a>
  if(*path == 0)
    80003fcc:	d7fd                	beqz	a5,80003fba <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fce:	0004c783          	lbu	a5,0(s1)
    80003fd2:	85a6                	mv	a1,s1
    80003fd4:	b7d1                	j	80003f98 <namex+0x122>

0000000080003fd6 <dirlink>:
{
    80003fd6:	7139                	addi	sp,sp,-64
    80003fd8:	fc06                	sd	ra,56(sp)
    80003fda:	f822                	sd	s0,48(sp)
    80003fdc:	f426                	sd	s1,40(sp)
    80003fde:	f04a                	sd	s2,32(sp)
    80003fe0:	ec4e                	sd	s3,24(sp)
    80003fe2:	e852                	sd	s4,16(sp)
    80003fe4:	0080                	addi	s0,sp,64
    80003fe6:	892a                	mv	s2,a0
    80003fe8:	8a2e                	mv	s4,a1
    80003fea:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fec:	4601                	li	a2,0
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	dd8080e7          	jalr	-552(ra) # 80003dc6 <dirlookup>
    80003ff6:	e93d                	bnez	a0,8000406c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff8:	04c92483          	lw	s1,76(s2)
    80003ffc:	c49d                	beqz	s1,8000402a <dirlink+0x54>
    80003ffe:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004000:	4741                	li	a4,16
    80004002:	86a6                	mv	a3,s1
    80004004:	fc040613          	addi	a2,s0,-64
    80004008:	4581                	li	a1,0
    8000400a:	854a                	mv	a0,s2
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	b8c080e7          	jalr	-1140(ra) # 80003b98 <readi>
    80004014:	47c1                	li	a5,16
    80004016:	06f51163          	bne	a0,a5,80004078 <dirlink+0xa2>
    if(de.inum == 0)
    8000401a:	fc045783          	lhu	a5,-64(s0)
    8000401e:	c791                	beqz	a5,8000402a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004020:	24c1                	addiw	s1,s1,16
    80004022:	04c92783          	lw	a5,76(s2)
    80004026:	fcf4ede3          	bltu	s1,a5,80004000 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000402a:	4639                	li	a2,14
    8000402c:	85d2                	mv	a1,s4
    8000402e:	fc240513          	addi	a0,s0,-62
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	f8a080e7          	jalr	-118(ra) # 80000fbc <strncpy>
  de.inum = inum;
    8000403a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403e:	4741                	li	a4,16
    80004040:	86a6                	mv	a3,s1
    80004042:	fc040613          	addi	a2,s0,-64
    80004046:	4581                	li	a1,0
    80004048:	854a                	mv	a0,s2
    8000404a:	00000097          	auipc	ra,0x0
    8000404e:	c46080e7          	jalr	-954(ra) # 80003c90 <writei>
    80004052:	872a                	mv	a4,a0
    80004054:	47c1                	li	a5,16
  return 0;
    80004056:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004058:	02f71863          	bne	a4,a5,80004088 <dirlink+0xb2>
}
    8000405c:	70e2                	ld	ra,56(sp)
    8000405e:	7442                	ld	s0,48(sp)
    80004060:	74a2                	ld	s1,40(sp)
    80004062:	7902                	ld	s2,32(sp)
    80004064:	69e2                	ld	s3,24(sp)
    80004066:	6a42                	ld	s4,16(sp)
    80004068:	6121                	addi	sp,sp,64
    8000406a:	8082                	ret
    iput(ip);
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	a32080e7          	jalr	-1486(ra) # 80003a9e <iput>
    return -1;
    80004074:	557d                	li	a0,-1
    80004076:	b7dd                	j	8000405c <dirlink+0x86>
      panic("dirlink read");
    80004078:	00004517          	auipc	a0,0x4
    8000407c:	5b050513          	addi	a0,a0,1456 # 80008628 <syscalls+0x1c8>
    80004080:	ffffc097          	auipc	ra,0xffffc
    80004084:	4d6080e7          	jalr	1238(ra) # 80000556 <panic>
    panic("dirlink");
    80004088:	00004517          	auipc	a0,0x4
    8000408c:	6c050513          	addi	a0,a0,1728 # 80008748 <syscalls+0x2e8>
    80004090:	ffffc097          	auipc	ra,0xffffc
    80004094:	4c6080e7          	jalr	1222(ra) # 80000556 <panic>

0000000080004098 <namei>:

struct inode*
namei(char *path)
{
    80004098:	1101                	addi	sp,sp,-32
    8000409a:	ec06                	sd	ra,24(sp)
    8000409c:	e822                	sd	s0,16(sp)
    8000409e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040a0:	fe040613          	addi	a2,s0,-32
    800040a4:	4581                	li	a1,0
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	dd0080e7          	jalr	-560(ra) # 80003e76 <namex>
}
    800040ae:	60e2                	ld	ra,24(sp)
    800040b0:	6442                	ld	s0,16(sp)
    800040b2:	6105                	addi	sp,sp,32
    800040b4:	8082                	ret

00000000800040b6 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040b6:	1141                	addi	sp,sp,-16
    800040b8:	e406                	sd	ra,8(sp)
    800040ba:	e022                	sd	s0,0(sp)
    800040bc:	0800                	addi	s0,sp,16
    800040be:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040c0:	4585                	li	a1,1
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	db4080e7          	jalr	-588(ra) # 80003e76 <namex>
}
    800040ca:	60a2                	ld	ra,8(sp)
    800040cc:	6402                	ld	s0,0(sp)
    800040ce:	0141                	addi	sp,sp,16
    800040d0:	8082                	ret

00000000800040d2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040d2:	1101                	addi	sp,sp,-32
    800040d4:	ec06                	sd	ra,24(sp)
    800040d6:	e822                	sd	s0,16(sp)
    800040d8:	e426                	sd	s1,8(sp)
    800040da:	e04a                	sd	s2,0(sp)
    800040dc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040de:	0003e917          	auipc	s2,0x3e
    800040e2:	84290913          	addi	s2,s2,-1982 # 80041920 <log>
    800040e6:	01892583          	lw	a1,24(s2)
    800040ea:	02892503          	lw	a0,40(s2)
    800040ee:	fffff097          	auipc	ra,0xfffff
    800040f2:	ff4080e7          	jalr	-12(ra) # 800030e2 <bread>
    800040f6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040f8:	02c92683          	lw	a3,44(s2)
    800040fc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040fe:	02d05763          	blez	a3,8000412c <write_head+0x5a>
    80004102:	0003e797          	auipc	a5,0x3e
    80004106:	84e78793          	addi	a5,a5,-1970 # 80041950 <log+0x30>
    8000410a:	05c50713          	addi	a4,a0,92
    8000410e:	36fd                	addiw	a3,a3,-1
    80004110:	1682                	slli	a3,a3,0x20
    80004112:	9281                	srli	a3,a3,0x20
    80004114:	068a                	slli	a3,a3,0x2
    80004116:	0003e617          	auipc	a2,0x3e
    8000411a:	83e60613          	addi	a2,a2,-1986 # 80041954 <log+0x34>
    8000411e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004120:	4390                	lw	a2,0(a5)
    80004122:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004124:	0791                	addi	a5,a5,4
    80004126:	0711                	addi	a4,a4,4
    80004128:	fed79ce3          	bne	a5,a3,80004120 <write_head+0x4e>
  }
  bwrite(buf);
    8000412c:	8526                	mv	a0,s1
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	0a6080e7          	jalr	166(ra) # 800031d4 <bwrite>
  brelse(buf);
    80004136:	8526                	mv	a0,s1
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	0da080e7          	jalr	218(ra) # 80003212 <brelse>
}
    80004140:	60e2                	ld	ra,24(sp)
    80004142:	6442                	ld	s0,16(sp)
    80004144:	64a2                	ld	s1,8(sp)
    80004146:	6902                	ld	s2,0(sp)
    80004148:	6105                	addi	sp,sp,32
    8000414a:	8082                	ret

000000008000414c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000414c:	0003e797          	auipc	a5,0x3e
    80004150:	8007a783          	lw	a5,-2048(a5) # 8004194c <log+0x2c>
    80004154:	0af05663          	blez	a5,80004200 <install_trans+0xb4>
{
    80004158:	7139                	addi	sp,sp,-64
    8000415a:	fc06                	sd	ra,56(sp)
    8000415c:	f822                	sd	s0,48(sp)
    8000415e:	f426                	sd	s1,40(sp)
    80004160:	f04a                	sd	s2,32(sp)
    80004162:	ec4e                	sd	s3,24(sp)
    80004164:	e852                	sd	s4,16(sp)
    80004166:	e456                	sd	s5,8(sp)
    80004168:	0080                	addi	s0,sp,64
    8000416a:	0003da97          	auipc	s5,0x3d
    8000416e:	7e6a8a93          	addi	s5,s5,2022 # 80041950 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004172:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004174:	0003d997          	auipc	s3,0x3d
    80004178:	7ac98993          	addi	s3,s3,1964 # 80041920 <log>
    8000417c:	0189a583          	lw	a1,24(s3)
    80004180:	014585bb          	addw	a1,a1,s4
    80004184:	2585                	addiw	a1,a1,1
    80004186:	0289a503          	lw	a0,40(s3)
    8000418a:	fffff097          	auipc	ra,0xfffff
    8000418e:	f58080e7          	jalr	-168(ra) # 800030e2 <bread>
    80004192:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004194:	000aa583          	lw	a1,0(s5)
    80004198:	0289a503          	lw	a0,40(s3)
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	f46080e7          	jalr	-186(ra) # 800030e2 <bread>
    800041a4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041a6:	40000613          	li	a2,1024
    800041aa:	05890593          	addi	a1,s2,88
    800041ae:	05850513          	addi	a0,a0,88
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	d52080e7          	jalr	-686(ra) # 80000f04 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041ba:	8526                	mv	a0,s1
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	018080e7          	jalr	24(ra) # 800031d4 <bwrite>
    bunpin(dbuf);
    800041c4:	8526                	mv	a0,s1
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	126080e7          	jalr	294(ra) # 800032ec <bunpin>
    brelse(lbuf);
    800041ce:	854a                	mv	a0,s2
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	042080e7          	jalr	66(ra) # 80003212 <brelse>
    brelse(dbuf);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	038080e7          	jalr	56(ra) # 80003212 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e2:	2a05                	addiw	s4,s4,1
    800041e4:	0a91                	addi	s5,s5,4
    800041e6:	02c9a783          	lw	a5,44(s3)
    800041ea:	f8fa49e3          	blt	s4,a5,8000417c <install_trans+0x30>
}
    800041ee:	70e2                	ld	ra,56(sp)
    800041f0:	7442                	ld	s0,48(sp)
    800041f2:	74a2                	ld	s1,40(sp)
    800041f4:	7902                	ld	s2,32(sp)
    800041f6:	69e2                	ld	s3,24(sp)
    800041f8:	6a42                	ld	s4,16(sp)
    800041fa:	6aa2                	ld	s5,8(sp)
    800041fc:	6121                	addi	sp,sp,64
    800041fe:	8082                	ret
    80004200:	8082                	ret

0000000080004202 <initlog>:
{
    80004202:	7179                	addi	sp,sp,-48
    80004204:	f406                	sd	ra,40(sp)
    80004206:	f022                	sd	s0,32(sp)
    80004208:	ec26                	sd	s1,24(sp)
    8000420a:	e84a                	sd	s2,16(sp)
    8000420c:	e44e                	sd	s3,8(sp)
    8000420e:	1800                	addi	s0,sp,48
    80004210:	892a                	mv	s2,a0
    80004212:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004214:	0003d497          	auipc	s1,0x3d
    80004218:	70c48493          	addi	s1,s1,1804 # 80041920 <log>
    8000421c:	00004597          	auipc	a1,0x4
    80004220:	41c58593          	addi	a1,a1,1052 # 80008638 <syscalls+0x1d8>
    80004224:	8526                	mv	a0,s1
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	af2080e7          	jalr	-1294(ra) # 80000d18 <initlock>
  log.start = sb->logstart;
    8000422e:	0149a583          	lw	a1,20(s3)
    80004232:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004234:	0109a783          	lw	a5,16(s3)
    80004238:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000423a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000423e:	854a                	mv	a0,s2
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	ea2080e7          	jalr	-350(ra) # 800030e2 <bread>
  log.lh.n = lh->n;
    80004248:	4d3c                	lw	a5,88(a0)
    8000424a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000424c:	02f05563          	blez	a5,80004276 <initlog+0x74>
    80004250:	05c50713          	addi	a4,a0,92
    80004254:	0003d697          	auipc	a3,0x3d
    80004258:	6fc68693          	addi	a3,a3,1788 # 80041950 <log+0x30>
    8000425c:	37fd                	addiw	a5,a5,-1
    8000425e:	1782                	slli	a5,a5,0x20
    80004260:	9381                	srli	a5,a5,0x20
    80004262:	078a                	slli	a5,a5,0x2
    80004264:	06050613          	addi	a2,a0,96
    80004268:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000426a:	4310                	lw	a2,0(a4)
    8000426c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000426e:	0711                	addi	a4,a4,4
    80004270:	0691                	addi	a3,a3,4
    80004272:	fef71ce3          	bne	a4,a5,8000426a <initlog+0x68>
  brelse(buf);
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	f9c080e7          	jalr	-100(ra) # 80003212 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000427e:	00000097          	auipc	ra,0x0
    80004282:	ece080e7          	jalr	-306(ra) # 8000414c <install_trans>
  log.lh.n = 0;
    80004286:	0003d797          	auipc	a5,0x3d
    8000428a:	6c07a323          	sw	zero,1734(a5) # 8004194c <log+0x2c>
  write_head(); // clear the log
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	e44080e7          	jalr	-444(ra) # 800040d2 <write_head>
}
    80004296:	70a2                	ld	ra,40(sp)
    80004298:	7402                	ld	s0,32(sp)
    8000429a:	64e2                	ld	s1,24(sp)
    8000429c:	6942                	ld	s2,16(sp)
    8000429e:	69a2                	ld	s3,8(sp)
    800042a0:	6145                	addi	sp,sp,48
    800042a2:	8082                	ret

00000000800042a4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042a4:	1101                	addi	sp,sp,-32
    800042a6:	ec06                	sd	ra,24(sp)
    800042a8:	e822                	sd	s0,16(sp)
    800042aa:	e426                	sd	s1,8(sp)
    800042ac:	e04a                	sd	s2,0(sp)
    800042ae:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042b0:	0003d517          	auipc	a0,0x3d
    800042b4:	67050513          	addi	a0,a0,1648 # 80041920 <log>
    800042b8:	ffffd097          	auipc	ra,0xffffd
    800042bc:	af0080e7          	jalr	-1296(ra) # 80000da8 <acquire>
  while(1){
    if(log.committing){
    800042c0:	0003d497          	auipc	s1,0x3d
    800042c4:	66048493          	addi	s1,s1,1632 # 80041920 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c8:	4979                	li	s2,30
    800042ca:	a039                	j	800042d8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042cc:	85a6                	mv	a1,s1
    800042ce:	8526                	mv	a0,s1
    800042d0:	ffffe097          	auipc	ra,0xffffe
    800042d4:	1ba080e7          	jalr	442(ra) # 8000248a <sleep>
    if(log.committing){
    800042d8:	50dc                	lw	a5,36(s1)
    800042da:	fbed                	bnez	a5,800042cc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042dc:	509c                	lw	a5,32(s1)
    800042de:	0017871b          	addiw	a4,a5,1
    800042e2:	0007069b          	sext.w	a3,a4
    800042e6:	0027179b          	slliw	a5,a4,0x2
    800042ea:	9fb9                	addw	a5,a5,a4
    800042ec:	0017979b          	slliw	a5,a5,0x1
    800042f0:	54d8                	lw	a4,44(s1)
    800042f2:	9fb9                	addw	a5,a5,a4
    800042f4:	00f95963          	bge	s2,a5,80004306 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042f8:	85a6                	mv	a1,s1
    800042fa:	8526                	mv	a0,s1
    800042fc:	ffffe097          	auipc	ra,0xffffe
    80004300:	18e080e7          	jalr	398(ra) # 8000248a <sleep>
    80004304:	bfd1                	j	800042d8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004306:	0003d517          	auipc	a0,0x3d
    8000430a:	61a50513          	addi	a0,a0,1562 # 80041920 <log>
    8000430e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	b4c080e7          	jalr	-1204(ra) # 80000e5c <release>
      break;
    }
  }
}
    80004318:	60e2                	ld	ra,24(sp)
    8000431a:	6442                	ld	s0,16(sp)
    8000431c:	64a2                	ld	s1,8(sp)
    8000431e:	6902                	ld	s2,0(sp)
    80004320:	6105                	addi	sp,sp,32
    80004322:	8082                	ret

0000000080004324 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004324:	7139                	addi	sp,sp,-64
    80004326:	fc06                	sd	ra,56(sp)
    80004328:	f822                	sd	s0,48(sp)
    8000432a:	f426                	sd	s1,40(sp)
    8000432c:	f04a                	sd	s2,32(sp)
    8000432e:	ec4e                	sd	s3,24(sp)
    80004330:	e852                	sd	s4,16(sp)
    80004332:	e456                	sd	s5,8(sp)
    80004334:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004336:	0003d497          	auipc	s1,0x3d
    8000433a:	5ea48493          	addi	s1,s1,1514 # 80041920 <log>
    8000433e:	8526                	mv	a0,s1
    80004340:	ffffd097          	auipc	ra,0xffffd
    80004344:	a68080e7          	jalr	-1432(ra) # 80000da8 <acquire>
  log.outstanding -= 1;
    80004348:	509c                	lw	a5,32(s1)
    8000434a:	37fd                	addiw	a5,a5,-1
    8000434c:	0007891b          	sext.w	s2,a5
    80004350:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004352:	50dc                	lw	a5,36(s1)
    80004354:	efb9                	bnez	a5,800043b2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004356:	06091663          	bnez	s2,800043c2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000435a:	0003d497          	auipc	s1,0x3d
    8000435e:	5c648493          	addi	s1,s1,1478 # 80041920 <log>
    80004362:	4785                	li	a5,1
    80004364:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004366:	8526                	mv	a0,s1
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	af4080e7          	jalr	-1292(ra) # 80000e5c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004370:	54dc                	lw	a5,44(s1)
    80004372:	06f04763          	bgtz	a5,800043e0 <end_op+0xbc>
    acquire(&log.lock);
    80004376:	0003d497          	auipc	s1,0x3d
    8000437a:	5aa48493          	addi	s1,s1,1450 # 80041920 <log>
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	a28080e7          	jalr	-1496(ra) # 80000da8 <acquire>
    log.committing = 0;
    80004388:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffe097          	auipc	ra,0xffffe
    80004392:	282080e7          	jalr	642(ra) # 80002610 <wakeup>
    release(&log.lock);
    80004396:	8526                	mv	a0,s1
    80004398:	ffffd097          	auipc	ra,0xffffd
    8000439c:	ac4080e7          	jalr	-1340(ra) # 80000e5c <release>
}
    800043a0:	70e2                	ld	ra,56(sp)
    800043a2:	7442                	ld	s0,48(sp)
    800043a4:	74a2                	ld	s1,40(sp)
    800043a6:	7902                	ld	s2,32(sp)
    800043a8:	69e2                	ld	s3,24(sp)
    800043aa:	6a42                	ld	s4,16(sp)
    800043ac:	6aa2                	ld	s5,8(sp)
    800043ae:	6121                	addi	sp,sp,64
    800043b0:	8082                	ret
    panic("log.committing");
    800043b2:	00004517          	auipc	a0,0x4
    800043b6:	28e50513          	addi	a0,a0,654 # 80008640 <syscalls+0x1e0>
    800043ba:	ffffc097          	auipc	ra,0xffffc
    800043be:	19c080e7          	jalr	412(ra) # 80000556 <panic>
    wakeup(&log);
    800043c2:	0003d497          	auipc	s1,0x3d
    800043c6:	55e48493          	addi	s1,s1,1374 # 80041920 <log>
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffe097          	auipc	ra,0xffffe
    800043d0:	244080e7          	jalr	580(ra) # 80002610 <wakeup>
  release(&log.lock);
    800043d4:	8526                	mv	a0,s1
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	a86080e7          	jalr	-1402(ra) # 80000e5c <release>
  if(do_commit){
    800043de:	b7c9                	j	800043a0 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e0:	0003da97          	auipc	s5,0x3d
    800043e4:	570a8a93          	addi	s5,s5,1392 # 80041950 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043e8:	0003da17          	auipc	s4,0x3d
    800043ec:	538a0a13          	addi	s4,s4,1336 # 80041920 <log>
    800043f0:	018a2583          	lw	a1,24(s4)
    800043f4:	012585bb          	addw	a1,a1,s2
    800043f8:	2585                	addiw	a1,a1,1
    800043fa:	028a2503          	lw	a0,40(s4)
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	ce4080e7          	jalr	-796(ra) # 800030e2 <bread>
    80004406:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004408:	000aa583          	lw	a1,0(s5)
    8000440c:	028a2503          	lw	a0,40(s4)
    80004410:	fffff097          	auipc	ra,0xfffff
    80004414:	cd2080e7          	jalr	-814(ra) # 800030e2 <bread>
    80004418:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000441a:	40000613          	li	a2,1024
    8000441e:	05850593          	addi	a1,a0,88
    80004422:	05848513          	addi	a0,s1,88
    80004426:	ffffd097          	auipc	ra,0xffffd
    8000442a:	ade080e7          	jalr	-1314(ra) # 80000f04 <memmove>
    bwrite(to);  // write the log
    8000442e:	8526                	mv	a0,s1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	da4080e7          	jalr	-604(ra) # 800031d4 <bwrite>
    brelse(from);
    80004438:	854e                	mv	a0,s3
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	dd8080e7          	jalr	-552(ra) # 80003212 <brelse>
    brelse(to);
    80004442:	8526                	mv	a0,s1
    80004444:	fffff097          	auipc	ra,0xfffff
    80004448:	dce080e7          	jalr	-562(ra) # 80003212 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444c:	2905                	addiw	s2,s2,1
    8000444e:	0a91                	addi	s5,s5,4
    80004450:	02ca2783          	lw	a5,44(s4)
    80004454:	f8f94ee3          	blt	s2,a5,800043f0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	c7a080e7          	jalr	-902(ra) # 800040d2 <write_head>
    install_trans(); // Now install writes to home locations
    80004460:	00000097          	auipc	ra,0x0
    80004464:	cec080e7          	jalr	-788(ra) # 8000414c <install_trans>
    log.lh.n = 0;
    80004468:	0003d797          	auipc	a5,0x3d
    8000446c:	4e07a223          	sw	zero,1252(a5) # 8004194c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004470:	00000097          	auipc	ra,0x0
    80004474:	c62080e7          	jalr	-926(ra) # 800040d2 <write_head>
    80004478:	bdfd                	j	80004376 <end_op+0x52>

000000008000447a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004486:	0003d717          	auipc	a4,0x3d
    8000448a:	4c672703          	lw	a4,1222(a4) # 8004194c <log+0x2c>
    8000448e:	47f5                	li	a5,29
    80004490:	08e7c063          	blt	a5,a4,80004510 <log_write+0x96>
    80004494:	84aa                	mv	s1,a0
    80004496:	0003d797          	auipc	a5,0x3d
    8000449a:	4a67a783          	lw	a5,1190(a5) # 8004193c <log+0x1c>
    8000449e:	37fd                	addiw	a5,a5,-1
    800044a0:	06f75863          	bge	a4,a5,80004510 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044a4:	0003d797          	auipc	a5,0x3d
    800044a8:	49c7a783          	lw	a5,1180(a5) # 80041940 <log+0x20>
    800044ac:	06f05a63          	blez	a5,80004520 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044b0:	0003d917          	auipc	s2,0x3d
    800044b4:	47090913          	addi	s2,s2,1136 # 80041920 <log>
    800044b8:	854a                	mv	a0,s2
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	8ee080e7          	jalr	-1810(ra) # 80000da8 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044c2:	02c92603          	lw	a2,44(s2)
    800044c6:	06c05563          	blez	a2,80004530 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044ca:	44cc                	lw	a1,12(s1)
    800044cc:	0003d717          	auipc	a4,0x3d
    800044d0:	48470713          	addi	a4,a4,1156 # 80041950 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044d4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044d6:	4314                	lw	a3,0(a4)
    800044d8:	04b68d63          	beq	a3,a1,80004532 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800044dc:	2785                	addiw	a5,a5,1
    800044de:	0711                	addi	a4,a4,4
    800044e0:	fec79be3          	bne	a5,a2,800044d6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044e4:	0621                	addi	a2,a2,8
    800044e6:	060a                	slli	a2,a2,0x2
    800044e8:	0003d797          	auipc	a5,0x3d
    800044ec:	43878793          	addi	a5,a5,1080 # 80041920 <log>
    800044f0:	963e                	add	a2,a2,a5
    800044f2:	44dc                	lw	a5,12(s1)
    800044f4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044f6:	8526                	mv	a0,s1
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	db8080e7          	jalr	-584(ra) # 800032b0 <bpin>
    log.lh.n++;
    80004500:	0003d717          	auipc	a4,0x3d
    80004504:	42070713          	addi	a4,a4,1056 # 80041920 <log>
    80004508:	575c                	lw	a5,44(a4)
    8000450a:	2785                	addiw	a5,a5,1
    8000450c:	d75c                	sw	a5,44(a4)
    8000450e:	a83d                	j	8000454c <log_write+0xd2>
    panic("too big a transaction");
    80004510:	00004517          	auipc	a0,0x4
    80004514:	14050513          	addi	a0,a0,320 # 80008650 <syscalls+0x1f0>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	03e080e7          	jalr	62(ra) # 80000556 <panic>
    panic("log_write outside of trans");
    80004520:	00004517          	auipc	a0,0x4
    80004524:	14850513          	addi	a0,a0,328 # 80008668 <syscalls+0x208>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	02e080e7          	jalr	46(ra) # 80000556 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004530:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004532:	00878713          	addi	a4,a5,8
    80004536:	00271693          	slli	a3,a4,0x2
    8000453a:	0003d717          	auipc	a4,0x3d
    8000453e:	3e670713          	addi	a4,a4,998 # 80041920 <log>
    80004542:	9736                	add	a4,a4,a3
    80004544:	44d4                	lw	a3,12(s1)
    80004546:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004548:	faf607e3          	beq	a2,a5,800044f6 <log_write+0x7c>
  }
  release(&log.lock);
    8000454c:	0003d517          	auipc	a0,0x3d
    80004550:	3d450513          	addi	a0,a0,980 # 80041920 <log>
    80004554:	ffffd097          	auipc	ra,0xffffd
    80004558:	908080e7          	jalr	-1784(ra) # 80000e5c <release>
}
    8000455c:	60e2                	ld	ra,24(sp)
    8000455e:	6442                	ld	s0,16(sp)
    80004560:	64a2                	ld	s1,8(sp)
    80004562:	6902                	ld	s2,0(sp)
    80004564:	6105                	addi	sp,sp,32
    80004566:	8082                	ret

0000000080004568 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004568:	1101                	addi	sp,sp,-32
    8000456a:	ec06                	sd	ra,24(sp)
    8000456c:	e822                	sd	s0,16(sp)
    8000456e:	e426                	sd	s1,8(sp)
    80004570:	e04a                	sd	s2,0(sp)
    80004572:	1000                	addi	s0,sp,32
    80004574:	84aa                	mv	s1,a0
    80004576:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004578:	00004597          	auipc	a1,0x4
    8000457c:	11058593          	addi	a1,a1,272 # 80008688 <syscalls+0x228>
    80004580:	0521                	addi	a0,a0,8
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	796080e7          	jalr	1942(ra) # 80000d18 <initlock>
  lk->name = name;
    8000458a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000458e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004592:	0204a423          	sw	zero,40(s1)
}
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	64a2                	ld	s1,8(sp)
    8000459c:	6902                	ld	s2,0(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret

00000000800045a2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045a2:	1101                	addi	sp,sp,-32
    800045a4:	ec06                	sd	ra,24(sp)
    800045a6:	e822                	sd	s0,16(sp)
    800045a8:	e426                	sd	s1,8(sp)
    800045aa:	e04a                	sd	s2,0(sp)
    800045ac:	1000                	addi	s0,sp,32
    800045ae:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045b0:	00850913          	addi	s2,a0,8
    800045b4:	854a                	mv	a0,s2
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	7f2080e7          	jalr	2034(ra) # 80000da8 <acquire>
  while (lk->locked) {
    800045be:	409c                	lw	a5,0(s1)
    800045c0:	cb89                	beqz	a5,800045d2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045c2:	85ca                	mv	a1,s2
    800045c4:	8526                	mv	a0,s1
    800045c6:	ffffe097          	auipc	ra,0xffffe
    800045ca:	ec4080e7          	jalr	-316(ra) # 8000248a <sleep>
  while (lk->locked) {
    800045ce:	409c                	lw	a5,0(s1)
    800045d0:	fbed                	bnez	a5,800045c2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045d2:	4785                	li	a5,1
    800045d4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045d6:	ffffd097          	auipc	ra,0xffffd
    800045da:	6a4080e7          	jalr	1700(ra) # 80001c7a <myproc>
    800045de:	5d1c                	lw	a5,56(a0)
    800045e0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045e2:	854a                	mv	a0,s2
    800045e4:	ffffd097          	auipc	ra,0xffffd
    800045e8:	878080e7          	jalr	-1928(ra) # 80000e5c <release>
}
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6902                	ld	s2,0(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	e04a                	sd	s2,0(sp)
    80004602:	1000                	addi	s0,sp,32
    80004604:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004606:	00850913          	addi	s2,a0,8
    8000460a:	854a                	mv	a0,s2
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	79c080e7          	jalr	1948(ra) # 80000da8 <acquire>
  lk->locked = 0;
    80004614:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004618:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000461c:	8526                	mv	a0,s1
    8000461e:	ffffe097          	auipc	ra,0xffffe
    80004622:	ff2080e7          	jalr	-14(ra) # 80002610 <wakeup>
  release(&lk->lk);
    80004626:	854a                	mv	a0,s2
    80004628:	ffffd097          	auipc	ra,0xffffd
    8000462c:	834080e7          	jalr	-1996(ra) # 80000e5c <release>
}
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6902                	ld	s2,0(sp)
    80004638:	6105                	addi	sp,sp,32
    8000463a:	8082                	ret

000000008000463c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000463c:	7179                	addi	sp,sp,-48
    8000463e:	f406                	sd	ra,40(sp)
    80004640:	f022                	sd	s0,32(sp)
    80004642:	ec26                	sd	s1,24(sp)
    80004644:	e84a                	sd	s2,16(sp)
    80004646:	e44e                	sd	s3,8(sp)
    80004648:	1800                	addi	s0,sp,48
    8000464a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000464c:	00850913          	addi	s2,a0,8
    80004650:	854a                	mv	a0,s2
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	756080e7          	jalr	1878(ra) # 80000da8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000465a:	409c                	lw	a5,0(s1)
    8000465c:	ef99                	bnez	a5,8000467a <holdingsleep+0x3e>
    8000465e:	4481                	li	s1,0
  release(&lk->lk);
    80004660:	854a                	mv	a0,s2
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	7fa080e7          	jalr	2042(ra) # 80000e5c <release>
  return r;
}
    8000466a:	8526                	mv	a0,s1
    8000466c:	70a2                	ld	ra,40(sp)
    8000466e:	7402                	ld	s0,32(sp)
    80004670:	64e2                	ld	s1,24(sp)
    80004672:	6942                	ld	s2,16(sp)
    80004674:	69a2                	ld	s3,8(sp)
    80004676:	6145                	addi	sp,sp,48
    80004678:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000467a:	0284a983          	lw	s3,40(s1)
    8000467e:	ffffd097          	auipc	ra,0xffffd
    80004682:	5fc080e7          	jalr	1532(ra) # 80001c7a <myproc>
    80004686:	5d04                	lw	s1,56(a0)
    80004688:	413484b3          	sub	s1,s1,s3
    8000468c:	0014b493          	seqz	s1,s1
    80004690:	bfc1                	j	80004660 <holdingsleep+0x24>

0000000080004692 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004692:	1141                	addi	sp,sp,-16
    80004694:	e406                	sd	ra,8(sp)
    80004696:	e022                	sd	s0,0(sp)
    80004698:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000469a:	00004597          	auipc	a1,0x4
    8000469e:	ffe58593          	addi	a1,a1,-2 # 80008698 <syscalls+0x238>
    800046a2:	0003d517          	auipc	a0,0x3d
    800046a6:	3c650513          	addi	a0,a0,966 # 80041a68 <ftable>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	66e080e7          	jalr	1646(ra) # 80000d18 <initlock>
}
    800046b2:	60a2                	ld	ra,8(sp)
    800046b4:	6402                	ld	s0,0(sp)
    800046b6:	0141                	addi	sp,sp,16
    800046b8:	8082                	ret

00000000800046ba <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046ba:	1101                	addi	sp,sp,-32
    800046bc:	ec06                	sd	ra,24(sp)
    800046be:	e822                	sd	s0,16(sp)
    800046c0:	e426                	sd	s1,8(sp)
    800046c2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046c4:	0003d517          	auipc	a0,0x3d
    800046c8:	3a450513          	addi	a0,a0,932 # 80041a68 <ftable>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	6dc080e7          	jalr	1756(ra) # 80000da8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d4:	0003d497          	auipc	s1,0x3d
    800046d8:	3ac48493          	addi	s1,s1,940 # 80041a80 <ftable+0x18>
    800046dc:	0003e717          	auipc	a4,0x3e
    800046e0:	34470713          	addi	a4,a4,836 # 80042a20 <ftable+0xfb8>
    if(f->ref == 0){
    800046e4:	40dc                	lw	a5,4(s1)
    800046e6:	cf99                	beqz	a5,80004704 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046e8:	02848493          	addi	s1,s1,40
    800046ec:	fee49ce3          	bne	s1,a4,800046e4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046f0:	0003d517          	auipc	a0,0x3d
    800046f4:	37850513          	addi	a0,a0,888 # 80041a68 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	764080e7          	jalr	1892(ra) # 80000e5c <release>
  return 0;
    80004700:	4481                	li	s1,0
    80004702:	a819                	j	80004718 <filealloc+0x5e>
      f->ref = 1;
    80004704:	4785                	li	a5,1
    80004706:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004708:	0003d517          	auipc	a0,0x3d
    8000470c:	36050513          	addi	a0,a0,864 # 80041a68 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	74c080e7          	jalr	1868(ra) # 80000e5c <release>
}
    80004718:	8526                	mv	a0,s1
    8000471a:	60e2                	ld	ra,24(sp)
    8000471c:	6442                	ld	s0,16(sp)
    8000471e:	64a2                	ld	s1,8(sp)
    80004720:	6105                	addi	sp,sp,32
    80004722:	8082                	ret

0000000080004724 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004724:	1101                	addi	sp,sp,-32
    80004726:	ec06                	sd	ra,24(sp)
    80004728:	e822                	sd	s0,16(sp)
    8000472a:	e426                	sd	s1,8(sp)
    8000472c:	1000                	addi	s0,sp,32
    8000472e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004730:	0003d517          	auipc	a0,0x3d
    80004734:	33850513          	addi	a0,a0,824 # 80041a68 <ftable>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	670080e7          	jalr	1648(ra) # 80000da8 <acquire>
  if(f->ref < 1)
    80004740:	40dc                	lw	a5,4(s1)
    80004742:	02f05263          	blez	a5,80004766 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004746:	2785                	addiw	a5,a5,1
    80004748:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000474a:	0003d517          	auipc	a0,0x3d
    8000474e:	31e50513          	addi	a0,a0,798 # 80041a68 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	70a080e7          	jalr	1802(ra) # 80000e5c <release>
  return f;
}
    8000475a:	8526                	mv	a0,s1
    8000475c:	60e2                	ld	ra,24(sp)
    8000475e:	6442                	ld	s0,16(sp)
    80004760:	64a2                	ld	s1,8(sp)
    80004762:	6105                	addi	sp,sp,32
    80004764:	8082                	ret
    panic("filedup");
    80004766:	00004517          	auipc	a0,0x4
    8000476a:	f3a50513          	addi	a0,a0,-198 # 800086a0 <syscalls+0x240>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	de8080e7          	jalr	-536(ra) # 80000556 <panic>

0000000080004776 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004776:	7139                	addi	sp,sp,-64
    80004778:	fc06                	sd	ra,56(sp)
    8000477a:	f822                	sd	s0,48(sp)
    8000477c:	f426                	sd	s1,40(sp)
    8000477e:	f04a                	sd	s2,32(sp)
    80004780:	ec4e                	sd	s3,24(sp)
    80004782:	e852                	sd	s4,16(sp)
    80004784:	e456                	sd	s5,8(sp)
    80004786:	0080                	addi	s0,sp,64
    80004788:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000478a:	0003d517          	auipc	a0,0x3d
    8000478e:	2de50513          	addi	a0,a0,734 # 80041a68 <ftable>
    80004792:	ffffc097          	auipc	ra,0xffffc
    80004796:	616080e7          	jalr	1558(ra) # 80000da8 <acquire>
  if(f->ref < 1)
    8000479a:	40dc                	lw	a5,4(s1)
    8000479c:	06f05163          	blez	a5,800047fe <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047a0:	37fd                	addiw	a5,a5,-1
    800047a2:	0007871b          	sext.w	a4,a5
    800047a6:	c0dc                	sw	a5,4(s1)
    800047a8:	06e04363          	bgtz	a4,8000480e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047ac:	0004a903          	lw	s2,0(s1)
    800047b0:	0094ca83          	lbu	s5,9(s1)
    800047b4:	0104ba03          	ld	s4,16(s1)
    800047b8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047bc:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047c0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047c4:	0003d517          	auipc	a0,0x3d
    800047c8:	2a450513          	addi	a0,a0,676 # 80041a68 <ftable>
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	690080e7          	jalr	1680(ra) # 80000e5c <release>

  if(ff.type == FD_PIPE){
    800047d4:	4785                	li	a5,1
    800047d6:	04f90d63          	beq	s2,a5,80004830 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047da:	3979                	addiw	s2,s2,-2
    800047dc:	4785                	li	a5,1
    800047de:	0527e063          	bltu	a5,s2,8000481e <fileclose+0xa8>
    begin_op();
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	ac2080e7          	jalr	-1342(ra) # 800042a4 <begin_op>
    iput(ff.ip);
    800047ea:	854e                	mv	a0,s3
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	2b2080e7          	jalr	690(ra) # 80003a9e <iput>
    end_op();
    800047f4:	00000097          	auipc	ra,0x0
    800047f8:	b30080e7          	jalr	-1232(ra) # 80004324 <end_op>
    800047fc:	a00d                	j	8000481e <fileclose+0xa8>
    panic("fileclose");
    800047fe:	00004517          	auipc	a0,0x4
    80004802:	eaa50513          	addi	a0,a0,-342 # 800086a8 <syscalls+0x248>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	d50080e7          	jalr	-688(ra) # 80000556 <panic>
    release(&ftable.lock);
    8000480e:	0003d517          	auipc	a0,0x3d
    80004812:	25a50513          	addi	a0,a0,602 # 80041a68 <ftable>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	646080e7          	jalr	1606(ra) # 80000e5c <release>
  }
}
    8000481e:	70e2                	ld	ra,56(sp)
    80004820:	7442                	ld	s0,48(sp)
    80004822:	74a2                	ld	s1,40(sp)
    80004824:	7902                	ld	s2,32(sp)
    80004826:	69e2                	ld	s3,24(sp)
    80004828:	6a42                	ld	s4,16(sp)
    8000482a:	6aa2                	ld	s5,8(sp)
    8000482c:	6121                	addi	sp,sp,64
    8000482e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004830:	85d6                	mv	a1,s5
    80004832:	8552                	mv	a0,s4
    80004834:	00000097          	auipc	ra,0x0
    80004838:	372080e7          	jalr	882(ra) # 80004ba6 <pipeclose>
    8000483c:	b7cd                	j	8000481e <fileclose+0xa8>

000000008000483e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000483e:	715d                	addi	sp,sp,-80
    80004840:	e486                	sd	ra,72(sp)
    80004842:	e0a2                	sd	s0,64(sp)
    80004844:	fc26                	sd	s1,56(sp)
    80004846:	f84a                	sd	s2,48(sp)
    80004848:	f44e                	sd	s3,40(sp)
    8000484a:	0880                	addi	s0,sp,80
    8000484c:	84aa                	mv	s1,a0
    8000484e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004850:	ffffd097          	auipc	ra,0xffffd
    80004854:	42a080e7          	jalr	1066(ra) # 80001c7a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004858:	409c                	lw	a5,0(s1)
    8000485a:	37f9                	addiw	a5,a5,-2
    8000485c:	4705                	li	a4,1
    8000485e:	04f76763          	bltu	a4,a5,800048ac <filestat+0x6e>
    80004862:	892a                	mv	s2,a0
    ilock(f->ip);
    80004864:	6c88                	ld	a0,24(s1)
    80004866:	fffff097          	auipc	ra,0xfffff
    8000486a:	07e080e7          	jalr	126(ra) # 800038e4 <ilock>
    stati(f->ip, &st);
    8000486e:	fb840593          	addi	a1,s0,-72
    80004872:	6c88                	ld	a0,24(s1)
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	2fa080e7          	jalr	762(ra) # 80003b6e <stati>
    iunlock(f->ip);
    8000487c:	6c88                	ld	a0,24(s1)
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	128080e7          	jalr	296(ra) # 800039a6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004886:	46e1                	li	a3,24
    80004888:	fb840613          	addi	a2,s0,-72
    8000488c:	85ce                	mv	a1,s3
    8000488e:	05093503          	ld	a0,80(s2)
    80004892:	ffffd097          	auipc	ra,0xffffd
    80004896:	202080e7          	jalr	514(ra) # 80001a94 <copyout>
    8000489a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000489e:	60a6                	ld	ra,72(sp)
    800048a0:	6406                	ld	s0,64(sp)
    800048a2:	74e2                	ld	s1,56(sp)
    800048a4:	7942                	ld	s2,48(sp)
    800048a6:	79a2                	ld	s3,40(sp)
    800048a8:	6161                	addi	sp,sp,80
    800048aa:	8082                	ret
  return -1;
    800048ac:	557d                	li	a0,-1
    800048ae:	bfc5                	j	8000489e <filestat+0x60>

00000000800048b0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048b0:	7179                	addi	sp,sp,-48
    800048b2:	f406                	sd	ra,40(sp)
    800048b4:	f022                	sd	s0,32(sp)
    800048b6:	ec26                	sd	s1,24(sp)
    800048b8:	e84a                	sd	s2,16(sp)
    800048ba:	e44e                	sd	s3,8(sp)
    800048bc:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048be:	00854783          	lbu	a5,8(a0)
    800048c2:	c3d5                	beqz	a5,80004966 <fileread+0xb6>
    800048c4:	84aa                	mv	s1,a0
    800048c6:	89ae                	mv	s3,a1
    800048c8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ca:	411c                	lw	a5,0(a0)
    800048cc:	4705                	li	a4,1
    800048ce:	04e78963          	beq	a5,a4,80004920 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d2:	470d                	li	a4,3
    800048d4:	04e78d63          	beq	a5,a4,8000492e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048d8:	4709                	li	a4,2
    800048da:	06e79e63          	bne	a5,a4,80004956 <fileread+0xa6>
    ilock(f->ip);
    800048de:	6d08                	ld	a0,24(a0)
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	004080e7          	jalr	4(ra) # 800038e4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048e8:	874a                	mv	a4,s2
    800048ea:	5094                	lw	a3,32(s1)
    800048ec:	864e                	mv	a2,s3
    800048ee:	4585                	li	a1,1
    800048f0:	6c88                	ld	a0,24(s1)
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	2a6080e7          	jalr	678(ra) # 80003b98 <readi>
    800048fa:	892a                	mv	s2,a0
    800048fc:	00a05563          	blez	a0,80004906 <fileread+0x56>
      f->off += r;
    80004900:	509c                	lw	a5,32(s1)
    80004902:	9fa9                	addw	a5,a5,a0
    80004904:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004906:	6c88                	ld	a0,24(s1)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	09e080e7          	jalr	158(ra) # 800039a6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004910:	854a                	mv	a0,s2
    80004912:	70a2                	ld	ra,40(sp)
    80004914:	7402                	ld	s0,32(sp)
    80004916:	64e2                	ld	s1,24(sp)
    80004918:	6942                	ld	s2,16(sp)
    8000491a:	69a2                	ld	s3,8(sp)
    8000491c:	6145                	addi	sp,sp,48
    8000491e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004920:	6908                	ld	a0,16(a0)
    80004922:	00000097          	auipc	ra,0x0
    80004926:	418080e7          	jalr	1048(ra) # 80004d3a <piperead>
    8000492a:	892a                	mv	s2,a0
    8000492c:	b7d5                	j	80004910 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000492e:	02451783          	lh	a5,36(a0)
    80004932:	03079693          	slli	a3,a5,0x30
    80004936:	92c1                	srli	a3,a3,0x30
    80004938:	4725                	li	a4,9
    8000493a:	02d76863          	bltu	a4,a3,8000496a <fileread+0xba>
    8000493e:	0792                	slli	a5,a5,0x4
    80004940:	0003d717          	auipc	a4,0x3d
    80004944:	08870713          	addi	a4,a4,136 # 800419c8 <devsw>
    80004948:	97ba                	add	a5,a5,a4
    8000494a:	639c                	ld	a5,0(a5)
    8000494c:	c38d                	beqz	a5,8000496e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000494e:	4505                	li	a0,1
    80004950:	9782                	jalr	a5
    80004952:	892a                	mv	s2,a0
    80004954:	bf75                	j	80004910 <fileread+0x60>
    panic("fileread");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	d6250513          	addi	a0,a0,-670 # 800086b8 <syscalls+0x258>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	bf8080e7          	jalr	-1032(ra) # 80000556 <panic>
    return -1;
    80004966:	597d                	li	s2,-1
    80004968:	b765                	j	80004910 <fileread+0x60>
      return -1;
    8000496a:	597d                	li	s2,-1
    8000496c:	b755                	j	80004910 <fileread+0x60>
    8000496e:	597d                	li	s2,-1
    80004970:	b745                	j	80004910 <fileread+0x60>

0000000080004972 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004972:	00954783          	lbu	a5,9(a0)
    80004976:	14078563          	beqz	a5,80004ac0 <filewrite+0x14e>
{
    8000497a:	715d                	addi	sp,sp,-80
    8000497c:	e486                	sd	ra,72(sp)
    8000497e:	e0a2                	sd	s0,64(sp)
    80004980:	fc26                	sd	s1,56(sp)
    80004982:	f84a                	sd	s2,48(sp)
    80004984:	f44e                	sd	s3,40(sp)
    80004986:	f052                	sd	s4,32(sp)
    80004988:	ec56                	sd	s5,24(sp)
    8000498a:	e85a                	sd	s6,16(sp)
    8000498c:	e45e                	sd	s7,8(sp)
    8000498e:	e062                	sd	s8,0(sp)
    80004990:	0880                	addi	s0,sp,80
    80004992:	892a                	mv	s2,a0
    80004994:	8aae                	mv	s5,a1
    80004996:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004998:	411c                	lw	a5,0(a0)
    8000499a:	4705                	li	a4,1
    8000499c:	02e78263          	beq	a5,a4,800049c0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a0:	470d                	li	a4,3
    800049a2:	02e78563          	beq	a5,a4,800049cc <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049a6:	4709                	li	a4,2
    800049a8:	10e79463          	bne	a5,a4,80004ab0 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049ac:	0ec05e63          	blez	a2,80004aa8 <filewrite+0x136>
    int i = 0;
    800049b0:	4981                	li	s3,0
    800049b2:	6b05                	lui	s6,0x1
    800049b4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049b8:	6b85                	lui	s7,0x1
    800049ba:	c00b8b9b          	addiw	s7,s7,-1024
    800049be:	a851                	j	80004a52 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049c0:	6908                	ld	a0,16(a0)
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	254080e7          	jalr	596(ra) # 80004c16 <pipewrite>
    800049ca:	a85d                	j	80004a80 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049cc:	02451783          	lh	a5,36(a0)
    800049d0:	03079693          	slli	a3,a5,0x30
    800049d4:	92c1                	srli	a3,a3,0x30
    800049d6:	4725                	li	a4,9
    800049d8:	0ed76663          	bltu	a4,a3,80004ac4 <filewrite+0x152>
    800049dc:	0792                	slli	a5,a5,0x4
    800049de:	0003d717          	auipc	a4,0x3d
    800049e2:	fea70713          	addi	a4,a4,-22 # 800419c8 <devsw>
    800049e6:	97ba                	add	a5,a5,a4
    800049e8:	679c                	ld	a5,8(a5)
    800049ea:	cff9                	beqz	a5,80004ac8 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800049ec:	4505                	li	a0,1
    800049ee:	9782                	jalr	a5
    800049f0:	a841                	j	80004a80 <filewrite+0x10e>
    800049f2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	8ae080e7          	jalr	-1874(ra) # 800042a4 <begin_op>
      ilock(f->ip);
    800049fe:	01893503          	ld	a0,24(s2)
    80004a02:	fffff097          	auipc	ra,0xfffff
    80004a06:	ee2080e7          	jalr	-286(ra) # 800038e4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a0a:	8762                	mv	a4,s8
    80004a0c:	02092683          	lw	a3,32(s2)
    80004a10:	01598633          	add	a2,s3,s5
    80004a14:	4585                	li	a1,1
    80004a16:	01893503          	ld	a0,24(s2)
    80004a1a:	fffff097          	auipc	ra,0xfffff
    80004a1e:	276080e7          	jalr	630(ra) # 80003c90 <writei>
    80004a22:	84aa                	mv	s1,a0
    80004a24:	02a05f63          	blez	a0,80004a62 <filewrite+0xf0>
        f->off += r;
    80004a28:	02092783          	lw	a5,32(s2)
    80004a2c:	9fa9                	addw	a5,a5,a0
    80004a2e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a32:	01893503          	ld	a0,24(s2)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	f70080e7          	jalr	-144(ra) # 800039a6 <iunlock>
      end_op();
    80004a3e:	00000097          	auipc	ra,0x0
    80004a42:	8e6080e7          	jalr	-1818(ra) # 80004324 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a46:	049c1963          	bne	s8,s1,80004a98 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a4a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a4e:	0349d663          	bge	s3,s4,80004a7a <filewrite+0x108>
      int n1 = n - i;
    80004a52:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a56:	84be                	mv	s1,a5
    80004a58:	2781                	sext.w	a5,a5
    80004a5a:	f8fb5ce3          	bge	s6,a5,800049f2 <filewrite+0x80>
    80004a5e:	84de                	mv	s1,s7
    80004a60:	bf49                	j	800049f2 <filewrite+0x80>
      iunlock(f->ip);
    80004a62:	01893503          	ld	a0,24(s2)
    80004a66:	fffff097          	auipc	ra,0xfffff
    80004a6a:	f40080e7          	jalr	-192(ra) # 800039a6 <iunlock>
      end_op();
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	8b6080e7          	jalr	-1866(ra) # 80004324 <end_op>
      if(r < 0)
    80004a76:	fc04d8e3          	bgez	s1,80004a46 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a7a:	8552                	mv	a0,s4
    80004a7c:	033a1863          	bne	s4,s3,80004aac <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a80:	60a6                	ld	ra,72(sp)
    80004a82:	6406                	ld	s0,64(sp)
    80004a84:	74e2                	ld	s1,56(sp)
    80004a86:	7942                	ld	s2,48(sp)
    80004a88:	79a2                	ld	s3,40(sp)
    80004a8a:	7a02                	ld	s4,32(sp)
    80004a8c:	6ae2                	ld	s5,24(sp)
    80004a8e:	6b42                	ld	s6,16(sp)
    80004a90:	6ba2                	ld	s7,8(sp)
    80004a92:	6c02                	ld	s8,0(sp)
    80004a94:	6161                	addi	sp,sp,80
    80004a96:	8082                	ret
        panic("short filewrite");
    80004a98:	00004517          	auipc	a0,0x4
    80004a9c:	c3050513          	addi	a0,a0,-976 # 800086c8 <syscalls+0x268>
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	ab6080e7          	jalr	-1354(ra) # 80000556 <panic>
    int i = 0;
    80004aa8:	4981                	li	s3,0
    80004aaa:	bfc1                	j	80004a7a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004aac:	557d                	li	a0,-1
    80004aae:	bfc9                	j	80004a80 <filewrite+0x10e>
    panic("filewrite");
    80004ab0:	00004517          	auipc	a0,0x4
    80004ab4:	c2850513          	addi	a0,a0,-984 # 800086d8 <syscalls+0x278>
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	a9e080e7          	jalr	-1378(ra) # 80000556 <panic>
    return -1;
    80004ac0:	557d                	li	a0,-1
}
    80004ac2:	8082                	ret
      return -1;
    80004ac4:	557d                	li	a0,-1
    80004ac6:	bf6d                	j	80004a80 <filewrite+0x10e>
    80004ac8:	557d                	li	a0,-1
    80004aca:	bf5d                	j	80004a80 <filewrite+0x10e>

0000000080004acc <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004acc:	7179                	addi	sp,sp,-48
    80004ace:	f406                	sd	ra,40(sp)
    80004ad0:	f022                	sd	s0,32(sp)
    80004ad2:	ec26                	sd	s1,24(sp)
    80004ad4:	e84a                	sd	s2,16(sp)
    80004ad6:	e44e                	sd	s3,8(sp)
    80004ad8:	e052                	sd	s4,0(sp)
    80004ada:	1800                	addi	s0,sp,48
    80004adc:	84aa                	mv	s1,a0
    80004ade:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ae0:	0005b023          	sd	zero,0(a1)
    80004ae4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ae8:	00000097          	auipc	ra,0x0
    80004aec:	bd2080e7          	jalr	-1070(ra) # 800046ba <filealloc>
    80004af0:	e088                	sd	a0,0(s1)
    80004af2:	c551                	beqz	a0,80004b7e <pipealloc+0xb2>
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	bc6080e7          	jalr	-1082(ra) # 800046ba <filealloc>
    80004afc:	00aa3023          	sd	a0,0(s4)
    80004b00:	c92d                	beqz	a0,80004b72 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	096080e7          	jalr	150(ra) # 80000b98 <kalloc>
    80004b0a:	892a                	mv	s2,a0
    80004b0c:	c125                	beqz	a0,80004b6c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b0e:	4985                	li	s3,1
    80004b10:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b14:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b18:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b1c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b20:	00004597          	auipc	a1,0x4
    80004b24:	bc858593          	addi	a1,a1,-1080 # 800086e8 <syscalls+0x288>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	1f0080e7          	jalr	496(ra) # 80000d18 <initlock>
  (*f0)->type = FD_PIPE;
    80004b30:	609c                	ld	a5,0(s1)
    80004b32:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b36:	609c                	ld	a5,0(s1)
    80004b38:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b3c:	609c                	ld	a5,0(s1)
    80004b3e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b42:	609c                	ld	a5,0(s1)
    80004b44:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b48:	000a3783          	ld	a5,0(s4)
    80004b4c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b50:	000a3783          	ld	a5,0(s4)
    80004b54:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b58:	000a3783          	ld	a5,0(s4)
    80004b5c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b60:	000a3783          	ld	a5,0(s4)
    80004b64:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b68:	4501                	li	a0,0
    80004b6a:	a025                	j	80004b92 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b6c:	6088                	ld	a0,0(s1)
    80004b6e:	e501                	bnez	a0,80004b76 <pipealloc+0xaa>
    80004b70:	a039                	j	80004b7e <pipealloc+0xb2>
    80004b72:	6088                	ld	a0,0(s1)
    80004b74:	c51d                	beqz	a0,80004ba2 <pipealloc+0xd6>
    fileclose(*f0);
    80004b76:	00000097          	auipc	ra,0x0
    80004b7a:	c00080e7          	jalr	-1024(ra) # 80004776 <fileclose>
  if(*f1)
    80004b7e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b82:	557d                	li	a0,-1
  if(*f1)
    80004b84:	c799                	beqz	a5,80004b92 <pipealloc+0xc6>
    fileclose(*f1);
    80004b86:	853e                	mv	a0,a5
    80004b88:	00000097          	auipc	ra,0x0
    80004b8c:	bee080e7          	jalr	-1042(ra) # 80004776 <fileclose>
  return -1;
    80004b90:	557d                	li	a0,-1
}
    80004b92:	70a2                	ld	ra,40(sp)
    80004b94:	7402                	ld	s0,32(sp)
    80004b96:	64e2                	ld	s1,24(sp)
    80004b98:	6942                	ld	s2,16(sp)
    80004b9a:	69a2                	ld	s3,8(sp)
    80004b9c:	6a02                	ld	s4,0(sp)
    80004b9e:	6145                	addi	sp,sp,48
    80004ba0:	8082                	ret
  return -1;
    80004ba2:	557d                	li	a0,-1
    80004ba4:	b7fd                	j	80004b92 <pipealloc+0xc6>

0000000080004ba6 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ba6:	1101                	addi	sp,sp,-32
    80004ba8:	ec06                	sd	ra,24(sp)
    80004baa:	e822                	sd	s0,16(sp)
    80004bac:	e426                	sd	s1,8(sp)
    80004bae:	e04a                	sd	s2,0(sp)
    80004bb0:	1000                	addi	s0,sp,32
    80004bb2:	84aa                	mv	s1,a0
    80004bb4:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	1f2080e7          	jalr	498(ra) # 80000da8 <acquire>
  if(writable){
    80004bbe:	02090d63          	beqz	s2,80004bf8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bc2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bc6:	21848513          	addi	a0,s1,536
    80004bca:	ffffe097          	auipc	ra,0xffffe
    80004bce:	a46080e7          	jalr	-1466(ra) # 80002610 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bd2:	2204b783          	ld	a5,544(s1)
    80004bd6:	eb95                	bnez	a5,80004c0a <pipeclose+0x64>
    release(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	282080e7          	jalr	642(ra) # 80000e5c <release>
    kfree((char*)pi);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	e4e080e7          	jalr	-434(ra) # 80000a32 <kfree>
  } else
    release(&pi->lock);
}
    80004bec:	60e2                	ld	ra,24(sp)
    80004bee:	6442                	ld	s0,16(sp)
    80004bf0:	64a2                	ld	s1,8(sp)
    80004bf2:	6902                	ld	s2,0(sp)
    80004bf4:	6105                	addi	sp,sp,32
    80004bf6:	8082                	ret
    pi->readopen = 0;
    80004bf8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bfc:	21c48513          	addi	a0,s1,540
    80004c00:	ffffe097          	auipc	ra,0xffffe
    80004c04:	a10080e7          	jalr	-1520(ra) # 80002610 <wakeup>
    80004c08:	b7e9                	j	80004bd2 <pipeclose+0x2c>
    release(&pi->lock);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	250080e7          	jalr	592(ra) # 80000e5c <release>
}
    80004c14:	bfe1                	j	80004bec <pipeclose+0x46>

0000000080004c16 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c16:	7119                	addi	sp,sp,-128
    80004c18:	fc86                	sd	ra,120(sp)
    80004c1a:	f8a2                	sd	s0,112(sp)
    80004c1c:	f4a6                	sd	s1,104(sp)
    80004c1e:	f0ca                	sd	s2,96(sp)
    80004c20:	ecce                	sd	s3,88(sp)
    80004c22:	e8d2                	sd	s4,80(sp)
    80004c24:	e4d6                	sd	s5,72(sp)
    80004c26:	e0da                	sd	s6,64(sp)
    80004c28:	fc5e                	sd	s7,56(sp)
    80004c2a:	f862                	sd	s8,48(sp)
    80004c2c:	f466                	sd	s9,40(sp)
    80004c2e:	f06a                	sd	s10,32(sp)
    80004c30:	ec6e                	sd	s11,24(sp)
    80004c32:	0100                	addi	s0,sp,128
    80004c34:	84aa                	mv	s1,a0
    80004c36:	8cae                	mv	s9,a1
    80004c38:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	040080e7          	jalr	64(ra) # 80001c7a <myproc>
    80004c42:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	162080e7          	jalr	354(ra) # 80000da8 <acquire>
  for(i = 0; i < n; i++){
    80004c4e:	0d605963          	blez	s6,80004d20 <pipewrite+0x10a>
    80004c52:	89a6                	mv	s3,s1
    80004c54:	3b7d                	addiw	s6,s6,-1
    80004c56:	1b02                	slli	s6,s6,0x20
    80004c58:	020b5b13          	srli	s6,s6,0x20
    80004c5c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c5e:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c62:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c66:	5dfd                	li	s11,-1
    80004c68:	000b8d1b          	sext.w	s10,s7
    80004c6c:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c6e:	2184a783          	lw	a5,536(s1)
    80004c72:	21c4a703          	lw	a4,540(s1)
    80004c76:	2007879b          	addiw	a5,a5,512
    80004c7a:	02f71b63          	bne	a4,a5,80004cb0 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004c7e:	2204a783          	lw	a5,544(s1)
    80004c82:	cbad                	beqz	a5,80004cf4 <pipewrite+0xde>
    80004c84:	03092783          	lw	a5,48(s2)
    80004c88:	e7b5                	bnez	a5,80004cf4 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004c8a:	8556                	mv	a0,s5
    80004c8c:	ffffe097          	auipc	ra,0xffffe
    80004c90:	984080e7          	jalr	-1660(ra) # 80002610 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c94:	85ce                	mv	a1,s3
    80004c96:	8552                	mv	a0,s4
    80004c98:	ffffd097          	auipc	ra,0xffffd
    80004c9c:	7f2080e7          	jalr	2034(ra) # 8000248a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ca0:	2184a783          	lw	a5,536(s1)
    80004ca4:	21c4a703          	lw	a4,540(s1)
    80004ca8:	2007879b          	addiw	a5,a5,512
    80004cac:	fcf709e3          	beq	a4,a5,80004c7e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb0:	4685                	li	a3,1
    80004cb2:	019b8633          	add	a2,s7,s9
    80004cb6:	f8f40593          	addi	a1,s0,-113
    80004cba:	05093503          	ld	a0,80(s2)
    80004cbe:	ffffd097          	auipc	ra,0xffffd
    80004cc2:	b9a080e7          	jalr	-1126(ra) # 80001858 <copyin>
    80004cc6:	05b50e63          	beq	a0,s11,80004d22 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cca:	21c4a783          	lw	a5,540(s1)
    80004cce:	0017871b          	addiw	a4,a5,1
    80004cd2:	20e4ae23          	sw	a4,540(s1)
    80004cd6:	1ff7f793          	andi	a5,a5,511
    80004cda:	97a6                	add	a5,a5,s1
    80004cdc:	f8f44703          	lbu	a4,-113(s0)
    80004ce0:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ce4:	001d0c1b          	addiw	s8,s10,1
    80004ce8:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004cec:	036b8b63          	beq	s7,s6,80004d22 <pipewrite+0x10c>
    80004cf0:	8bbe                	mv	s7,a5
    80004cf2:	bf9d                	j	80004c68 <pipewrite+0x52>
        release(&pi->lock);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	166080e7          	jalr	358(ra) # 80000e5c <release>
        return -1;
    80004cfe:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d00:	8562                	mv	a0,s8
    80004d02:	70e6                	ld	ra,120(sp)
    80004d04:	7446                	ld	s0,112(sp)
    80004d06:	74a6                	ld	s1,104(sp)
    80004d08:	7906                	ld	s2,96(sp)
    80004d0a:	69e6                	ld	s3,88(sp)
    80004d0c:	6a46                	ld	s4,80(sp)
    80004d0e:	6aa6                	ld	s5,72(sp)
    80004d10:	6b06                	ld	s6,64(sp)
    80004d12:	7be2                	ld	s7,56(sp)
    80004d14:	7c42                	ld	s8,48(sp)
    80004d16:	7ca2                	ld	s9,40(sp)
    80004d18:	7d02                	ld	s10,32(sp)
    80004d1a:	6de2                	ld	s11,24(sp)
    80004d1c:	6109                	addi	sp,sp,128
    80004d1e:	8082                	ret
  for(i = 0; i < n; i++){
    80004d20:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004d22:	21848513          	addi	a0,s1,536
    80004d26:	ffffe097          	auipc	ra,0xffffe
    80004d2a:	8ea080e7          	jalr	-1814(ra) # 80002610 <wakeup>
  release(&pi->lock);
    80004d2e:	8526                	mv	a0,s1
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	12c080e7          	jalr	300(ra) # 80000e5c <release>
  return i;
    80004d38:	b7e1                	j	80004d00 <pipewrite+0xea>

0000000080004d3a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d3a:	715d                	addi	sp,sp,-80
    80004d3c:	e486                	sd	ra,72(sp)
    80004d3e:	e0a2                	sd	s0,64(sp)
    80004d40:	fc26                	sd	s1,56(sp)
    80004d42:	f84a                	sd	s2,48(sp)
    80004d44:	f44e                	sd	s3,40(sp)
    80004d46:	f052                	sd	s4,32(sp)
    80004d48:	ec56                	sd	s5,24(sp)
    80004d4a:	e85a                	sd	s6,16(sp)
    80004d4c:	0880                	addi	s0,sp,80
    80004d4e:	84aa                	mv	s1,a0
    80004d50:	892e                	mv	s2,a1
    80004d52:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d54:	ffffd097          	auipc	ra,0xffffd
    80004d58:	f26080e7          	jalr	-218(ra) # 80001c7a <myproc>
    80004d5c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d5e:	8b26                	mv	s6,s1
    80004d60:	8526                	mv	a0,s1
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	046080e7          	jalr	70(ra) # 80000da8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d6a:	2184a703          	lw	a4,536(s1)
    80004d6e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d72:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d76:	02f71463          	bne	a4,a5,80004d9e <piperead+0x64>
    80004d7a:	2244a783          	lw	a5,548(s1)
    80004d7e:	c385                	beqz	a5,80004d9e <piperead+0x64>
    if(pr->killed){
    80004d80:	030a2783          	lw	a5,48(s4)
    80004d84:	ebc1                	bnez	a5,80004e14 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d86:	85da                	mv	a1,s6
    80004d88:	854e                	mv	a0,s3
    80004d8a:	ffffd097          	auipc	ra,0xffffd
    80004d8e:	700080e7          	jalr	1792(ra) # 8000248a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d92:	2184a703          	lw	a4,536(s1)
    80004d96:	21c4a783          	lw	a5,540(s1)
    80004d9a:	fef700e3          	beq	a4,a5,80004d7a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d9e:	09505263          	blez	s5,80004e22 <piperead+0xe8>
    80004da2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004da4:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004da6:	2184a783          	lw	a5,536(s1)
    80004daa:	21c4a703          	lw	a4,540(s1)
    80004dae:	02f70d63          	beq	a4,a5,80004de8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004db2:	0017871b          	addiw	a4,a5,1
    80004db6:	20e4ac23          	sw	a4,536(s1)
    80004dba:	1ff7f793          	andi	a5,a5,511
    80004dbe:	97a6                	add	a5,a5,s1
    80004dc0:	0187c783          	lbu	a5,24(a5)
    80004dc4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc8:	4685                	li	a3,1
    80004dca:	fbf40613          	addi	a2,s0,-65
    80004dce:	85ca                	mv	a1,s2
    80004dd0:	050a3503          	ld	a0,80(s4)
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	cc0080e7          	jalr	-832(ra) # 80001a94 <copyout>
    80004ddc:	01650663          	beq	a0,s6,80004de8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004de0:	2985                	addiw	s3,s3,1
    80004de2:	0905                	addi	s2,s2,1
    80004de4:	fd3a91e3          	bne	s5,s3,80004da6 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004de8:	21c48513          	addi	a0,s1,540
    80004dec:	ffffe097          	auipc	ra,0xffffe
    80004df0:	824080e7          	jalr	-2012(ra) # 80002610 <wakeup>
  release(&pi->lock);
    80004df4:	8526                	mv	a0,s1
    80004df6:	ffffc097          	auipc	ra,0xffffc
    80004dfa:	066080e7          	jalr	102(ra) # 80000e5c <release>
  return i;
}
    80004dfe:	854e                	mv	a0,s3
    80004e00:	60a6                	ld	ra,72(sp)
    80004e02:	6406                	ld	s0,64(sp)
    80004e04:	74e2                	ld	s1,56(sp)
    80004e06:	7942                	ld	s2,48(sp)
    80004e08:	79a2                	ld	s3,40(sp)
    80004e0a:	7a02                	ld	s4,32(sp)
    80004e0c:	6ae2                	ld	s5,24(sp)
    80004e0e:	6b42                	ld	s6,16(sp)
    80004e10:	6161                	addi	sp,sp,80
    80004e12:	8082                	ret
      release(&pi->lock);
    80004e14:	8526                	mv	a0,s1
    80004e16:	ffffc097          	auipc	ra,0xffffc
    80004e1a:	046080e7          	jalr	70(ra) # 80000e5c <release>
      return -1;
    80004e1e:	59fd                	li	s3,-1
    80004e20:	bff9                	j	80004dfe <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e22:	4981                	li	s3,0
    80004e24:	b7d1                	j	80004de8 <piperead+0xae>

0000000080004e26 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e26:	df010113          	addi	sp,sp,-528
    80004e2a:	20113423          	sd	ra,520(sp)
    80004e2e:	20813023          	sd	s0,512(sp)
    80004e32:	ffa6                	sd	s1,504(sp)
    80004e34:	fbca                	sd	s2,496(sp)
    80004e36:	f7ce                	sd	s3,488(sp)
    80004e38:	f3d2                	sd	s4,480(sp)
    80004e3a:	efd6                	sd	s5,472(sp)
    80004e3c:	ebda                	sd	s6,464(sp)
    80004e3e:	e7de                	sd	s7,456(sp)
    80004e40:	e3e2                	sd	s8,448(sp)
    80004e42:	ff66                	sd	s9,440(sp)
    80004e44:	fb6a                	sd	s10,432(sp)
    80004e46:	f76e                	sd	s11,424(sp)
    80004e48:	0c00                	addi	s0,sp,528
    80004e4a:	84aa                	mv	s1,a0
    80004e4c:	dea43c23          	sd	a0,-520(s0)
    80004e50:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e54:	ffffd097          	auipc	ra,0xffffd
    80004e58:	e26080e7          	jalr	-474(ra) # 80001c7a <myproc>
    80004e5c:	892a                	mv	s2,a0

  begin_op();
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	446080e7          	jalr	1094(ra) # 800042a4 <begin_op>

  if((ip = namei(path)) == 0){
    80004e66:	8526                	mv	a0,s1
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	230080e7          	jalr	560(ra) # 80004098 <namei>
    80004e70:	c92d                	beqz	a0,80004ee2 <exec+0xbc>
    80004e72:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e74:	fffff097          	auipc	ra,0xfffff
    80004e78:	a70080e7          	jalr	-1424(ra) # 800038e4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e7c:	04000713          	li	a4,64
    80004e80:	4681                	li	a3,0
    80004e82:	e4840613          	addi	a2,s0,-440
    80004e86:	4581                	li	a1,0
    80004e88:	8526                	mv	a0,s1
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	d0e080e7          	jalr	-754(ra) # 80003b98 <readi>
    80004e92:	04000793          	li	a5,64
    80004e96:	00f51a63          	bne	a0,a5,80004eaa <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e9a:	e4842703          	lw	a4,-440(s0)
    80004e9e:	464c47b7          	lui	a5,0x464c4
    80004ea2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ea6:	04f70463          	beq	a4,a5,80004eee <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eaa:	8526                	mv	a0,s1
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	c9a080e7          	jalr	-870(ra) # 80003b46 <iunlockput>
    end_op();
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	470080e7          	jalr	1136(ra) # 80004324 <end_op>
  }
  return -1;
    80004ebc:	557d                	li	a0,-1
}
    80004ebe:	20813083          	ld	ra,520(sp)
    80004ec2:	20013403          	ld	s0,512(sp)
    80004ec6:	74fe                	ld	s1,504(sp)
    80004ec8:	795e                	ld	s2,496(sp)
    80004eca:	79be                	ld	s3,488(sp)
    80004ecc:	7a1e                	ld	s4,480(sp)
    80004ece:	6afe                	ld	s5,472(sp)
    80004ed0:	6b5e                	ld	s6,464(sp)
    80004ed2:	6bbe                	ld	s7,456(sp)
    80004ed4:	6c1e                	ld	s8,448(sp)
    80004ed6:	7cfa                	ld	s9,440(sp)
    80004ed8:	7d5a                	ld	s10,432(sp)
    80004eda:	7dba                	ld	s11,424(sp)
    80004edc:	21010113          	addi	sp,sp,528
    80004ee0:	8082                	ret
    end_op();
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	442080e7          	jalr	1090(ra) # 80004324 <end_op>
    return -1;
    80004eea:	557d                	li	a0,-1
    80004eec:	bfc9                	j	80004ebe <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eee:	854a                	mv	a0,s2
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	e4e080e7          	jalr	-434(ra) # 80001d3e <proc_pagetable>
    80004ef8:	8baa                	mv	s7,a0
    80004efa:	d945                	beqz	a0,80004eaa <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004efc:	e6842983          	lw	s3,-408(s0)
    80004f00:	e8045783          	lhu	a5,-384(s0)
    80004f04:	c7ad                	beqz	a5,80004f6e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f06:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f08:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f0a:	6c85                	lui	s9,0x1
    80004f0c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f10:	def43823          	sd	a5,-528(s0)
    80004f14:	a42d                	j	8000513e <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f16:	00003517          	auipc	a0,0x3
    80004f1a:	7da50513          	addi	a0,a0,2010 # 800086f0 <syscalls+0x290>
    80004f1e:	ffffb097          	auipc	ra,0xffffb
    80004f22:	638080e7          	jalr	1592(ra) # 80000556 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f26:	8756                	mv	a4,s5
    80004f28:	012d86bb          	addw	a3,s11,s2
    80004f2c:	4581                	li	a1,0
    80004f2e:	8526                	mv	a0,s1
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	c68080e7          	jalr	-920(ra) # 80003b98 <readi>
    80004f38:	2501                	sext.w	a0,a0
    80004f3a:	1aaa9963          	bne	s5,a0,800050ec <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004f3e:	6785                	lui	a5,0x1
    80004f40:	0127893b          	addw	s2,a5,s2
    80004f44:	77fd                	lui	a5,0xfffff
    80004f46:	01478a3b          	addw	s4,a5,s4
    80004f4a:	1f897163          	bgeu	s2,s8,8000512c <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004f4e:	02091593          	slli	a1,s2,0x20
    80004f52:	9181                	srli	a1,a1,0x20
    80004f54:	95ea                	add	a1,a1,s10
    80004f56:	855e                	mv	a0,s7
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	2de080e7          	jalr	734(ra) # 80001236 <walkaddr>
    80004f60:	862a                	mv	a2,a0
    if(pa == 0)
    80004f62:	d955                	beqz	a0,80004f16 <exec+0xf0>
      n = PGSIZE;
    80004f64:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f66:	fd9a70e3          	bgeu	s4,s9,80004f26 <exec+0x100>
      n = sz - i;
    80004f6a:	8ad2                	mv	s5,s4
    80004f6c:	bf6d                	j	80004f26 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f6e:	4901                	li	s2,0
  iunlockput(ip);
    80004f70:	8526                	mv	a0,s1
    80004f72:	fffff097          	auipc	ra,0xfffff
    80004f76:	bd4080e7          	jalr	-1068(ra) # 80003b46 <iunlockput>
  end_op();
    80004f7a:	fffff097          	auipc	ra,0xfffff
    80004f7e:	3aa080e7          	jalr	938(ra) # 80004324 <end_op>
  p = myproc();
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	cf8080e7          	jalr	-776(ra) # 80001c7a <myproc>
    80004f8a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f8c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f90:	6785                	lui	a5,0x1
    80004f92:	17fd                	addi	a5,a5,-1
    80004f94:	993e                	add	s2,s2,a5
    80004f96:	757d                	lui	a0,0xfffff
    80004f98:	00a977b3          	and	a5,s2,a0
    80004f9c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fa0:	6609                	lui	a2,0x2
    80004fa2:	963e                	add	a2,a2,a5
    80004fa4:	85be                	mv	a1,a5
    80004fa6:	855e                	mv	a0,s7
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	672080e7          	jalr	1650(ra) # 8000161a <uvmalloc>
    80004fb0:	8b2a                	mv	s6,a0
  ip = 0;
    80004fb2:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fb4:	12050c63          	beqz	a0,800050ec <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fb8:	75f9                	lui	a1,0xffffe
    80004fba:	95aa                	add	a1,a1,a0
    80004fbc:	855e                	mv	a0,s7
    80004fbe:	ffffd097          	auipc	ra,0xffffd
    80004fc2:	868080e7          	jalr	-1944(ra) # 80001826 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fc6:	7c7d                	lui	s8,0xfffff
    80004fc8:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fca:	e0043783          	ld	a5,-512(s0)
    80004fce:	6388                	ld	a0,0(a5)
    80004fd0:	c535                	beqz	a0,8000503c <exec+0x216>
    80004fd2:	e8840993          	addi	s3,s0,-376
    80004fd6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fda:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	050080e7          	jalr	80(ra) # 8000102c <strlen>
    80004fe4:	2505                	addiw	a0,a0,1
    80004fe6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fea:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fee:	13896363          	bltu	s2,s8,80005114 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ff2:	e0043d83          	ld	s11,-512(s0)
    80004ff6:	000dba03          	ld	s4,0(s11)
    80004ffa:	8552                	mv	a0,s4
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	030080e7          	jalr	48(ra) # 8000102c <strlen>
    80005004:	0015069b          	addiw	a3,a0,1
    80005008:	8652                	mv	a2,s4
    8000500a:	85ca                	mv	a1,s2
    8000500c:	855e                	mv	a0,s7
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	a86080e7          	jalr	-1402(ra) # 80001a94 <copyout>
    80005016:	10054363          	bltz	a0,8000511c <exec+0x2f6>
    ustack[argc] = sp;
    8000501a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000501e:	0485                	addi	s1,s1,1
    80005020:	008d8793          	addi	a5,s11,8
    80005024:	e0f43023          	sd	a5,-512(s0)
    80005028:	008db503          	ld	a0,8(s11)
    8000502c:	c911                	beqz	a0,80005040 <exec+0x21a>
    if(argc >= MAXARG)
    8000502e:	09a1                	addi	s3,s3,8
    80005030:	fb3c96e3          	bne	s9,s3,80004fdc <exec+0x1b6>
  sz = sz1;
    80005034:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005038:	4481                	li	s1,0
    8000503a:	a84d                	j	800050ec <exec+0x2c6>
  sp = sz;
    8000503c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000503e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005040:	00349793          	slli	a5,s1,0x3
    80005044:	f9040713          	addi	a4,s0,-112
    80005048:	97ba                	add	a5,a5,a4
    8000504a:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000504e:	00148693          	addi	a3,s1,1
    80005052:	068e                	slli	a3,a3,0x3
    80005054:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005058:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000505c:	01897663          	bgeu	s2,s8,80005068 <exec+0x242>
  sz = sz1;
    80005060:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005064:	4481                	li	s1,0
    80005066:	a059                	j	800050ec <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005068:	e8840613          	addi	a2,s0,-376
    8000506c:	85ca                	mv	a1,s2
    8000506e:	855e                	mv	a0,s7
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	a24080e7          	jalr	-1500(ra) # 80001a94 <copyout>
    80005078:	0a054663          	bltz	a0,80005124 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000507c:	058ab783          	ld	a5,88(s5)
    80005080:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005084:	df843783          	ld	a5,-520(s0)
    80005088:	0007c703          	lbu	a4,0(a5)
    8000508c:	cf11                	beqz	a4,800050a8 <exec+0x282>
    8000508e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005090:	02f00693          	li	a3,47
    80005094:	a029                	j	8000509e <exec+0x278>
  for(last=s=path; *s; s++)
    80005096:	0785                	addi	a5,a5,1
    80005098:	fff7c703          	lbu	a4,-1(a5)
    8000509c:	c711                	beqz	a4,800050a8 <exec+0x282>
    if(*s == '/')
    8000509e:	fed71ce3          	bne	a4,a3,80005096 <exec+0x270>
      last = s+1;
    800050a2:	def43c23          	sd	a5,-520(s0)
    800050a6:	bfc5                	j	80005096 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800050a8:	4641                	li	a2,16
    800050aa:	df843583          	ld	a1,-520(s0)
    800050ae:	158a8513          	addi	a0,s5,344
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	f48080e7          	jalr	-184(ra) # 80000ffa <safestrcpy>
  oldpagetable = p->pagetable;
    800050ba:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050be:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050c2:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050c6:	058ab783          	ld	a5,88(s5)
    800050ca:	e6043703          	ld	a4,-416(s0)
    800050ce:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050d0:	058ab783          	ld	a5,88(s5)
    800050d4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050d8:	85ea                	mv	a1,s10
    800050da:	ffffd097          	auipc	ra,0xffffd
    800050de:	d00080e7          	jalr	-768(ra) # 80001dda <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050e2:	0004851b          	sext.w	a0,s1
    800050e6:	bbe1                	j	80004ebe <exec+0x98>
    800050e8:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050ec:	e0843583          	ld	a1,-504(s0)
    800050f0:	855e                	mv	a0,s7
    800050f2:	ffffd097          	auipc	ra,0xffffd
    800050f6:	ce8080e7          	jalr	-792(ra) # 80001dda <proc_freepagetable>
  if(ip){
    800050fa:	da0498e3          	bnez	s1,80004eaa <exec+0x84>
  return -1;
    800050fe:	557d                	li	a0,-1
    80005100:	bb7d                	j	80004ebe <exec+0x98>
    80005102:	e1243423          	sd	s2,-504(s0)
    80005106:	b7dd                	j	800050ec <exec+0x2c6>
    80005108:	e1243423          	sd	s2,-504(s0)
    8000510c:	b7c5                	j	800050ec <exec+0x2c6>
    8000510e:	e1243423          	sd	s2,-504(s0)
    80005112:	bfe9                	j	800050ec <exec+0x2c6>
  sz = sz1;
    80005114:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005118:	4481                	li	s1,0
    8000511a:	bfc9                	j	800050ec <exec+0x2c6>
  sz = sz1;
    8000511c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005120:	4481                	li	s1,0
    80005122:	b7e9                	j	800050ec <exec+0x2c6>
  sz = sz1;
    80005124:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005128:	4481                	li	s1,0
    8000512a:	b7c9                	j	800050ec <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000512c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005130:	2b05                	addiw	s6,s6,1
    80005132:	0389899b          	addiw	s3,s3,56
    80005136:	e8045783          	lhu	a5,-384(s0)
    8000513a:	e2fb5be3          	bge	s6,a5,80004f70 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000513e:	2981                	sext.w	s3,s3
    80005140:	03800713          	li	a4,56
    80005144:	86ce                	mv	a3,s3
    80005146:	e1040613          	addi	a2,s0,-496
    8000514a:	4581                	li	a1,0
    8000514c:	8526                	mv	a0,s1
    8000514e:	fffff097          	auipc	ra,0xfffff
    80005152:	a4a080e7          	jalr	-1462(ra) # 80003b98 <readi>
    80005156:	03800793          	li	a5,56
    8000515a:	f8f517e3          	bne	a0,a5,800050e8 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000515e:	e1042783          	lw	a5,-496(s0)
    80005162:	4705                	li	a4,1
    80005164:	fce796e3          	bne	a5,a4,80005130 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005168:	e3843603          	ld	a2,-456(s0)
    8000516c:	e3043783          	ld	a5,-464(s0)
    80005170:	f8f669e3          	bltu	a2,a5,80005102 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005174:	e2043783          	ld	a5,-480(s0)
    80005178:	963e                	add	a2,a2,a5
    8000517a:	f8f667e3          	bltu	a2,a5,80005108 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000517e:	85ca                	mv	a1,s2
    80005180:	855e                	mv	a0,s7
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	498080e7          	jalr	1176(ra) # 8000161a <uvmalloc>
    8000518a:	e0a43423          	sd	a0,-504(s0)
    8000518e:	d141                	beqz	a0,8000510e <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005190:	e2043d03          	ld	s10,-480(s0)
    80005194:	df043783          	ld	a5,-528(s0)
    80005198:	00fd77b3          	and	a5,s10,a5
    8000519c:	fba1                	bnez	a5,800050ec <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000519e:	e1842d83          	lw	s11,-488(s0)
    800051a2:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051a6:	f80c03e3          	beqz	s8,8000512c <exec+0x306>
    800051aa:	8a62                	mv	s4,s8
    800051ac:	4901                	li	s2,0
    800051ae:	b345                	j	80004f4e <exec+0x128>

00000000800051b0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051b0:	7179                	addi	sp,sp,-48
    800051b2:	f406                	sd	ra,40(sp)
    800051b4:	f022                	sd	s0,32(sp)
    800051b6:	ec26                	sd	s1,24(sp)
    800051b8:	e84a                	sd	s2,16(sp)
    800051ba:	1800                	addi	s0,sp,48
    800051bc:	892e                	mv	s2,a1
    800051be:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051c0:	fdc40593          	addi	a1,s0,-36
    800051c4:	ffffe097          	auipc	ra,0xffffe
    800051c8:	bae080e7          	jalr	-1106(ra) # 80002d72 <argint>
    800051cc:	04054063          	bltz	a0,8000520c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051d0:	fdc42703          	lw	a4,-36(s0)
    800051d4:	47bd                	li	a5,15
    800051d6:	02e7ed63          	bltu	a5,a4,80005210 <argfd+0x60>
    800051da:	ffffd097          	auipc	ra,0xffffd
    800051de:	aa0080e7          	jalr	-1376(ra) # 80001c7a <myproc>
    800051e2:	fdc42703          	lw	a4,-36(s0)
    800051e6:	01a70793          	addi	a5,a4,26
    800051ea:	078e                	slli	a5,a5,0x3
    800051ec:	953e                	add	a0,a0,a5
    800051ee:	611c                	ld	a5,0(a0)
    800051f0:	c395                	beqz	a5,80005214 <argfd+0x64>
    return -1;
  if(pfd)
    800051f2:	00090463          	beqz	s2,800051fa <argfd+0x4a>
    *pfd = fd;
    800051f6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051fa:	4501                	li	a0,0
  if(pf)
    800051fc:	c091                	beqz	s1,80005200 <argfd+0x50>
    *pf = f;
    800051fe:	e09c                	sd	a5,0(s1)
}
    80005200:	70a2                	ld	ra,40(sp)
    80005202:	7402                	ld	s0,32(sp)
    80005204:	64e2                	ld	s1,24(sp)
    80005206:	6942                	ld	s2,16(sp)
    80005208:	6145                	addi	sp,sp,48
    8000520a:	8082                	ret
    return -1;
    8000520c:	557d                	li	a0,-1
    8000520e:	bfcd                	j	80005200 <argfd+0x50>
    return -1;
    80005210:	557d                	li	a0,-1
    80005212:	b7fd                	j	80005200 <argfd+0x50>
    80005214:	557d                	li	a0,-1
    80005216:	b7ed                	j	80005200 <argfd+0x50>

0000000080005218 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005218:	1101                	addi	sp,sp,-32
    8000521a:	ec06                	sd	ra,24(sp)
    8000521c:	e822                	sd	s0,16(sp)
    8000521e:	e426                	sd	s1,8(sp)
    80005220:	1000                	addi	s0,sp,32
    80005222:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005224:	ffffd097          	auipc	ra,0xffffd
    80005228:	a56080e7          	jalr	-1450(ra) # 80001c7a <myproc>
    8000522c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000522e:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffb90d0>
    80005232:	4501                	li	a0,0
    80005234:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005236:	6398                	ld	a4,0(a5)
    80005238:	cb19                	beqz	a4,8000524e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000523a:	2505                	addiw	a0,a0,1
    8000523c:	07a1                	addi	a5,a5,8
    8000523e:	fed51ce3          	bne	a0,a3,80005236 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005242:	557d                	li	a0,-1
}
    80005244:	60e2                	ld	ra,24(sp)
    80005246:	6442                	ld	s0,16(sp)
    80005248:	64a2                	ld	s1,8(sp)
    8000524a:	6105                	addi	sp,sp,32
    8000524c:	8082                	ret
      p->ofile[fd] = f;
    8000524e:	01a50793          	addi	a5,a0,26
    80005252:	078e                	slli	a5,a5,0x3
    80005254:	963e                	add	a2,a2,a5
    80005256:	e204                	sd	s1,0(a2)
      return fd;
    80005258:	b7f5                	j	80005244 <fdalloc+0x2c>

000000008000525a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000525a:	715d                	addi	sp,sp,-80
    8000525c:	e486                	sd	ra,72(sp)
    8000525e:	e0a2                	sd	s0,64(sp)
    80005260:	fc26                	sd	s1,56(sp)
    80005262:	f84a                	sd	s2,48(sp)
    80005264:	f44e                	sd	s3,40(sp)
    80005266:	f052                	sd	s4,32(sp)
    80005268:	ec56                	sd	s5,24(sp)
    8000526a:	0880                	addi	s0,sp,80
    8000526c:	89ae                	mv	s3,a1
    8000526e:	8ab2                	mv	s5,a2
    80005270:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005272:	fb040593          	addi	a1,s0,-80
    80005276:	fffff097          	auipc	ra,0xfffff
    8000527a:	e40080e7          	jalr	-448(ra) # 800040b6 <nameiparent>
    8000527e:	892a                	mv	s2,a0
    80005280:	12050f63          	beqz	a0,800053be <create+0x164>
    return 0;

  ilock(dp);
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	660080e7          	jalr	1632(ra) # 800038e4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000528c:	4601                	li	a2,0
    8000528e:	fb040593          	addi	a1,s0,-80
    80005292:	854a                	mv	a0,s2
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	b32080e7          	jalr	-1230(ra) # 80003dc6 <dirlookup>
    8000529c:	84aa                	mv	s1,a0
    8000529e:	c921                	beqz	a0,800052ee <create+0x94>
    iunlockput(dp);
    800052a0:	854a                	mv	a0,s2
    800052a2:	fffff097          	auipc	ra,0xfffff
    800052a6:	8a4080e7          	jalr	-1884(ra) # 80003b46 <iunlockput>
    ilock(ip);
    800052aa:	8526                	mv	a0,s1
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	638080e7          	jalr	1592(ra) # 800038e4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052b4:	2981                	sext.w	s3,s3
    800052b6:	4789                	li	a5,2
    800052b8:	02f99463          	bne	s3,a5,800052e0 <create+0x86>
    800052bc:	0444d783          	lhu	a5,68(s1)
    800052c0:	37f9                	addiw	a5,a5,-2
    800052c2:	17c2                	slli	a5,a5,0x30
    800052c4:	93c1                	srli	a5,a5,0x30
    800052c6:	4705                	li	a4,1
    800052c8:	00f76c63          	bltu	a4,a5,800052e0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052cc:	8526                	mv	a0,s1
    800052ce:	60a6                	ld	ra,72(sp)
    800052d0:	6406                	ld	s0,64(sp)
    800052d2:	74e2                	ld	s1,56(sp)
    800052d4:	7942                	ld	s2,48(sp)
    800052d6:	79a2                	ld	s3,40(sp)
    800052d8:	7a02                	ld	s4,32(sp)
    800052da:	6ae2                	ld	s5,24(sp)
    800052dc:	6161                	addi	sp,sp,80
    800052de:	8082                	ret
    iunlockput(ip);
    800052e0:	8526                	mv	a0,s1
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	864080e7          	jalr	-1948(ra) # 80003b46 <iunlockput>
    return 0;
    800052ea:	4481                	li	s1,0
    800052ec:	b7c5                	j	800052cc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ee:	85ce                	mv	a1,s3
    800052f0:	00092503          	lw	a0,0(s2)
    800052f4:	ffffe097          	auipc	ra,0xffffe
    800052f8:	458080e7          	jalr	1112(ra) # 8000374c <ialloc>
    800052fc:	84aa                	mv	s1,a0
    800052fe:	c529                	beqz	a0,80005348 <create+0xee>
  ilock(ip);
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	5e4080e7          	jalr	1508(ra) # 800038e4 <ilock>
  ip->major = major;
    80005308:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000530c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005310:	4785                	li	a5,1
    80005312:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005316:	8526                	mv	a0,s1
    80005318:	ffffe097          	auipc	ra,0xffffe
    8000531c:	502080e7          	jalr	1282(ra) # 8000381a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005320:	2981                	sext.w	s3,s3
    80005322:	4785                	li	a5,1
    80005324:	02f98a63          	beq	s3,a5,80005358 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005328:	40d0                	lw	a2,4(s1)
    8000532a:	fb040593          	addi	a1,s0,-80
    8000532e:	854a                	mv	a0,s2
    80005330:	fffff097          	auipc	ra,0xfffff
    80005334:	ca6080e7          	jalr	-858(ra) # 80003fd6 <dirlink>
    80005338:	06054b63          	bltz	a0,800053ae <create+0x154>
  iunlockput(dp);
    8000533c:	854a                	mv	a0,s2
    8000533e:	fffff097          	auipc	ra,0xfffff
    80005342:	808080e7          	jalr	-2040(ra) # 80003b46 <iunlockput>
  return ip;
    80005346:	b759                	j	800052cc <create+0x72>
    panic("create: ialloc");
    80005348:	00003517          	auipc	a0,0x3
    8000534c:	3c850513          	addi	a0,a0,968 # 80008710 <syscalls+0x2b0>
    80005350:	ffffb097          	auipc	ra,0xffffb
    80005354:	206080e7          	jalr	518(ra) # 80000556 <panic>
    dp->nlink++;  // for ".."
    80005358:	04a95783          	lhu	a5,74(s2)
    8000535c:	2785                	addiw	a5,a5,1
    8000535e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005362:	854a                	mv	a0,s2
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	4b6080e7          	jalr	1206(ra) # 8000381a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000536c:	40d0                	lw	a2,4(s1)
    8000536e:	00003597          	auipc	a1,0x3
    80005372:	3b258593          	addi	a1,a1,946 # 80008720 <syscalls+0x2c0>
    80005376:	8526                	mv	a0,s1
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	c5e080e7          	jalr	-930(ra) # 80003fd6 <dirlink>
    80005380:	00054f63          	bltz	a0,8000539e <create+0x144>
    80005384:	00492603          	lw	a2,4(s2)
    80005388:	00003597          	auipc	a1,0x3
    8000538c:	3a058593          	addi	a1,a1,928 # 80008728 <syscalls+0x2c8>
    80005390:	8526                	mv	a0,s1
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	c44080e7          	jalr	-956(ra) # 80003fd6 <dirlink>
    8000539a:	f80557e3          	bgez	a0,80005328 <create+0xce>
      panic("create dots");
    8000539e:	00003517          	auipc	a0,0x3
    800053a2:	39250513          	addi	a0,a0,914 # 80008730 <syscalls+0x2d0>
    800053a6:	ffffb097          	auipc	ra,0xffffb
    800053aa:	1b0080e7          	jalr	432(ra) # 80000556 <panic>
    panic("create: dirlink");
    800053ae:	00003517          	auipc	a0,0x3
    800053b2:	39250513          	addi	a0,a0,914 # 80008740 <syscalls+0x2e0>
    800053b6:	ffffb097          	auipc	ra,0xffffb
    800053ba:	1a0080e7          	jalr	416(ra) # 80000556 <panic>
    return 0;
    800053be:	84aa                	mv	s1,a0
    800053c0:	b731                	j	800052cc <create+0x72>

00000000800053c2 <sys_dup>:
{
    800053c2:	7179                	addi	sp,sp,-48
    800053c4:	f406                	sd	ra,40(sp)
    800053c6:	f022                	sd	s0,32(sp)
    800053c8:	ec26                	sd	s1,24(sp)
    800053ca:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053cc:	fd840613          	addi	a2,s0,-40
    800053d0:	4581                	li	a1,0
    800053d2:	4501                	li	a0,0
    800053d4:	00000097          	auipc	ra,0x0
    800053d8:	ddc080e7          	jalr	-548(ra) # 800051b0 <argfd>
    return -1;
    800053dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053de:	02054363          	bltz	a0,80005404 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053e2:	fd843503          	ld	a0,-40(s0)
    800053e6:	00000097          	auipc	ra,0x0
    800053ea:	e32080e7          	jalr	-462(ra) # 80005218 <fdalloc>
    800053ee:	84aa                	mv	s1,a0
    return -1;
    800053f0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053f2:	00054963          	bltz	a0,80005404 <sys_dup+0x42>
  filedup(f);
    800053f6:	fd843503          	ld	a0,-40(s0)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	32a080e7          	jalr	810(ra) # 80004724 <filedup>
  return fd;
    80005402:	87a6                	mv	a5,s1
}
    80005404:	853e                	mv	a0,a5
    80005406:	70a2                	ld	ra,40(sp)
    80005408:	7402                	ld	s0,32(sp)
    8000540a:	64e2                	ld	s1,24(sp)
    8000540c:	6145                	addi	sp,sp,48
    8000540e:	8082                	ret

0000000080005410 <sys_read>:
{
    80005410:	7179                	addi	sp,sp,-48
    80005412:	f406                	sd	ra,40(sp)
    80005414:	f022                	sd	s0,32(sp)
    80005416:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005418:	fe840613          	addi	a2,s0,-24
    8000541c:	4581                	li	a1,0
    8000541e:	4501                	li	a0,0
    80005420:	00000097          	auipc	ra,0x0
    80005424:	d90080e7          	jalr	-624(ra) # 800051b0 <argfd>
    return -1;
    80005428:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000542a:	04054163          	bltz	a0,8000546c <sys_read+0x5c>
    8000542e:	fe440593          	addi	a1,s0,-28
    80005432:	4509                	li	a0,2
    80005434:	ffffe097          	auipc	ra,0xffffe
    80005438:	93e080e7          	jalr	-1730(ra) # 80002d72 <argint>
    return -1;
    8000543c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000543e:	02054763          	bltz	a0,8000546c <sys_read+0x5c>
    80005442:	fd840593          	addi	a1,s0,-40
    80005446:	4505                	li	a0,1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	94c080e7          	jalr	-1716(ra) # 80002d94 <argaddr>
    return -1;
    80005450:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005452:	00054d63          	bltz	a0,8000546c <sys_read+0x5c>
  return fileread(f, p, n);
    80005456:	fe442603          	lw	a2,-28(s0)
    8000545a:	fd843583          	ld	a1,-40(s0)
    8000545e:	fe843503          	ld	a0,-24(s0)
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	44e080e7          	jalr	1102(ra) # 800048b0 <fileread>
    8000546a:	87aa                	mv	a5,a0
}
    8000546c:	853e                	mv	a0,a5
    8000546e:	70a2                	ld	ra,40(sp)
    80005470:	7402                	ld	s0,32(sp)
    80005472:	6145                	addi	sp,sp,48
    80005474:	8082                	ret

0000000080005476 <sys_write>:
{
    80005476:	7179                	addi	sp,sp,-48
    80005478:	f406                	sd	ra,40(sp)
    8000547a:	f022                	sd	s0,32(sp)
    8000547c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547e:	fe840613          	addi	a2,s0,-24
    80005482:	4581                	li	a1,0
    80005484:	4501                	li	a0,0
    80005486:	00000097          	auipc	ra,0x0
    8000548a:	d2a080e7          	jalr	-726(ra) # 800051b0 <argfd>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005490:	04054163          	bltz	a0,800054d2 <sys_write+0x5c>
    80005494:	fe440593          	addi	a1,s0,-28
    80005498:	4509                	li	a0,2
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	8d8080e7          	jalr	-1832(ra) # 80002d72 <argint>
    return -1;
    800054a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a4:	02054763          	bltz	a0,800054d2 <sys_write+0x5c>
    800054a8:	fd840593          	addi	a1,s0,-40
    800054ac:	4505                	li	a0,1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	8e6080e7          	jalr	-1818(ra) # 80002d94 <argaddr>
    return -1;
    800054b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b8:	00054d63          	bltz	a0,800054d2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800054bc:	fe442603          	lw	a2,-28(s0)
    800054c0:	fd843583          	ld	a1,-40(s0)
    800054c4:	fe843503          	ld	a0,-24(s0)
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	4aa080e7          	jalr	1194(ra) # 80004972 <filewrite>
    800054d0:	87aa                	mv	a5,a0
}
    800054d2:	853e                	mv	a0,a5
    800054d4:	70a2                	ld	ra,40(sp)
    800054d6:	7402                	ld	s0,32(sp)
    800054d8:	6145                	addi	sp,sp,48
    800054da:	8082                	ret

00000000800054dc <sys_close>:
{
    800054dc:	1101                	addi	sp,sp,-32
    800054de:	ec06                	sd	ra,24(sp)
    800054e0:	e822                	sd	s0,16(sp)
    800054e2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054e4:	fe040613          	addi	a2,s0,-32
    800054e8:	fec40593          	addi	a1,s0,-20
    800054ec:	4501                	li	a0,0
    800054ee:	00000097          	auipc	ra,0x0
    800054f2:	cc2080e7          	jalr	-830(ra) # 800051b0 <argfd>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054f8:	02054463          	bltz	a0,80005520 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054fc:	ffffc097          	auipc	ra,0xffffc
    80005500:	77e080e7          	jalr	1918(ra) # 80001c7a <myproc>
    80005504:	fec42783          	lw	a5,-20(s0)
    80005508:	07e9                	addi	a5,a5,26
    8000550a:	078e                	slli	a5,a5,0x3
    8000550c:	97aa                	add	a5,a5,a0
    8000550e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005512:	fe043503          	ld	a0,-32(s0)
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	260080e7          	jalr	608(ra) # 80004776 <fileclose>
  return 0;
    8000551e:	4781                	li	a5,0
}
    80005520:	853e                	mv	a0,a5
    80005522:	60e2                	ld	ra,24(sp)
    80005524:	6442                	ld	s0,16(sp)
    80005526:	6105                	addi	sp,sp,32
    80005528:	8082                	ret

000000008000552a <sys_fstat>:
{
    8000552a:	1101                	addi	sp,sp,-32
    8000552c:	ec06                	sd	ra,24(sp)
    8000552e:	e822                	sd	s0,16(sp)
    80005530:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005532:	fe840613          	addi	a2,s0,-24
    80005536:	4581                	li	a1,0
    80005538:	4501                	li	a0,0
    8000553a:	00000097          	auipc	ra,0x0
    8000553e:	c76080e7          	jalr	-906(ra) # 800051b0 <argfd>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005544:	02054563          	bltz	a0,8000556e <sys_fstat+0x44>
    80005548:	fe040593          	addi	a1,s0,-32
    8000554c:	4505                	li	a0,1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	846080e7          	jalr	-1978(ra) # 80002d94 <argaddr>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005558:	00054b63          	bltz	a0,8000556e <sys_fstat+0x44>
  return filestat(f, st);
    8000555c:	fe043583          	ld	a1,-32(s0)
    80005560:	fe843503          	ld	a0,-24(s0)
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	2da080e7          	jalr	730(ra) # 8000483e <filestat>
    8000556c:	87aa                	mv	a5,a0
}
    8000556e:	853e                	mv	a0,a5
    80005570:	60e2                	ld	ra,24(sp)
    80005572:	6442                	ld	s0,16(sp)
    80005574:	6105                	addi	sp,sp,32
    80005576:	8082                	ret

0000000080005578 <sys_link>:
{
    80005578:	7169                	addi	sp,sp,-304
    8000557a:	f606                	sd	ra,296(sp)
    8000557c:	f222                	sd	s0,288(sp)
    8000557e:	ee26                	sd	s1,280(sp)
    80005580:	ea4a                	sd	s2,272(sp)
    80005582:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005584:	08000613          	li	a2,128
    80005588:	ed040593          	addi	a1,s0,-304
    8000558c:	4501                	li	a0,0
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	828080e7          	jalr	-2008(ra) # 80002db6 <argstr>
    return -1;
    80005596:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005598:	10054e63          	bltz	a0,800056b4 <sys_link+0x13c>
    8000559c:	08000613          	li	a2,128
    800055a0:	f5040593          	addi	a1,s0,-176
    800055a4:	4505                	li	a0,1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	810080e7          	jalr	-2032(ra) # 80002db6 <argstr>
    return -1;
    800055ae:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b0:	10054263          	bltz	a0,800056b4 <sys_link+0x13c>
  begin_op();
    800055b4:	fffff097          	auipc	ra,0xfffff
    800055b8:	cf0080e7          	jalr	-784(ra) # 800042a4 <begin_op>
  if((ip = namei(old)) == 0){
    800055bc:	ed040513          	addi	a0,s0,-304
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	ad8080e7          	jalr	-1320(ra) # 80004098 <namei>
    800055c8:	84aa                	mv	s1,a0
    800055ca:	c551                	beqz	a0,80005656 <sys_link+0xde>
  ilock(ip);
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	318080e7          	jalr	792(ra) # 800038e4 <ilock>
  if(ip->type == T_DIR){
    800055d4:	04449703          	lh	a4,68(s1)
    800055d8:	4785                	li	a5,1
    800055da:	08f70463          	beq	a4,a5,80005662 <sys_link+0xea>
  ip->nlink++;
    800055de:	04a4d783          	lhu	a5,74(s1)
    800055e2:	2785                	addiw	a5,a5,1
    800055e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	230080e7          	jalr	560(ra) # 8000381a <iupdate>
  iunlock(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	3b2080e7          	jalr	946(ra) # 800039a6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055fc:	fd040593          	addi	a1,s0,-48
    80005600:	f5040513          	addi	a0,s0,-176
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	ab2080e7          	jalr	-1358(ra) # 800040b6 <nameiparent>
    8000560c:	892a                	mv	s2,a0
    8000560e:	c935                	beqz	a0,80005682 <sys_link+0x10a>
  ilock(dp);
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	2d4080e7          	jalr	724(ra) # 800038e4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005618:	00092703          	lw	a4,0(s2)
    8000561c:	409c                	lw	a5,0(s1)
    8000561e:	04f71d63          	bne	a4,a5,80005678 <sys_link+0x100>
    80005622:	40d0                	lw	a2,4(s1)
    80005624:	fd040593          	addi	a1,s0,-48
    80005628:	854a                	mv	a0,s2
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	9ac080e7          	jalr	-1620(ra) # 80003fd6 <dirlink>
    80005632:	04054363          	bltz	a0,80005678 <sys_link+0x100>
  iunlockput(dp);
    80005636:	854a                	mv	a0,s2
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	50e080e7          	jalr	1294(ra) # 80003b46 <iunlockput>
  iput(ip);
    80005640:	8526                	mv	a0,s1
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	45c080e7          	jalr	1116(ra) # 80003a9e <iput>
  end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	cda080e7          	jalr	-806(ra) # 80004324 <end_op>
  return 0;
    80005652:	4781                	li	a5,0
    80005654:	a085                	j	800056b4 <sys_link+0x13c>
    end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	cce080e7          	jalr	-818(ra) # 80004324 <end_op>
    return -1;
    8000565e:	57fd                	li	a5,-1
    80005660:	a891                	j	800056b4 <sys_link+0x13c>
    iunlockput(ip);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	4e2080e7          	jalr	1250(ra) # 80003b46 <iunlockput>
    end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	cb8080e7          	jalr	-840(ra) # 80004324 <end_op>
    return -1;
    80005674:	57fd                	li	a5,-1
    80005676:	a83d                	j	800056b4 <sys_link+0x13c>
    iunlockput(dp);
    80005678:	854a                	mv	a0,s2
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	4cc080e7          	jalr	1228(ra) # 80003b46 <iunlockput>
  ilock(ip);
    80005682:	8526                	mv	a0,s1
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	260080e7          	jalr	608(ra) # 800038e4 <ilock>
  ip->nlink--;
    8000568c:	04a4d783          	lhu	a5,74(s1)
    80005690:	37fd                	addiw	a5,a5,-1
    80005692:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	182080e7          	jalr	386(ra) # 8000381a <iupdate>
  iunlockput(ip);
    800056a0:	8526                	mv	a0,s1
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	4a4080e7          	jalr	1188(ra) # 80003b46 <iunlockput>
  end_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	c7a080e7          	jalr	-902(ra) # 80004324 <end_op>
  return -1;
    800056b2:	57fd                	li	a5,-1
}
    800056b4:	853e                	mv	a0,a5
    800056b6:	70b2                	ld	ra,296(sp)
    800056b8:	7412                	ld	s0,288(sp)
    800056ba:	64f2                	ld	s1,280(sp)
    800056bc:	6952                	ld	s2,272(sp)
    800056be:	6155                	addi	sp,sp,304
    800056c0:	8082                	ret

00000000800056c2 <sys_unlink>:
{
    800056c2:	7151                	addi	sp,sp,-240
    800056c4:	f586                	sd	ra,232(sp)
    800056c6:	f1a2                	sd	s0,224(sp)
    800056c8:	eda6                	sd	s1,216(sp)
    800056ca:	e9ca                	sd	s2,208(sp)
    800056cc:	e5ce                	sd	s3,200(sp)
    800056ce:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056d0:	08000613          	li	a2,128
    800056d4:	f3040593          	addi	a1,s0,-208
    800056d8:	4501                	li	a0,0
    800056da:	ffffd097          	auipc	ra,0xffffd
    800056de:	6dc080e7          	jalr	1756(ra) # 80002db6 <argstr>
    800056e2:	18054163          	bltz	a0,80005864 <sys_unlink+0x1a2>
  begin_op();
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	bbe080e7          	jalr	-1090(ra) # 800042a4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ee:	fb040593          	addi	a1,s0,-80
    800056f2:	f3040513          	addi	a0,s0,-208
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	9c0080e7          	jalr	-1600(ra) # 800040b6 <nameiparent>
    800056fe:	84aa                	mv	s1,a0
    80005700:	c979                	beqz	a0,800057d6 <sys_unlink+0x114>
  ilock(dp);
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	1e2080e7          	jalr	482(ra) # 800038e4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000570a:	00003597          	auipc	a1,0x3
    8000570e:	01658593          	addi	a1,a1,22 # 80008720 <syscalls+0x2c0>
    80005712:	fb040513          	addi	a0,s0,-80
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	696080e7          	jalr	1686(ra) # 80003dac <namecmp>
    8000571e:	14050a63          	beqz	a0,80005872 <sys_unlink+0x1b0>
    80005722:	00003597          	auipc	a1,0x3
    80005726:	00658593          	addi	a1,a1,6 # 80008728 <syscalls+0x2c8>
    8000572a:	fb040513          	addi	a0,s0,-80
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	67e080e7          	jalr	1662(ra) # 80003dac <namecmp>
    80005736:	12050e63          	beqz	a0,80005872 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000573a:	f2c40613          	addi	a2,s0,-212
    8000573e:	fb040593          	addi	a1,s0,-80
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	682080e7          	jalr	1666(ra) # 80003dc6 <dirlookup>
    8000574c:	892a                	mv	s2,a0
    8000574e:	12050263          	beqz	a0,80005872 <sys_unlink+0x1b0>
  ilock(ip);
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	192080e7          	jalr	402(ra) # 800038e4 <ilock>
  if(ip->nlink < 1)
    8000575a:	04a91783          	lh	a5,74(s2)
    8000575e:	08f05263          	blez	a5,800057e2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005762:	04491703          	lh	a4,68(s2)
    80005766:	4785                	li	a5,1
    80005768:	08f70563          	beq	a4,a5,800057f2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000576c:	4641                	li	a2,16
    8000576e:	4581                	li	a1,0
    80005770:	fc040513          	addi	a0,s0,-64
    80005774:	ffffb097          	auipc	ra,0xffffb
    80005778:	730080e7          	jalr	1840(ra) # 80000ea4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000577c:	4741                	li	a4,16
    8000577e:	f2c42683          	lw	a3,-212(s0)
    80005782:	fc040613          	addi	a2,s0,-64
    80005786:	4581                	li	a1,0
    80005788:	8526                	mv	a0,s1
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	506080e7          	jalr	1286(ra) # 80003c90 <writei>
    80005792:	47c1                	li	a5,16
    80005794:	0af51563          	bne	a0,a5,8000583e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005798:	04491703          	lh	a4,68(s2)
    8000579c:	4785                	li	a5,1
    8000579e:	0af70863          	beq	a4,a5,8000584e <sys_unlink+0x18c>
  iunlockput(dp);
    800057a2:	8526                	mv	a0,s1
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	3a2080e7          	jalr	930(ra) # 80003b46 <iunlockput>
  ip->nlink--;
    800057ac:	04a95783          	lhu	a5,74(s2)
    800057b0:	37fd                	addiw	a5,a5,-1
    800057b2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057b6:	854a                	mv	a0,s2
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	062080e7          	jalr	98(ra) # 8000381a <iupdate>
  iunlockput(ip);
    800057c0:	854a                	mv	a0,s2
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	384080e7          	jalr	900(ra) # 80003b46 <iunlockput>
  end_op();
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	b5a080e7          	jalr	-1190(ra) # 80004324 <end_op>
  return 0;
    800057d2:	4501                	li	a0,0
    800057d4:	a84d                	j	80005886 <sys_unlink+0x1c4>
    end_op();
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	b4e080e7          	jalr	-1202(ra) # 80004324 <end_op>
    return -1;
    800057de:	557d                	li	a0,-1
    800057e0:	a05d                	j	80005886 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057e2:	00003517          	auipc	a0,0x3
    800057e6:	f6e50513          	addi	a0,a0,-146 # 80008750 <syscalls+0x2f0>
    800057ea:	ffffb097          	auipc	ra,0xffffb
    800057ee:	d6c080e7          	jalr	-660(ra) # 80000556 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057f2:	04c92703          	lw	a4,76(s2)
    800057f6:	02000793          	li	a5,32
    800057fa:	f6e7f9e3          	bgeu	a5,a4,8000576c <sys_unlink+0xaa>
    800057fe:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005802:	4741                	li	a4,16
    80005804:	86ce                	mv	a3,s3
    80005806:	f1840613          	addi	a2,s0,-232
    8000580a:	4581                	li	a1,0
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	38a080e7          	jalr	906(ra) # 80003b98 <readi>
    80005816:	47c1                	li	a5,16
    80005818:	00f51b63          	bne	a0,a5,8000582e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000581c:	f1845783          	lhu	a5,-232(s0)
    80005820:	e7a1                	bnez	a5,80005868 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005822:	29c1                	addiw	s3,s3,16
    80005824:	04c92783          	lw	a5,76(s2)
    80005828:	fcf9ede3          	bltu	s3,a5,80005802 <sys_unlink+0x140>
    8000582c:	b781                	j	8000576c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000582e:	00003517          	auipc	a0,0x3
    80005832:	f3a50513          	addi	a0,a0,-198 # 80008768 <syscalls+0x308>
    80005836:	ffffb097          	auipc	ra,0xffffb
    8000583a:	d20080e7          	jalr	-736(ra) # 80000556 <panic>
    panic("unlink: writei");
    8000583e:	00003517          	auipc	a0,0x3
    80005842:	f4250513          	addi	a0,a0,-190 # 80008780 <syscalls+0x320>
    80005846:	ffffb097          	auipc	ra,0xffffb
    8000584a:	d10080e7          	jalr	-752(ra) # 80000556 <panic>
    dp->nlink--;
    8000584e:	04a4d783          	lhu	a5,74(s1)
    80005852:	37fd                	addiw	a5,a5,-1
    80005854:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	fc0080e7          	jalr	-64(ra) # 8000381a <iupdate>
    80005862:	b781                	j	800057a2 <sys_unlink+0xe0>
    return -1;
    80005864:	557d                	li	a0,-1
    80005866:	a005                	j	80005886 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	2dc080e7          	jalr	732(ra) # 80003b46 <iunlockput>
  iunlockput(dp);
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	2d2080e7          	jalr	722(ra) # 80003b46 <iunlockput>
  end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	aa8080e7          	jalr	-1368(ra) # 80004324 <end_op>
  return -1;
    80005884:	557d                	li	a0,-1
}
    80005886:	70ae                	ld	ra,232(sp)
    80005888:	740e                	ld	s0,224(sp)
    8000588a:	64ee                	ld	s1,216(sp)
    8000588c:	694e                	ld	s2,208(sp)
    8000588e:	69ae                	ld	s3,200(sp)
    80005890:	616d                	addi	sp,sp,240
    80005892:	8082                	ret

0000000080005894 <sys_open>:

uint64
sys_open(void)
{
    80005894:	7131                	addi	sp,sp,-192
    80005896:	fd06                	sd	ra,184(sp)
    80005898:	f922                	sd	s0,176(sp)
    8000589a:	f526                	sd	s1,168(sp)
    8000589c:	f14a                	sd	s2,160(sp)
    8000589e:	ed4e                	sd	s3,152(sp)
    800058a0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058a2:	08000613          	li	a2,128
    800058a6:	f5040593          	addi	a1,s0,-176
    800058aa:	4501                	li	a0,0
    800058ac:	ffffd097          	auipc	ra,0xffffd
    800058b0:	50a080e7          	jalr	1290(ra) # 80002db6 <argstr>
    return -1;
    800058b4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058b6:	0c054163          	bltz	a0,80005978 <sys_open+0xe4>
    800058ba:	f4c40593          	addi	a1,s0,-180
    800058be:	4505                	li	a0,1
    800058c0:	ffffd097          	auipc	ra,0xffffd
    800058c4:	4b2080e7          	jalr	1202(ra) # 80002d72 <argint>
    800058c8:	0a054863          	bltz	a0,80005978 <sys_open+0xe4>

  begin_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	9d8080e7          	jalr	-1576(ra) # 800042a4 <begin_op>

  if(omode & O_CREATE){
    800058d4:	f4c42783          	lw	a5,-180(s0)
    800058d8:	2007f793          	andi	a5,a5,512
    800058dc:	cbdd                	beqz	a5,80005992 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058de:	4681                	li	a3,0
    800058e0:	4601                	li	a2,0
    800058e2:	4589                	li	a1,2
    800058e4:	f5040513          	addi	a0,s0,-176
    800058e8:	00000097          	auipc	ra,0x0
    800058ec:	972080e7          	jalr	-1678(ra) # 8000525a <create>
    800058f0:	892a                	mv	s2,a0
    if(ip == 0){
    800058f2:	c959                	beqz	a0,80005988 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058f4:	04491703          	lh	a4,68(s2)
    800058f8:	478d                	li	a5,3
    800058fa:	00f71763          	bne	a4,a5,80005908 <sys_open+0x74>
    800058fe:	04695703          	lhu	a4,70(s2)
    80005902:	47a5                	li	a5,9
    80005904:	0ce7ec63          	bltu	a5,a4,800059dc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	db2080e7          	jalr	-590(ra) # 800046ba <filealloc>
    80005910:	89aa                	mv	s3,a0
    80005912:	10050263          	beqz	a0,80005a16 <sys_open+0x182>
    80005916:	00000097          	auipc	ra,0x0
    8000591a:	902080e7          	jalr	-1790(ra) # 80005218 <fdalloc>
    8000591e:	84aa                	mv	s1,a0
    80005920:	0e054663          	bltz	a0,80005a0c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005924:	04491703          	lh	a4,68(s2)
    80005928:	478d                	li	a5,3
    8000592a:	0cf70463          	beq	a4,a5,800059f2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000592e:	4789                	li	a5,2
    80005930:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005934:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005938:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000593c:	f4c42783          	lw	a5,-180(s0)
    80005940:	0017c713          	xori	a4,a5,1
    80005944:	8b05                	andi	a4,a4,1
    80005946:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000594a:	0037f713          	andi	a4,a5,3
    8000594e:	00e03733          	snez	a4,a4
    80005952:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005956:	4007f793          	andi	a5,a5,1024
    8000595a:	c791                	beqz	a5,80005966 <sys_open+0xd2>
    8000595c:	04491703          	lh	a4,68(s2)
    80005960:	4789                	li	a5,2
    80005962:	08f70f63          	beq	a4,a5,80005a00 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005966:	854a                	mv	a0,s2
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	03e080e7          	jalr	62(ra) # 800039a6 <iunlock>
  end_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	9b4080e7          	jalr	-1612(ra) # 80004324 <end_op>

  return fd;
}
    80005978:	8526                	mv	a0,s1
    8000597a:	70ea                	ld	ra,184(sp)
    8000597c:	744a                	ld	s0,176(sp)
    8000597e:	74aa                	ld	s1,168(sp)
    80005980:	790a                	ld	s2,160(sp)
    80005982:	69ea                	ld	s3,152(sp)
    80005984:	6129                	addi	sp,sp,192
    80005986:	8082                	ret
      end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	99c080e7          	jalr	-1636(ra) # 80004324 <end_op>
      return -1;
    80005990:	b7e5                	j	80005978 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005992:	f5040513          	addi	a0,s0,-176
    80005996:	ffffe097          	auipc	ra,0xffffe
    8000599a:	702080e7          	jalr	1794(ra) # 80004098 <namei>
    8000599e:	892a                	mv	s2,a0
    800059a0:	c905                	beqz	a0,800059d0 <sys_open+0x13c>
    ilock(ip);
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	f42080e7          	jalr	-190(ra) # 800038e4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059aa:	04491703          	lh	a4,68(s2)
    800059ae:	4785                	li	a5,1
    800059b0:	f4f712e3          	bne	a4,a5,800058f4 <sys_open+0x60>
    800059b4:	f4c42783          	lw	a5,-180(s0)
    800059b8:	dba1                	beqz	a5,80005908 <sys_open+0x74>
      iunlockput(ip);
    800059ba:	854a                	mv	a0,s2
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	18a080e7          	jalr	394(ra) # 80003b46 <iunlockput>
      end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	960080e7          	jalr	-1696(ra) # 80004324 <end_op>
      return -1;
    800059cc:	54fd                	li	s1,-1
    800059ce:	b76d                	j	80005978 <sys_open+0xe4>
      end_op();
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	954080e7          	jalr	-1708(ra) # 80004324 <end_op>
      return -1;
    800059d8:	54fd                	li	s1,-1
    800059da:	bf79                	j	80005978 <sys_open+0xe4>
    iunlockput(ip);
    800059dc:	854a                	mv	a0,s2
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	168080e7          	jalr	360(ra) # 80003b46 <iunlockput>
    end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	93e080e7          	jalr	-1730(ra) # 80004324 <end_op>
    return -1;
    800059ee:	54fd                	li	s1,-1
    800059f0:	b761                	j	80005978 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059f2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059f6:	04691783          	lh	a5,70(s2)
    800059fa:	02f99223          	sh	a5,36(s3)
    800059fe:	bf2d                	j	80005938 <sys_open+0xa4>
    itrunc(ip);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	ff0080e7          	jalr	-16(ra) # 800039f2 <itrunc>
    80005a0a:	bfb1                	j	80005966 <sys_open+0xd2>
      fileclose(f);
    80005a0c:	854e                	mv	a0,s3
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	d68080e7          	jalr	-664(ra) # 80004776 <fileclose>
    iunlockput(ip);
    80005a16:	854a                	mv	a0,s2
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	12e080e7          	jalr	302(ra) # 80003b46 <iunlockput>
    end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	904080e7          	jalr	-1788(ra) # 80004324 <end_op>
    return -1;
    80005a28:	54fd                	li	s1,-1
    80005a2a:	b7b9                	j	80005978 <sys_open+0xe4>

0000000080005a2c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a2c:	7175                	addi	sp,sp,-144
    80005a2e:	e506                	sd	ra,136(sp)
    80005a30:	e122                	sd	s0,128(sp)
    80005a32:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	870080e7          	jalr	-1936(ra) # 800042a4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a3c:	08000613          	li	a2,128
    80005a40:	f7040593          	addi	a1,s0,-144
    80005a44:	4501                	li	a0,0
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	370080e7          	jalr	880(ra) # 80002db6 <argstr>
    80005a4e:	02054963          	bltz	a0,80005a80 <sys_mkdir+0x54>
    80005a52:	4681                	li	a3,0
    80005a54:	4601                	li	a2,0
    80005a56:	4585                	li	a1,1
    80005a58:	f7040513          	addi	a0,s0,-144
    80005a5c:	fffff097          	auipc	ra,0xfffff
    80005a60:	7fe080e7          	jalr	2046(ra) # 8000525a <create>
    80005a64:	cd11                	beqz	a0,80005a80 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a66:	ffffe097          	auipc	ra,0xffffe
    80005a6a:	0e0080e7          	jalr	224(ra) # 80003b46 <iunlockput>
  end_op();
    80005a6e:	fffff097          	auipc	ra,0xfffff
    80005a72:	8b6080e7          	jalr	-1866(ra) # 80004324 <end_op>
  return 0;
    80005a76:	4501                	li	a0,0
}
    80005a78:	60aa                	ld	ra,136(sp)
    80005a7a:	640a                	ld	s0,128(sp)
    80005a7c:	6149                	addi	sp,sp,144
    80005a7e:	8082                	ret
    end_op();
    80005a80:	fffff097          	auipc	ra,0xfffff
    80005a84:	8a4080e7          	jalr	-1884(ra) # 80004324 <end_op>
    return -1;
    80005a88:	557d                	li	a0,-1
    80005a8a:	b7fd                	j	80005a78 <sys_mkdir+0x4c>

0000000080005a8c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a8c:	7135                	addi	sp,sp,-160
    80005a8e:	ed06                	sd	ra,152(sp)
    80005a90:	e922                	sd	s0,144(sp)
    80005a92:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	810080e7          	jalr	-2032(ra) # 800042a4 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a9c:	08000613          	li	a2,128
    80005aa0:	f7040593          	addi	a1,s0,-144
    80005aa4:	4501                	li	a0,0
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	310080e7          	jalr	784(ra) # 80002db6 <argstr>
    80005aae:	04054a63          	bltz	a0,80005b02 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ab2:	f6c40593          	addi	a1,s0,-148
    80005ab6:	4505                	li	a0,1
    80005ab8:	ffffd097          	auipc	ra,0xffffd
    80005abc:	2ba080e7          	jalr	698(ra) # 80002d72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ac0:	04054163          	bltz	a0,80005b02 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ac4:	f6840593          	addi	a1,s0,-152
    80005ac8:	4509                	li	a0,2
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	2a8080e7          	jalr	680(ra) # 80002d72 <argint>
     argint(1, &major) < 0 ||
    80005ad2:	02054863          	bltz	a0,80005b02 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ad6:	f6841683          	lh	a3,-152(s0)
    80005ada:	f6c41603          	lh	a2,-148(s0)
    80005ade:	458d                	li	a1,3
    80005ae0:	f7040513          	addi	a0,s0,-144
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	776080e7          	jalr	1910(ra) # 8000525a <create>
     argint(2, &minor) < 0 ||
    80005aec:	c919                	beqz	a0,80005b02 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	058080e7          	jalr	88(ra) # 80003b46 <iunlockput>
  end_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	82e080e7          	jalr	-2002(ra) # 80004324 <end_op>
  return 0;
    80005afe:	4501                	li	a0,0
    80005b00:	a031                	j	80005b0c <sys_mknod+0x80>
    end_op();
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	822080e7          	jalr	-2014(ra) # 80004324 <end_op>
    return -1;
    80005b0a:	557d                	li	a0,-1
}
    80005b0c:	60ea                	ld	ra,152(sp)
    80005b0e:	644a                	ld	s0,144(sp)
    80005b10:	610d                	addi	sp,sp,160
    80005b12:	8082                	ret

0000000080005b14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b14:	7135                	addi	sp,sp,-160
    80005b16:	ed06                	sd	ra,152(sp)
    80005b18:	e922                	sd	s0,144(sp)
    80005b1a:	e526                	sd	s1,136(sp)
    80005b1c:	e14a                	sd	s2,128(sp)
    80005b1e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b20:	ffffc097          	auipc	ra,0xffffc
    80005b24:	15a080e7          	jalr	346(ra) # 80001c7a <myproc>
    80005b28:	892a                	mv	s2,a0
  
  begin_op();
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	77a080e7          	jalr	1914(ra) # 800042a4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b32:	08000613          	li	a2,128
    80005b36:	f6040593          	addi	a1,s0,-160
    80005b3a:	4501                	li	a0,0
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	27a080e7          	jalr	634(ra) # 80002db6 <argstr>
    80005b44:	04054b63          	bltz	a0,80005b9a <sys_chdir+0x86>
    80005b48:	f6040513          	addi	a0,s0,-160
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	54c080e7          	jalr	1356(ra) # 80004098 <namei>
    80005b54:	84aa                	mv	s1,a0
    80005b56:	c131                	beqz	a0,80005b9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	d8c080e7          	jalr	-628(ra) # 800038e4 <ilock>
  if(ip->type != T_DIR){
    80005b60:	04449703          	lh	a4,68(s1)
    80005b64:	4785                	li	a5,1
    80005b66:	04f71063          	bne	a4,a5,80005ba6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b6a:	8526                	mv	a0,s1
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	e3a080e7          	jalr	-454(ra) # 800039a6 <iunlock>
  iput(p->cwd);
    80005b74:	15093503          	ld	a0,336(s2)
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	f26080e7          	jalr	-218(ra) # 80003a9e <iput>
  end_op();
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	7a4080e7          	jalr	1956(ra) # 80004324 <end_op>
  p->cwd = ip;
    80005b88:	14993823          	sd	s1,336(s2)
  return 0;
    80005b8c:	4501                	li	a0,0
}
    80005b8e:	60ea                	ld	ra,152(sp)
    80005b90:	644a                	ld	s0,144(sp)
    80005b92:	64aa                	ld	s1,136(sp)
    80005b94:	690a                	ld	s2,128(sp)
    80005b96:	610d                	addi	sp,sp,160
    80005b98:	8082                	ret
    end_op();
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	78a080e7          	jalr	1930(ra) # 80004324 <end_op>
    return -1;
    80005ba2:	557d                	li	a0,-1
    80005ba4:	b7ed                	j	80005b8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	f9e080e7          	jalr	-98(ra) # 80003b46 <iunlockput>
    end_op();
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	774080e7          	jalr	1908(ra) # 80004324 <end_op>
    return -1;
    80005bb8:	557d                	li	a0,-1
    80005bba:	bfd1                	j	80005b8e <sys_chdir+0x7a>

0000000080005bbc <sys_exec>:

uint64
sys_exec(void)
{
    80005bbc:	7145                	addi	sp,sp,-464
    80005bbe:	e786                	sd	ra,456(sp)
    80005bc0:	e3a2                	sd	s0,448(sp)
    80005bc2:	ff26                	sd	s1,440(sp)
    80005bc4:	fb4a                	sd	s2,432(sp)
    80005bc6:	f74e                	sd	s3,424(sp)
    80005bc8:	f352                	sd	s4,416(sp)
    80005bca:	ef56                	sd	s5,408(sp)
    80005bcc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bce:	08000613          	li	a2,128
    80005bd2:	f4040593          	addi	a1,s0,-192
    80005bd6:	4501                	li	a0,0
    80005bd8:	ffffd097          	auipc	ra,0xffffd
    80005bdc:	1de080e7          	jalr	478(ra) # 80002db6 <argstr>
    return -1;
    80005be0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005be2:	0c054a63          	bltz	a0,80005cb6 <sys_exec+0xfa>
    80005be6:	e3840593          	addi	a1,s0,-456
    80005bea:	4505                	li	a0,1
    80005bec:	ffffd097          	auipc	ra,0xffffd
    80005bf0:	1a8080e7          	jalr	424(ra) # 80002d94 <argaddr>
    80005bf4:	0c054163          	bltz	a0,80005cb6 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bf8:	10000613          	li	a2,256
    80005bfc:	4581                	li	a1,0
    80005bfe:	e4040513          	addi	a0,s0,-448
    80005c02:	ffffb097          	auipc	ra,0xffffb
    80005c06:	2a2080e7          	jalr	674(ra) # 80000ea4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c0a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c0e:	89a6                	mv	s3,s1
    80005c10:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c12:	02000a13          	li	s4,32
    80005c16:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c1a:	00391513          	slli	a0,s2,0x3
    80005c1e:	e3040593          	addi	a1,s0,-464
    80005c22:	e3843783          	ld	a5,-456(s0)
    80005c26:	953e                	add	a0,a0,a5
    80005c28:	ffffd097          	auipc	ra,0xffffd
    80005c2c:	0b0080e7          	jalr	176(ra) # 80002cd8 <fetchaddr>
    80005c30:	02054a63          	bltz	a0,80005c64 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c34:	e3043783          	ld	a5,-464(s0)
    80005c38:	c3b9                	beqz	a5,80005c7e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c3a:	ffffb097          	auipc	ra,0xffffb
    80005c3e:	f5e080e7          	jalr	-162(ra) # 80000b98 <kalloc>
    80005c42:	85aa                	mv	a1,a0
    80005c44:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c48:	cd11                	beqz	a0,80005c64 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c4a:	6605                	lui	a2,0x1
    80005c4c:	e3043503          	ld	a0,-464(s0)
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	0da080e7          	jalr	218(ra) # 80002d2a <fetchstr>
    80005c58:	00054663          	bltz	a0,80005c64 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c5c:	0905                	addi	s2,s2,1
    80005c5e:	09a1                	addi	s3,s3,8
    80005c60:	fb491be3          	bne	s2,s4,80005c16 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c64:	10048913          	addi	s2,s1,256
    80005c68:	6088                	ld	a0,0(s1)
    80005c6a:	c529                	beqz	a0,80005cb4 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c6c:	ffffb097          	auipc	ra,0xffffb
    80005c70:	dc6080e7          	jalr	-570(ra) # 80000a32 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c74:	04a1                	addi	s1,s1,8
    80005c76:	ff2499e3          	bne	s1,s2,80005c68 <sys_exec+0xac>
  return -1;
    80005c7a:	597d                	li	s2,-1
    80005c7c:	a82d                	j	80005cb6 <sys_exec+0xfa>
      argv[i] = 0;
    80005c7e:	0a8e                	slli	s5,s5,0x3
    80005c80:	fc040793          	addi	a5,s0,-64
    80005c84:	9abe                	add	s5,s5,a5
    80005c86:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c8a:	e4040593          	addi	a1,s0,-448
    80005c8e:	f4040513          	addi	a0,s0,-192
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	194080e7          	jalr	404(ra) # 80004e26 <exec>
    80005c9a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c9c:	10048993          	addi	s3,s1,256
    80005ca0:	6088                	ld	a0,0(s1)
    80005ca2:	c911                	beqz	a0,80005cb6 <sys_exec+0xfa>
    kfree(argv[i]);
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	d8e080e7          	jalr	-626(ra) # 80000a32 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cac:	04a1                	addi	s1,s1,8
    80005cae:	ff3499e3          	bne	s1,s3,80005ca0 <sys_exec+0xe4>
    80005cb2:	a011                	j	80005cb6 <sys_exec+0xfa>
  return -1;
    80005cb4:	597d                	li	s2,-1
}
    80005cb6:	854a                	mv	a0,s2
    80005cb8:	60be                	ld	ra,456(sp)
    80005cba:	641e                	ld	s0,448(sp)
    80005cbc:	74fa                	ld	s1,440(sp)
    80005cbe:	795a                	ld	s2,432(sp)
    80005cc0:	79ba                	ld	s3,424(sp)
    80005cc2:	7a1a                	ld	s4,416(sp)
    80005cc4:	6afa                	ld	s5,408(sp)
    80005cc6:	6179                	addi	sp,sp,464
    80005cc8:	8082                	ret

0000000080005cca <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cca:	7139                	addi	sp,sp,-64
    80005ccc:	fc06                	sd	ra,56(sp)
    80005cce:	f822                	sd	s0,48(sp)
    80005cd0:	f426                	sd	s1,40(sp)
    80005cd2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cd4:	ffffc097          	auipc	ra,0xffffc
    80005cd8:	fa6080e7          	jalr	-90(ra) # 80001c7a <myproc>
    80005cdc:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005cde:	fd840593          	addi	a1,s0,-40
    80005ce2:	4501                	li	a0,0
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	0b0080e7          	jalr	176(ra) # 80002d94 <argaddr>
    return -1;
    80005cec:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cee:	0e054063          	bltz	a0,80005dce <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cf2:	fc840593          	addi	a1,s0,-56
    80005cf6:	fd040513          	addi	a0,s0,-48
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	dd2080e7          	jalr	-558(ra) # 80004acc <pipealloc>
    return -1;
    80005d02:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d04:	0c054563          	bltz	a0,80005dce <sys_pipe+0x104>
  fd0 = -1;
    80005d08:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d0c:	fd043503          	ld	a0,-48(s0)
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	508080e7          	jalr	1288(ra) # 80005218 <fdalloc>
    80005d18:	fca42223          	sw	a0,-60(s0)
    80005d1c:	08054c63          	bltz	a0,80005db4 <sys_pipe+0xea>
    80005d20:	fc843503          	ld	a0,-56(s0)
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	4f4080e7          	jalr	1268(ra) # 80005218 <fdalloc>
    80005d2c:	fca42023          	sw	a0,-64(s0)
    80005d30:	06054863          	bltz	a0,80005da0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d34:	4691                	li	a3,4
    80005d36:	fc440613          	addi	a2,s0,-60
    80005d3a:	fd843583          	ld	a1,-40(s0)
    80005d3e:	68a8                	ld	a0,80(s1)
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	d54080e7          	jalr	-684(ra) # 80001a94 <copyout>
    80005d48:	02054063          	bltz	a0,80005d68 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d4c:	4691                	li	a3,4
    80005d4e:	fc040613          	addi	a2,s0,-64
    80005d52:	fd843583          	ld	a1,-40(s0)
    80005d56:	0591                	addi	a1,a1,4
    80005d58:	68a8                	ld	a0,80(s1)
    80005d5a:	ffffc097          	auipc	ra,0xffffc
    80005d5e:	d3a080e7          	jalr	-710(ra) # 80001a94 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d62:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d64:	06055563          	bgez	a0,80005dce <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d68:	fc442783          	lw	a5,-60(s0)
    80005d6c:	07e9                	addi	a5,a5,26
    80005d6e:	078e                	slli	a5,a5,0x3
    80005d70:	97a6                	add	a5,a5,s1
    80005d72:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d76:	fc042503          	lw	a0,-64(s0)
    80005d7a:	0569                	addi	a0,a0,26
    80005d7c:	050e                	slli	a0,a0,0x3
    80005d7e:	9526                	add	a0,a0,s1
    80005d80:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d84:	fd043503          	ld	a0,-48(s0)
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	9ee080e7          	jalr	-1554(ra) # 80004776 <fileclose>
    fileclose(wf);
    80005d90:	fc843503          	ld	a0,-56(s0)
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	9e2080e7          	jalr	-1566(ra) # 80004776 <fileclose>
    return -1;
    80005d9c:	57fd                	li	a5,-1
    80005d9e:	a805                	j	80005dce <sys_pipe+0x104>
    if(fd0 >= 0)
    80005da0:	fc442783          	lw	a5,-60(s0)
    80005da4:	0007c863          	bltz	a5,80005db4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005da8:	01a78513          	addi	a0,a5,26
    80005dac:	050e                	slli	a0,a0,0x3
    80005dae:	9526                	add	a0,a0,s1
    80005db0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005db4:	fd043503          	ld	a0,-48(s0)
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	9be080e7          	jalr	-1602(ra) # 80004776 <fileclose>
    fileclose(wf);
    80005dc0:	fc843503          	ld	a0,-56(s0)
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	9b2080e7          	jalr	-1614(ra) # 80004776 <fileclose>
    return -1;
    80005dcc:	57fd                	li	a5,-1
}
    80005dce:	853e                	mv	a0,a5
    80005dd0:	70e2                	ld	ra,56(sp)
    80005dd2:	7442                	ld	s0,48(sp)
    80005dd4:	74a2                	ld	s1,40(sp)
    80005dd6:	6121                	addi	sp,sp,64
    80005dd8:	8082                	ret
    80005dda:	0000                	unimp
    80005ddc:	0000                	unimp
	...

0000000080005de0 <kernelvec>:
    80005de0:	7111                	addi	sp,sp,-256
    80005de2:	e006                	sd	ra,0(sp)
    80005de4:	e40a                	sd	sp,8(sp)
    80005de6:	e80e                	sd	gp,16(sp)
    80005de8:	ec12                	sd	tp,24(sp)
    80005dea:	f016                	sd	t0,32(sp)
    80005dec:	f41a                	sd	t1,40(sp)
    80005dee:	f81e                	sd	t2,48(sp)
    80005df0:	fc22                	sd	s0,56(sp)
    80005df2:	e0a6                	sd	s1,64(sp)
    80005df4:	e4aa                	sd	a0,72(sp)
    80005df6:	e8ae                	sd	a1,80(sp)
    80005df8:	ecb2                	sd	a2,88(sp)
    80005dfa:	f0b6                	sd	a3,96(sp)
    80005dfc:	f4ba                	sd	a4,104(sp)
    80005dfe:	f8be                	sd	a5,112(sp)
    80005e00:	fcc2                	sd	a6,120(sp)
    80005e02:	e146                	sd	a7,128(sp)
    80005e04:	e54a                	sd	s2,136(sp)
    80005e06:	e94e                	sd	s3,144(sp)
    80005e08:	ed52                	sd	s4,152(sp)
    80005e0a:	f156                	sd	s5,160(sp)
    80005e0c:	f55a                	sd	s6,168(sp)
    80005e0e:	f95e                	sd	s7,176(sp)
    80005e10:	fd62                	sd	s8,184(sp)
    80005e12:	e1e6                	sd	s9,192(sp)
    80005e14:	e5ea                	sd	s10,200(sp)
    80005e16:	e9ee                	sd	s11,208(sp)
    80005e18:	edf2                	sd	t3,216(sp)
    80005e1a:	f1f6                	sd	t4,224(sp)
    80005e1c:	f5fa                	sd	t5,232(sp)
    80005e1e:	f9fe                	sd	t6,240(sp)
    80005e20:	d85fc0ef          	jal	ra,80002ba4 <kerneltrap>
    80005e24:	6082                	ld	ra,0(sp)
    80005e26:	6122                	ld	sp,8(sp)
    80005e28:	61c2                	ld	gp,16(sp)
    80005e2a:	7282                	ld	t0,32(sp)
    80005e2c:	7322                	ld	t1,40(sp)
    80005e2e:	73c2                	ld	t2,48(sp)
    80005e30:	7462                	ld	s0,56(sp)
    80005e32:	6486                	ld	s1,64(sp)
    80005e34:	6526                	ld	a0,72(sp)
    80005e36:	65c6                	ld	a1,80(sp)
    80005e38:	6666                	ld	a2,88(sp)
    80005e3a:	7686                	ld	a3,96(sp)
    80005e3c:	7726                	ld	a4,104(sp)
    80005e3e:	77c6                	ld	a5,112(sp)
    80005e40:	7866                	ld	a6,120(sp)
    80005e42:	688a                	ld	a7,128(sp)
    80005e44:	692a                	ld	s2,136(sp)
    80005e46:	69ca                	ld	s3,144(sp)
    80005e48:	6a6a                	ld	s4,152(sp)
    80005e4a:	7a8a                	ld	s5,160(sp)
    80005e4c:	7b2a                	ld	s6,168(sp)
    80005e4e:	7bca                	ld	s7,176(sp)
    80005e50:	7c6a                	ld	s8,184(sp)
    80005e52:	6c8e                	ld	s9,192(sp)
    80005e54:	6d2e                	ld	s10,200(sp)
    80005e56:	6dce                	ld	s11,208(sp)
    80005e58:	6e6e                	ld	t3,216(sp)
    80005e5a:	7e8e                	ld	t4,224(sp)
    80005e5c:	7f2e                	ld	t5,232(sp)
    80005e5e:	7fce                	ld	t6,240(sp)
    80005e60:	6111                	addi	sp,sp,256
    80005e62:	10200073          	sret

0000000080005e66 <unexpected_exc>:
    80005e66:	a001                	j	80005e66 <unexpected_exc>

0000000080005e68 <unexpected_int>:
    80005e68:	a001                	j	80005e68 <unexpected_int>
    80005e6a:	00000013          	nop
    80005e6e:	0001                	nop

0000000080005e70 <timervec>:
    80005e70:	34051573          	csrrw	a0,mscratch,a0
    80005e74:	e10c                	sd	a1,0(a0)
    80005e76:	e510                	sd	a2,8(a0)
    80005e78:	e914                	sd	a3,16(a0)
    80005e7a:	342025f3          	csrr	a1,mcause
    80005e7e:	fe05d4e3          	bgez	a1,80005e66 <unexpected_exc>
    80005e82:	fff0061b          	addiw	a2,zero,-1
    80005e86:	167e                	slli	a2,a2,0x3f
    80005e88:	061d                	addi	a2,a2,7
    80005e8a:	fcc59fe3          	bne	a1,a2,80005e68 <unexpected_int>
    80005e8e:	710c                	ld	a1,32(a0)
    80005e90:	7510                	ld	a2,40(a0)
    80005e92:	6194                	ld	a3,0(a1)
    80005e94:	96b2                	add	a3,a3,a2
    80005e96:	e194                	sd	a3,0(a1)
    80005e98:	4589                	li	a1,2
    80005e9a:	14459073          	csrw	sip,a1
    80005e9e:	6914                	ld	a3,16(a0)
    80005ea0:	6510                	ld	a2,8(a0)
    80005ea2:	610c                	ld	a1,0(a0)
    80005ea4:	34051573          	csrrw	a0,mscratch,a0
    80005ea8:	30200073          	mret
	...

0000000080005eb6 <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eb6:	1141                	addi	sp,sp,-16
    80005eb8:	e422                	sd	s0,8(sp)
    80005eba:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ebc:	0c0007b7          	lui	a5,0xc000
    80005ec0:	4705                	li	a4,1
    80005ec2:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ec4:	c3d8                	sw	a4,4(a5)
}
    80005ec6:	6422                	ld	s0,8(sp)
    80005ec8:	0141                	addi	sp,sp,16
    80005eca:	8082                	ret

0000000080005ecc <plicinithart>:

void
plicinithart(void)
{
    80005ecc:	1141                	addi	sp,sp,-16
    80005ece:	e406                	sd	ra,8(sp)
    80005ed0:	e022                	sd	s0,0(sp)
    80005ed2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ed4:	ffffc097          	auipc	ra,0xffffc
    80005ed8:	d7a080e7          	jalr	-646(ra) # 80001c4e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005edc:	0085171b          	slliw	a4,a0,0x8
    80005ee0:	0c0027b7          	lui	a5,0xc002
    80005ee4:	97ba                	add	a5,a5,a4
    80005ee6:	40200713          	li	a4,1026
    80005eea:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005eee:	00d5151b          	slliw	a0,a0,0xd
    80005ef2:	0c2017b7          	lui	a5,0xc201
    80005ef6:	953e                	add	a0,a0,a5
    80005ef8:	00052023          	sw	zero,0(a0)
}
    80005efc:	60a2                	ld	ra,8(sp)
    80005efe:	6402                	ld	s0,0(sp)
    80005f00:	0141                	addi	sp,sp,16
    80005f02:	8082                	ret

0000000080005f04 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f04:	1141                	addi	sp,sp,-16
    80005f06:	e406                	sd	ra,8(sp)
    80005f08:	e022                	sd	s0,0(sp)
    80005f0a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f0c:	ffffc097          	auipc	ra,0xffffc
    80005f10:	d42080e7          	jalr	-702(ra) # 80001c4e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f14:	00d5179b          	slliw	a5,a0,0xd
    80005f18:	0c201537          	lui	a0,0xc201
    80005f1c:	953e                	add	a0,a0,a5
  return irq;
}
    80005f1e:	4148                	lw	a0,4(a0)
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f28:	1101                	addi	sp,sp,-32
    80005f2a:	ec06                	sd	ra,24(sp)
    80005f2c:	e822                	sd	s0,16(sp)
    80005f2e:	e426                	sd	s1,8(sp)
    80005f30:	1000                	addi	s0,sp,32
    80005f32:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f34:	ffffc097          	auipc	ra,0xffffc
    80005f38:	d1a080e7          	jalr	-742(ra) # 80001c4e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f3c:	00d5151b          	slliw	a0,a0,0xd
    80005f40:	0c2017b7          	lui	a5,0xc201
    80005f44:	97aa                	add	a5,a5,a0
    80005f46:	c3c4                	sw	s1,4(a5)
}
    80005f48:	60e2                	ld	ra,24(sp)
    80005f4a:	6442                	ld	s0,16(sp)
    80005f4c:	64a2                	ld	s1,8(sp)
    80005f4e:	6105                	addi	sp,sp,32
    80005f50:	8082                	ret

0000000080005f52 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f52:	1141                	addi	sp,sp,-16
    80005f54:	e406                	sd	ra,8(sp)
    80005f56:	e022                	sd	s0,0(sp)
    80005f58:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f5a:	479d                	li	a5,7
    80005f5c:	04a7cc63          	blt	a5,a0,80005fb4 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f60:	0003d797          	auipc	a5,0x3d
    80005f64:	0a078793          	addi	a5,a5,160 # 80043000 <disk>
    80005f68:	00a78733          	add	a4,a5,a0
    80005f6c:	6789                	lui	a5,0x2
    80005f6e:	97ba                	add	a5,a5,a4
    80005f70:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f74:	eba1                	bnez	a5,80005fc4 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f76:	00451713          	slli	a4,a0,0x4
    80005f7a:	0003f797          	auipc	a5,0x3f
    80005f7e:	0867b783          	ld	a5,134(a5) # 80045000 <disk+0x2000>
    80005f82:	97ba                	add	a5,a5,a4
    80005f84:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f88:	0003d797          	auipc	a5,0x3d
    80005f8c:	07878793          	addi	a5,a5,120 # 80043000 <disk>
    80005f90:	97aa                	add	a5,a5,a0
    80005f92:	6509                	lui	a0,0x2
    80005f94:	953e                	add	a0,a0,a5
    80005f96:	4785                	li	a5,1
    80005f98:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f9c:	0003f517          	auipc	a0,0x3f
    80005fa0:	07c50513          	addi	a0,a0,124 # 80045018 <disk+0x2018>
    80005fa4:	ffffc097          	auipc	ra,0xffffc
    80005fa8:	66c080e7          	jalr	1644(ra) # 80002610 <wakeup>
}
    80005fac:	60a2                	ld	ra,8(sp)
    80005fae:	6402                	ld	s0,0(sp)
    80005fb0:	0141                	addi	sp,sp,16
    80005fb2:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fb4:	00002517          	auipc	a0,0x2
    80005fb8:	7dc50513          	addi	a0,a0,2012 # 80008790 <syscalls+0x330>
    80005fbc:	ffffa097          	auipc	ra,0xffffa
    80005fc0:	59a080e7          	jalr	1434(ra) # 80000556 <panic>
    panic("virtio_disk_intr 2");
    80005fc4:	00002517          	auipc	a0,0x2
    80005fc8:	7e450513          	addi	a0,a0,2020 # 800087a8 <syscalls+0x348>
    80005fcc:	ffffa097          	auipc	ra,0xffffa
    80005fd0:	58a080e7          	jalr	1418(ra) # 80000556 <panic>

0000000080005fd4 <virtio_disk_init>:
{
    80005fd4:	1101                	addi	sp,sp,-32
    80005fd6:	ec06                	sd	ra,24(sp)
    80005fd8:	e822                	sd	s0,16(sp)
    80005fda:	e426                	sd	s1,8(sp)
    80005fdc:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fde:	00002597          	auipc	a1,0x2
    80005fe2:	7e258593          	addi	a1,a1,2018 # 800087c0 <syscalls+0x360>
    80005fe6:	0003f517          	auipc	a0,0x3f
    80005fea:	0c250513          	addi	a0,a0,194 # 800450a8 <disk+0x20a8>
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	d2a080e7          	jalr	-726(ra) # 80000d18 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ff6:	100017b7          	lui	a5,0x10001
    80005ffa:	4398                	lw	a4,0(a5)
    80005ffc:	2701                	sext.w	a4,a4
    80005ffe:	747277b7          	lui	a5,0x74727
    80006002:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006006:	0ef71163          	bne	a4,a5,800060e8 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000600a:	100017b7          	lui	a5,0x10001
    8000600e:	43dc                	lw	a5,4(a5)
    80006010:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006012:	4705                	li	a4,1
    80006014:	0ce79a63          	bne	a5,a4,800060e8 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	479c                	lw	a5,8(a5)
    8000601e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006020:	4709                	li	a4,2
    80006022:	0ce79363          	bne	a5,a4,800060e8 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006026:	100017b7          	lui	a5,0x10001
    8000602a:	47d8                	lw	a4,12(a5)
    8000602c:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000602e:	554d47b7          	lui	a5,0x554d4
    80006032:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006036:	0af71963          	bne	a4,a5,800060e8 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000603a:	100017b7          	lui	a5,0x10001
    8000603e:	4705                	li	a4,1
    80006040:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006042:	470d                	li	a4,3
    80006044:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006046:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006048:	c7ffe737          	lui	a4,0xc7ffe
    8000604c:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fb875f>
    80006050:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006052:	2701                	sext.w	a4,a4
    80006054:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006056:	472d                	li	a4,11
    80006058:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605a:	473d                	li	a4,15
    8000605c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000605e:	6705                	lui	a4,0x1
    80006060:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006062:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006066:	5bdc                	lw	a5,52(a5)
    80006068:	2781                	sext.w	a5,a5
  if(max == 0)
    8000606a:	c7d9                	beqz	a5,800060f8 <virtio_disk_init+0x124>
  if(max < NUM)
    8000606c:	471d                	li	a4,7
    8000606e:	08f77d63          	bgeu	a4,a5,80006108 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006072:	100014b7          	lui	s1,0x10001
    80006076:	47a1                	li	a5,8
    80006078:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000607a:	6609                	lui	a2,0x2
    8000607c:	4581                	li	a1,0
    8000607e:	0003d517          	auipc	a0,0x3d
    80006082:	f8250513          	addi	a0,a0,-126 # 80043000 <disk>
    80006086:	ffffb097          	auipc	ra,0xffffb
    8000608a:	e1e080e7          	jalr	-482(ra) # 80000ea4 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000608e:	0003d717          	auipc	a4,0x3d
    80006092:	f7270713          	addi	a4,a4,-142 # 80043000 <disk>
    80006096:	00c75793          	srli	a5,a4,0xc
    8000609a:	2781                	sext.w	a5,a5
    8000609c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    8000609e:	0003f797          	auipc	a5,0x3f
    800060a2:	f6278793          	addi	a5,a5,-158 # 80045000 <disk+0x2000>
    800060a6:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060a8:	0003d717          	auipc	a4,0x3d
    800060ac:	fd870713          	addi	a4,a4,-40 # 80043080 <disk+0x80>
    800060b0:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060b2:	0003e717          	auipc	a4,0x3e
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80044000 <disk+0x1000>
    800060ba:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060bc:	4705                	li	a4,1
    800060be:	00e78c23          	sb	a4,24(a5)
    800060c2:	00e78ca3          	sb	a4,25(a5)
    800060c6:	00e78d23          	sb	a4,26(a5)
    800060ca:	00e78da3          	sb	a4,27(a5)
    800060ce:	00e78e23          	sb	a4,28(a5)
    800060d2:	00e78ea3          	sb	a4,29(a5)
    800060d6:	00e78f23          	sb	a4,30(a5)
    800060da:	00e78fa3          	sb	a4,31(a5)
}
    800060de:	60e2                	ld	ra,24(sp)
    800060e0:	6442                	ld	s0,16(sp)
    800060e2:	64a2                	ld	s1,8(sp)
    800060e4:	6105                	addi	sp,sp,32
    800060e6:	8082                	ret
    panic("could not find virtio disk");
    800060e8:	00002517          	auipc	a0,0x2
    800060ec:	6e850513          	addi	a0,a0,1768 # 800087d0 <syscalls+0x370>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	466080e7          	jalr	1126(ra) # 80000556 <panic>
    panic("virtio disk has no queue 0");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	6f850513          	addi	a0,a0,1784 # 800087f0 <syscalls+0x390>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	456080e7          	jalr	1110(ra) # 80000556 <panic>
    panic("virtio disk max queue too short");
    80006108:	00002517          	auipc	a0,0x2
    8000610c:	70850513          	addi	a0,a0,1800 # 80008810 <syscalls+0x3b0>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	446080e7          	jalr	1094(ra) # 80000556 <panic>

0000000080006118 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006118:	7119                	addi	sp,sp,-128
    8000611a:	fc86                	sd	ra,120(sp)
    8000611c:	f8a2                	sd	s0,112(sp)
    8000611e:	f4a6                	sd	s1,104(sp)
    80006120:	f0ca                	sd	s2,96(sp)
    80006122:	ecce                	sd	s3,88(sp)
    80006124:	e8d2                	sd	s4,80(sp)
    80006126:	e4d6                	sd	s5,72(sp)
    80006128:	e0da                	sd	s6,64(sp)
    8000612a:	fc5e                	sd	s7,56(sp)
    8000612c:	f862                	sd	s8,48(sp)
    8000612e:	f466                	sd	s9,40(sp)
    80006130:	f06a                	sd	s10,32(sp)
    80006132:	0100                	addi	s0,sp,128
    80006134:	892a                	mv	s2,a0
    80006136:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006138:	00c52c83          	lw	s9,12(a0)
    8000613c:	001c9c9b          	slliw	s9,s9,0x1
    80006140:	1c82                	slli	s9,s9,0x20
    80006142:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006146:	0003f517          	auipc	a0,0x3f
    8000614a:	f6250513          	addi	a0,a0,-158 # 800450a8 <disk+0x20a8>
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	c5a080e7          	jalr	-934(ra) # 80000da8 <acquire>
  for(int i = 0; i < 3; i++){
    80006156:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006158:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000615a:	0003db97          	auipc	s7,0x3d
    8000615e:	ea6b8b93          	addi	s7,s7,-346 # 80043000 <disk>
    80006162:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006164:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006166:	8a4e                	mv	s4,s3
    80006168:	a051                	j	800061ec <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000616a:	00fb86b3          	add	a3,s7,a5
    8000616e:	96da                	add	a3,a3,s6
    80006170:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006174:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006176:	0207c563          	bltz	a5,800061a0 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000617a:	2485                	addiw	s1,s1,1
    8000617c:	0711                	addi	a4,a4,4
    8000617e:	23548d63          	beq	s1,s5,800063b8 <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006182:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006184:	0003f697          	auipc	a3,0x3f
    80006188:	e9468693          	addi	a3,a3,-364 # 80045018 <disk+0x2018>
    8000618c:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000618e:	0006c583          	lbu	a1,0(a3)
    80006192:	fde1                	bnez	a1,8000616a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006194:	2785                	addiw	a5,a5,1
    80006196:	0685                	addi	a3,a3,1
    80006198:	ff879be3          	bne	a5,s8,8000618e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000619c:	57fd                	li	a5,-1
    8000619e:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061a0:	02905a63          	blez	s1,800061d4 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061a4:	f9042503          	lw	a0,-112(s0)
    800061a8:	00000097          	auipc	ra,0x0
    800061ac:	daa080e7          	jalr	-598(ra) # 80005f52 <free_desc>
      for(int j = 0; j < i; j++)
    800061b0:	4785                	li	a5,1
    800061b2:	0297d163          	bge	a5,s1,800061d4 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061b6:	f9442503          	lw	a0,-108(s0)
    800061ba:	00000097          	auipc	ra,0x0
    800061be:	d98080e7          	jalr	-616(ra) # 80005f52 <free_desc>
      for(int j = 0; j < i; j++)
    800061c2:	4789                	li	a5,2
    800061c4:	0097d863          	bge	a5,s1,800061d4 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061c8:	f9842503          	lw	a0,-104(s0)
    800061cc:	00000097          	auipc	ra,0x0
    800061d0:	d86080e7          	jalr	-634(ra) # 80005f52 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d4:	0003f597          	auipc	a1,0x3f
    800061d8:	ed458593          	addi	a1,a1,-300 # 800450a8 <disk+0x20a8>
    800061dc:	0003f517          	auipc	a0,0x3f
    800061e0:	e3c50513          	addi	a0,a0,-452 # 80045018 <disk+0x2018>
    800061e4:	ffffc097          	auipc	ra,0xffffc
    800061e8:	2a6080e7          	jalr	678(ra) # 8000248a <sleep>
  for(int i = 0; i < 3; i++){
    800061ec:	f9040713          	addi	a4,s0,-112
    800061f0:	84ce                	mv	s1,s3
    800061f2:	bf41                	j	80006182 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800061f4:	4785                	li	a5,1
    800061f6:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800061fa:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800061fe:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006202:	f9042983          	lw	s3,-112(s0)
    80006206:	00499493          	slli	s1,s3,0x4
    8000620a:	0003fa17          	auipc	s4,0x3f
    8000620e:	df6a0a13          	addi	s4,s4,-522 # 80045000 <disk+0x2000>
    80006212:	000a3a83          	ld	s5,0(s4)
    80006216:	9aa6                	add	s5,s5,s1
    80006218:	f8040513          	addi	a0,s0,-128
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	05c080e7          	jalr	92(ra) # 80001278 <kvmpa>
    80006224:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006228:	000a3783          	ld	a5,0(s4)
    8000622c:	97a6                	add	a5,a5,s1
    8000622e:	4741                	li	a4,16
    80006230:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006232:	000a3783          	ld	a5,0(s4)
    80006236:	97a6                	add	a5,a5,s1
    80006238:	4705                	li	a4,1
    8000623a:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    8000623e:	f9442703          	lw	a4,-108(s0)
    80006242:	000a3783          	ld	a5,0(s4)
    80006246:	97a6                	add	a5,a5,s1
    80006248:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000624c:	0712                	slli	a4,a4,0x4
    8000624e:	000a3783          	ld	a5,0(s4)
    80006252:	97ba                	add	a5,a5,a4
    80006254:	05890693          	addi	a3,s2,88
    80006258:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000625a:	000a3783          	ld	a5,0(s4)
    8000625e:	97ba                	add	a5,a5,a4
    80006260:	40000693          	li	a3,1024
    80006264:	c794                	sw	a3,8(a5)
  if(write)
    80006266:	100d0a63          	beqz	s10,8000637a <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000626a:	0003f797          	auipc	a5,0x3f
    8000626e:	d967b783          	ld	a5,-618(a5) # 80045000 <disk+0x2000>
    80006272:	97ba                	add	a5,a5,a4
    80006274:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006278:	0003d517          	auipc	a0,0x3d
    8000627c:	d8850513          	addi	a0,a0,-632 # 80043000 <disk>
    80006280:	0003f797          	auipc	a5,0x3f
    80006284:	d8078793          	addi	a5,a5,-640 # 80045000 <disk+0x2000>
    80006288:	6394                	ld	a3,0(a5)
    8000628a:	96ba                	add	a3,a3,a4
    8000628c:	00c6d603          	lhu	a2,12(a3)
    80006290:	00166613          	ori	a2,a2,1
    80006294:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006298:	f9842683          	lw	a3,-104(s0)
    8000629c:	6390                	ld	a2,0(a5)
    8000629e:	9732                	add	a4,a4,a2
    800062a0:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800062a4:	20098613          	addi	a2,s3,512
    800062a8:	0612                	slli	a2,a2,0x4
    800062aa:	962a                	add	a2,a2,a0
    800062ac:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062b0:	00469713          	slli	a4,a3,0x4
    800062b4:	6394                	ld	a3,0(a5)
    800062b6:	96ba                	add	a3,a3,a4
    800062b8:	6589                	lui	a1,0x2
    800062ba:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800062be:	94ae                	add	s1,s1,a1
    800062c0:	94aa                	add	s1,s1,a0
    800062c2:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800062c4:	6394                	ld	a3,0(a5)
    800062c6:	96ba                	add	a3,a3,a4
    800062c8:	4585                	li	a1,1
    800062ca:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062cc:	6394                	ld	a3,0(a5)
    800062ce:	96ba                	add	a3,a3,a4
    800062d0:	4509                	li	a0,2
    800062d2:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062d6:	6394                	ld	a3,0(a5)
    800062d8:	9736                	add	a4,a4,a3
    800062da:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062de:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800062e2:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062e6:	6794                	ld	a3,8(a5)
    800062e8:	0026d703          	lhu	a4,2(a3)
    800062ec:	8b1d                	andi	a4,a4,7
    800062ee:	2709                	addiw	a4,a4,2
    800062f0:	0706                	slli	a4,a4,0x1
    800062f2:	9736                	add	a4,a4,a3
    800062f4:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800062f8:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062fc:	6798                	ld	a4,8(a5)
    800062fe:	00275783          	lhu	a5,2(a4)
    80006302:	2785                	addiw	a5,a5,1
    80006304:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006308:	100017b7          	lui	a5,0x10001
    8000630c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006310:	00492703          	lw	a4,4(s2)
    80006314:	4785                	li	a5,1
    80006316:	02f71163          	bne	a4,a5,80006338 <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000631a:	0003f997          	auipc	s3,0x3f
    8000631e:	d8e98993          	addi	s3,s3,-626 # 800450a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006322:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006324:	85ce                	mv	a1,s3
    80006326:	854a                	mv	a0,s2
    80006328:	ffffc097          	auipc	ra,0xffffc
    8000632c:	162080e7          	jalr	354(ra) # 8000248a <sleep>
  while(b->disk == 1) {
    80006330:	00492783          	lw	a5,4(s2)
    80006334:	fe9788e3          	beq	a5,s1,80006324 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    80006338:	f9042483          	lw	s1,-112(s0)
    8000633c:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006340:	00479713          	slli	a4,a5,0x4
    80006344:	0003d797          	auipc	a5,0x3d
    80006348:	cbc78793          	addi	a5,a5,-836 # 80043000 <disk>
    8000634c:	97ba                	add	a5,a5,a4
    8000634e:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006352:	0003f917          	auipc	s2,0x3f
    80006356:	cae90913          	addi	s2,s2,-850 # 80045000 <disk+0x2000>
    free_desc(i);
    8000635a:	8526                	mv	a0,s1
    8000635c:	00000097          	auipc	ra,0x0
    80006360:	bf6080e7          	jalr	-1034(ra) # 80005f52 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006364:	0492                	slli	s1,s1,0x4
    80006366:	00093783          	ld	a5,0(s2)
    8000636a:	94be                	add	s1,s1,a5
    8000636c:	00c4d783          	lhu	a5,12(s1)
    80006370:	8b85                	andi	a5,a5,1
    80006372:	cf89                	beqz	a5,8000638c <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006374:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006378:	b7cd                	j	8000635a <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000637a:	0003f797          	auipc	a5,0x3f
    8000637e:	c867b783          	ld	a5,-890(a5) # 80045000 <disk+0x2000>
    80006382:	97ba                	add	a5,a5,a4
    80006384:	4689                	li	a3,2
    80006386:	00d79623          	sh	a3,12(a5)
    8000638a:	b5fd                	j	80006278 <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000638c:	0003f517          	auipc	a0,0x3f
    80006390:	d1c50513          	addi	a0,a0,-740 # 800450a8 <disk+0x20a8>
    80006394:	ffffb097          	auipc	ra,0xffffb
    80006398:	ac8080e7          	jalr	-1336(ra) # 80000e5c <release>
}
    8000639c:	70e6                	ld	ra,120(sp)
    8000639e:	7446                	ld	s0,112(sp)
    800063a0:	74a6                	ld	s1,104(sp)
    800063a2:	7906                	ld	s2,96(sp)
    800063a4:	69e6                	ld	s3,88(sp)
    800063a6:	6a46                	ld	s4,80(sp)
    800063a8:	6aa6                	ld	s5,72(sp)
    800063aa:	6b06                	ld	s6,64(sp)
    800063ac:	7be2                	ld	s7,56(sp)
    800063ae:	7c42                	ld	s8,48(sp)
    800063b0:	7ca2                	ld	s9,40(sp)
    800063b2:	7d02                	ld	s10,32(sp)
    800063b4:	6109                	addi	sp,sp,128
    800063b6:	8082                	ret
  if(write)
    800063b8:	e20d1ee3          	bnez	s10,800061f4 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800063bc:	f8042023          	sw	zero,-128(s0)
    800063c0:	bd2d                	j	800061fa <virtio_disk_rw+0xe2>

00000000800063c2 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063c2:	1101                	addi	sp,sp,-32
    800063c4:	ec06                	sd	ra,24(sp)
    800063c6:	e822                	sd	s0,16(sp)
    800063c8:	e426                	sd	s1,8(sp)
    800063ca:	e04a                	sd	s2,0(sp)
    800063cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ce:	0003f517          	auipc	a0,0x3f
    800063d2:	cda50513          	addi	a0,a0,-806 # 800450a8 <disk+0x20a8>
    800063d6:	ffffb097          	auipc	ra,0xffffb
    800063da:	9d2080e7          	jalr	-1582(ra) # 80000da8 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063de:	0003f717          	auipc	a4,0x3f
    800063e2:	c2270713          	addi	a4,a4,-990 # 80045000 <disk+0x2000>
    800063e6:	02075783          	lhu	a5,32(a4)
    800063ea:	6b18                	ld	a4,16(a4)
    800063ec:	00275683          	lhu	a3,2(a4)
    800063f0:	8ebd                	xor	a3,a3,a5
    800063f2:	8a9d                	andi	a3,a3,7
    800063f4:	cab9                	beqz	a3,8000644a <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063f6:	0003d917          	auipc	s2,0x3d
    800063fa:	c0a90913          	addi	s2,s2,-1014 # 80043000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063fe:	0003f497          	auipc	s1,0x3f
    80006402:	c0248493          	addi	s1,s1,-1022 # 80045000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006406:	078e                	slli	a5,a5,0x3
    80006408:	97ba                	add	a5,a5,a4
    8000640a:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    8000640c:	20078713          	addi	a4,a5,512
    80006410:	0712                	slli	a4,a4,0x4
    80006412:	974a                	add	a4,a4,s2
    80006414:	03074703          	lbu	a4,48(a4)
    80006418:	ef21                	bnez	a4,80006470 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000641a:	20078793          	addi	a5,a5,512
    8000641e:	0792                	slli	a5,a5,0x4
    80006420:	97ca                	add	a5,a5,s2
    80006422:	7798                	ld	a4,40(a5)
    80006424:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006428:	7788                	ld	a0,40(a5)
    8000642a:	ffffc097          	auipc	ra,0xffffc
    8000642e:	1e6080e7          	jalr	486(ra) # 80002610 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006432:	0204d783          	lhu	a5,32(s1)
    80006436:	2785                	addiw	a5,a5,1
    80006438:	8b9d                	andi	a5,a5,7
    8000643a:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000643e:	6898                	ld	a4,16(s1)
    80006440:	00275683          	lhu	a3,2(a4)
    80006444:	8a9d                	andi	a3,a3,7
    80006446:	fcf690e3          	bne	a3,a5,80006406 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000644a:	10001737          	lui	a4,0x10001
    8000644e:	533c                	lw	a5,96(a4)
    80006450:	8b8d                	andi	a5,a5,3
    80006452:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006454:	0003f517          	auipc	a0,0x3f
    80006458:	c5450513          	addi	a0,a0,-940 # 800450a8 <disk+0x20a8>
    8000645c:	ffffb097          	auipc	ra,0xffffb
    80006460:	a00080e7          	jalr	-1536(ra) # 80000e5c <release>
}
    80006464:	60e2                	ld	ra,24(sp)
    80006466:	6442                	ld	s0,16(sp)
    80006468:	64a2                	ld	s1,8(sp)
    8000646a:	6902                	ld	s2,0(sp)
    8000646c:	6105                	addi	sp,sp,32
    8000646e:	8082                	ret
      panic("virtio_disk_intr status");
    80006470:	00002517          	auipc	a0,0x2
    80006474:	3c050513          	addi	a0,a0,960 # 80008830 <syscalls+0x3d0>
    80006478:	ffffa097          	auipc	ra,0xffffa
    8000647c:	0de080e7          	jalr	222(ra) # 80000556 <panic>
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
