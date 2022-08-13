
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
    80000060:	c6478793          	addi	a5,a5,-924 # 80005cc0 <timervec>
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
    800000aa:	e3c78793          	addi	a5,a5,-452 # 80000ee2 <main>
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
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b28080e7          	jalr	-1240(ra) # 80000c34 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	3a8080e7          	jalr	936(ra) # 800024ce <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b9a080e7          	jalr	-1126(ra) # 80000ce8 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a96080e7          	jalr	-1386(ra) # 80000c34 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	834080e7          	jalr	-1996(ra) # 80001a02 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	038080e7          	jalr	56(ra) # 80002216 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	25e080e7          	jalr	606(ra) # 80002478 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	ab2080e7          	jalr	-1358(ra) # 80000ce8 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a9c080e7          	jalr	-1380(ra) # 80000ce8 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	956080e7          	jalr	-1706(ra) # 80000c34 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	228080e7          	jalr	552(ra) # 80002524 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9dc080e7          	jalr	-1572(ra) # 80000ce8 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	f4c080e7          	jalr	-180(ra) # 8000239c <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	732080e7          	jalr	1842(ra) # 80000ba4 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	62a080e7          	jalr	1578(ra) # 80000c34 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	57a080e7          	jalr	1402(ra) # 80000ce8 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	410080e7          	jalr	1040(ra) # 80000ba4 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	3ba080e7          	jalr	954(ra) # 80000ba4 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3e2080e7          	jalr	994(ra) # 80000be8 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	450080e7          	jalr	1104(ra) # 80000c88 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	ae6080e7          	jalr	-1306(ra) # 8000239c <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	33a080e7          	jalr	826(ra) # 80000c34 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	8c6080e7          	jalr	-1850(ra) # 80002216 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	354080e7          	jalr	852(ra) # 80000ce8 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	234080e7          	jalr	564(ra) # 80000c34 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2d6080e7          	jalr	726(ra) # 80000ce8 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2e0080e7          	jalr	736(ra) # 80000d30 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1d2080e7          	jalr	466(ra) # 80000c34 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	272080e7          	jalr	626(ra) # 80000ce8 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	0a8080e7          	jalr	168(ra) # 80000ba4 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	100080e7          	jalr	256(ra) # 80000c34 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	19c080e7          	jalr	412(ra) # 80000ce8 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1d6080e7          	jalr	470(ra) # 80000d30 <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	172080e7          	jalr	370(ra) # 80000ce8 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <free_mem>:

uint64 free_mem(void) 
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  struct run *r = kmem.freelist;
    80000b86:	00011797          	auipc	a5,0x11
    80000b8a:	dc27b783          	ld	a5,-574(a5) # 80011948 <kmem+0x18>
  uint64 n = 0;
  while (r) {
    80000b8e:	cb89                	beqz	a5,80000ba0 <free_mem+0x20>
  uint64 n = 0;
    80000b90:	4501                	li	a0,0
    n++;
    80000b92:	0505                	addi	a0,a0,1
	r = r->next;
    80000b94:	639c                	ld	a5,0(a5)
  while (r) {
    80000b96:	fff5                	bnez	a5,80000b92 <free_mem+0x12>
  }
  return n * PGSIZE;
}
    80000b98:	0532                	slli	a0,a0,0xc
    80000b9a:	6422                	ld	s0,8(sp)
    80000b9c:	0141                	addi	sp,sp,16
    80000b9e:	8082                	ret
  uint64 n = 0;
    80000ba0:	4501                	li	a0,0
    80000ba2:	bfdd                	j	80000b98 <free_mem+0x18>

0000000080000ba4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba4:	1141                	addi	sp,sp,-16
    80000ba6:	e422                	sd	s0,8(sp)
    80000ba8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000baa:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bac:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb0:	00053823          	sd	zero,16(a0)
}
    80000bb4:	6422                	ld	s0,8(sp)
    80000bb6:	0141                	addi	sp,sp,16
    80000bb8:	8082                	ret

0000000080000bba <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bba:	411c                	lw	a5,0(a0)
    80000bbc:	e399                	bnez	a5,80000bc2 <holding+0x8>
    80000bbe:	4501                	li	a0,0
  return r;
}
    80000bc0:	8082                	ret
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bcc:	6904                	ld	s1,16(a0)
    80000bce:	00001097          	auipc	ra,0x1
    80000bd2:	e18080e7          	jalr	-488(ra) # 800019e6 <mycpu>
    80000bd6:	40a48533          	sub	a0,s1,a0
    80000bda:	00153513          	seqz	a0,a0
}
    80000bde:	60e2                	ld	ra,24(sp)
    80000be0:	6442                	ld	s0,16(sp)
    80000be2:	64a2                	ld	s1,8(sp)
    80000be4:	6105                	addi	sp,sp,32
    80000be6:	8082                	ret

0000000080000be8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf2:	100024f3          	csrr	s1,sstatus
    80000bf6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bfc:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	de6080e7          	jalr	-538(ra) # 800019e6 <mycpu>
    80000c08:	5d3c                	lw	a5,120(a0)
    80000c0a:	cf89                	beqz	a5,80000c24 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c0c:	00001097          	auipc	ra,0x1
    80000c10:	dda080e7          	jalr	-550(ra) # 800019e6 <mycpu>
    80000c14:	5d3c                	lw	a5,120(a0)
    80000c16:	2785                	addiw	a5,a5,1
    80000c18:	dd3c                	sw	a5,120(a0)
}
    80000c1a:	60e2                	ld	ra,24(sp)
    80000c1c:	6442                	ld	s0,16(sp)
    80000c1e:	64a2                	ld	s1,8(sp)
    80000c20:	6105                	addi	sp,sp,32
    80000c22:	8082                	ret
    mycpu()->intena = old;
    80000c24:	00001097          	auipc	ra,0x1
    80000c28:	dc2080e7          	jalr	-574(ra) # 800019e6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c2c:	8085                	srli	s1,s1,0x1
    80000c2e:	8885                	andi	s1,s1,1
    80000c30:	dd64                	sw	s1,124(a0)
    80000c32:	bfe9                	j	80000c0c <push_off+0x24>

0000000080000c34 <acquire>:
{
    80000c34:	1101                	addi	sp,sp,-32
    80000c36:	ec06                	sd	ra,24(sp)
    80000c38:	e822                	sd	s0,16(sp)
    80000c3a:	e426                	sd	s1,8(sp)
    80000c3c:	1000                	addi	s0,sp,32
    80000c3e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c40:	00000097          	auipc	ra,0x0
    80000c44:	fa8080e7          	jalr	-88(ra) # 80000be8 <push_off>
  if(holding(lk))
    80000c48:	8526                	mv	a0,s1
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	f70080e7          	jalr	-144(ra) # 80000bba <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c52:	4705                	li	a4,1
  if(holding(lk))
    80000c54:	e115                	bnez	a0,80000c78 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	87ba                	mv	a5,a4
    80000c58:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c5c:	2781                	sext.w	a5,a5
    80000c5e:	ffe5                	bnez	a5,80000c56 <acquire+0x22>
  __sync_synchronize();
    80000c60:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c64:	00001097          	auipc	ra,0x1
    80000c68:	d82080e7          	jalr	-638(ra) # 800019e6 <mycpu>
    80000c6c:	e888                	sd	a0,16(s1)
}
    80000c6e:	60e2                	ld	ra,24(sp)
    80000c70:	6442                	ld	s0,16(sp)
    80000c72:	64a2                	ld	s1,8(sp)
    80000c74:	6105                	addi	sp,sp,32
    80000c76:	8082                	ret
    panic("acquire");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	3f850513          	addi	a0,a0,1016 # 80008070 <digits+0x30>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8c8080e7          	jalr	-1848(ra) # 80000548 <panic>

0000000080000c88 <pop_off>:

void
pop_off(void)
{
    80000c88:	1141                	addi	sp,sp,-16
    80000c8a:	e406                	sd	ra,8(sp)
    80000c8c:	e022                	sd	s0,0(sp)
    80000c8e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c90:	00001097          	auipc	ra,0x1
    80000c94:	d56080e7          	jalr	-682(ra) # 800019e6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c9c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c9e:	e78d                	bnez	a5,80000cc8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca0:	5d3c                	lw	a5,120(a0)
    80000ca2:	02f05b63          	blez	a5,80000cd8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ca6:	37fd                	addiw	a5,a5,-1
    80000ca8:	0007871b          	sext.w	a4,a5
    80000cac:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cae:	eb09                	bnez	a4,80000cc0 <pop_off+0x38>
    80000cb0:	5d7c                	lw	a5,124(a0)
    80000cb2:	c799                	beqz	a5,80000cc0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cb8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cbc:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc0:	60a2                	ld	ra,8(sp)
    80000cc2:	6402                	ld	s0,0(sp)
    80000cc4:	0141                	addi	sp,sp,16
    80000cc6:	8082                	ret
    panic("pop_off - interruptible");
    80000cc8:	00007517          	auipc	a0,0x7
    80000ccc:	3b050513          	addi	a0,a0,944 # 80008078 <digits+0x38>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	878080e7          	jalr	-1928(ra) # 80000548 <panic>
    panic("pop_off");
    80000cd8:	00007517          	auipc	a0,0x7
    80000cdc:	3b850513          	addi	a0,a0,952 # 80008090 <digits+0x50>
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	868080e7          	jalr	-1944(ra) # 80000548 <panic>

0000000080000ce8 <release>:
{
    80000ce8:	1101                	addi	sp,sp,-32
    80000cea:	ec06                	sd	ra,24(sp)
    80000cec:	e822                	sd	s0,16(sp)
    80000cee:	e426                	sd	s1,8(sp)
    80000cf0:	1000                	addi	s0,sp,32
    80000cf2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	ec6080e7          	jalr	-314(ra) # 80000bba <holding>
    80000cfc:	c115                	beqz	a0,80000d20 <release+0x38>
  lk->cpu = 0;
    80000cfe:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d02:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d06:	0f50000f          	fence	iorw,ow
    80000d0a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	f7a080e7          	jalr	-134(ra) # 80000c88 <pop_off>
}
    80000d16:	60e2                	ld	ra,24(sp)
    80000d18:	6442                	ld	s0,16(sp)
    80000d1a:	64a2                	ld	s1,8(sp)
    80000d1c:	6105                	addi	sp,sp,32
    80000d1e:	8082                	ret
    panic("release");
    80000d20:	00007517          	auipc	a0,0x7
    80000d24:	37850513          	addi	a0,a0,888 # 80008098 <digits+0x58>
    80000d28:	00000097          	auipc	ra,0x0
    80000d2c:	820080e7          	jalr	-2016(ra) # 80000548 <panic>

0000000080000d30 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d30:	1141                	addi	sp,sp,-16
    80000d32:	e422                	sd	s0,8(sp)
    80000d34:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d36:	ce09                	beqz	a2,80000d50 <memset+0x20>
    80000d38:	87aa                	mv	a5,a0
    80000d3a:	fff6071b          	addiw	a4,a2,-1
    80000d3e:	1702                	slli	a4,a4,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	0705                	addi	a4,a4,1
    80000d44:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	addi	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x16>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addiw	a3,a2,-1
    80000d62:	1682                	slli	a3,a3,0x20
    80000d64:	9281                	srli	a3,a3,0x20
    80000d66:	0685                	addi	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	addi	a0,a0,1
    80000d78:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d96:	00a5f963          	bgeu	a1,a0,80000da8 <memmove+0x18>
    80000d9a:	02061713          	slli	a4,a2,0x20
    80000d9e:	9301                	srli	a4,a4,0x20
    80000da0:	00e587b3          	add	a5,a1,a4
    80000da4:	02f56563          	bltu	a0,a5,80000dce <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000da8:	fff6069b          	addiw	a3,a2,-1
    80000dac:	ce11                	beqz	a2,80000dc8 <memmove+0x38>
    80000dae:	1682                	slli	a3,a3,0x20
    80000db0:	9281                	srli	a3,a3,0x20
    80000db2:	0685                	addi	a3,a3,1
    80000db4:	96ae                	add	a3,a3,a1
    80000db6:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000db8:	0585                	addi	a1,a1,1
    80000dba:	0785                	addi	a5,a5,1
    80000dbc:	fff5c703          	lbu	a4,-1(a1)
    80000dc0:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dc4:	fed59ae3          	bne	a1,a3,80000db8 <memmove+0x28>

  return dst;
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    d += n;
    80000dce:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dd0:	fff6069b          	addiw	a3,a2,-1
    80000dd4:	da75                	beqz	a2,80000dc8 <memmove+0x38>
    80000dd6:	02069613          	slli	a2,a3,0x20
    80000dda:	9201                	srli	a2,a2,0x20
    80000ddc:	fff64613          	not	a2,a2
    80000de0:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000de2:	17fd                	addi	a5,a5,-1
    80000de4:	177d                	addi	a4,a4,-1
    80000de6:	0007c683          	lbu	a3,0(a5)
    80000dea:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dee:	fec79ae3          	bne	a5,a2,80000de2 <memmove+0x52>
    80000df2:	bfd9                	j	80000dc8 <memmove+0x38>

0000000080000df4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e406                	sd	ra,8(sp)
    80000df8:	e022                	sd	s0,0(sp)
    80000dfa:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dfc:	00000097          	auipc	ra,0x0
    80000e00:	f94080e7          	jalr	-108(ra) # 80000d90 <memmove>
}
    80000e04:	60a2                	ld	ra,8(sp)
    80000e06:	6402                	ld	s0,0(sp)
    80000e08:	0141                	addi	sp,sp,16
    80000e0a:	8082                	ret

0000000080000e0c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e12:	ce11                	beqz	a2,80000e2e <strncmp+0x22>
    80000e14:	00054783          	lbu	a5,0(a0)
    80000e18:	cf89                	beqz	a5,80000e32 <strncmp+0x26>
    80000e1a:	0005c703          	lbu	a4,0(a1)
    80000e1e:	00f71a63          	bne	a4,a5,80000e32 <strncmp+0x26>
    n--, p++, q++;
    80000e22:	367d                	addiw	a2,a2,-1
    80000e24:	0505                	addi	a0,a0,1
    80000e26:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e28:	f675                	bnez	a2,80000e14 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e2a:	4501                	li	a0,0
    80000e2c:	a809                	j	80000e3e <strncmp+0x32>
    80000e2e:	4501                	li	a0,0
    80000e30:	a039                	j	80000e3e <strncmp+0x32>
  if(n == 0)
    80000e32:	ca09                	beqz	a2,80000e44 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e34:	00054503          	lbu	a0,0(a0)
    80000e38:	0005c783          	lbu	a5,0(a1)
    80000e3c:	9d1d                	subw	a0,a0,a5
}
    80000e3e:	6422                	ld	s0,8(sp)
    80000e40:	0141                	addi	sp,sp,16
    80000e42:	8082                	ret
    return 0;
    80000e44:	4501                	li	a0,0
    80000e46:	bfe5                	j	80000e3e <strncmp+0x32>

0000000080000e48 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e4e:	872a                	mv	a4,a0
    80000e50:	8832                	mv	a6,a2
    80000e52:	367d                	addiw	a2,a2,-1
    80000e54:	01005963          	blez	a6,80000e66 <strncpy+0x1e>
    80000e58:	0705                	addi	a4,a4,1
    80000e5a:	0005c783          	lbu	a5,0(a1)
    80000e5e:	fef70fa3          	sb	a5,-1(a4)
    80000e62:	0585                	addi	a1,a1,1
    80000e64:	f7f5                	bnez	a5,80000e50 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e66:	00c05d63          	blez	a2,80000e80 <strncpy+0x38>
    80000e6a:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e6c:	0685                	addi	a3,a3,1
    80000e6e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e72:	fff6c793          	not	a5,a3
    80000e76:	9fb9                	addw	a5,a5,a4
    80000e78:	010787bb          	addw	a5,a5,a6
    80000e7c:	fef048e3          	bgtz	a5,80000e6c <strncpy+0x24>
  return os;
}
    80000e80:	6422                	ld	s0,8(sp)
    80000e82:	0141                	addi	sp,sp,16
    80000e84:	8082                	ret

0000000080000e86 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e86:	1141                	addi	sp,sp,-16
    80000e88:	e422                	sd	s0,8(sp)
    80000e8a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e8c:	02c05363          	blez	a2,80000eb2 <safestrcpy+0x2c>
    80000e90:	fff6069b          	addiw	a3,a2,-1
    80000e94:	1682                	slli	a3,a3,0x20
    80000e96:	9281                	srli	a3,a3,0x20
    80000e98:	96ae                	add	a3,a3,a1
    80000e9a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e9c:	00d58963          	beq	a1,a3,80000eae <safestrcpy+0x28>
    80000ea0:	0585                	addi	a1,a1,1
    80000ea2:	0785                	addi	a5,a5,1
    80000ea4:	fff5c703          	lbu	a4,-1(a1)
    80000ea8:	fee78fa3          	sb	a4,-1(a5)
    80000eac:	fb65                	bnez	a4,80000e9c <safestrcpy+0x16>
    ;
  *s = 0;
    80000eae:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb2:	6422                	ld	s0,8(sp)
    80000eb4:	0141                	addi	sp,sp,16
    80000eb6:	8082                	ret

0000000080000eb8 <strlen>:

int
strlen(const char *s)
{
    80000eb8:	1141                	addi	sp,sp,-16
    80000eba:	e422                	sd	s0,8(sp)
    80000ebc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ebe:	00054783          	lbu	a5,0(a0)
    80000ec2:	cf91                	beqz	a5,80000ede <strlen+0x26>
    80000ec4:	0505                	addi	a0,a0,1
    80000ec6:	87aa                	mv	a5,a0
    80000ec8:	4685                	li	a3,1
    80000eca:	9e89                	subw	a3,a3,a0
    80000ecc:	00f6853b          	addw	a0,a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	fb7d                	bnez	a4,80000ecc <strlen+0x14>
    ;
  return n;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ede:	4501                	li	a0,0
    80000ee0:	bfe5                	j	80000ed8 <strlen+0x20>

0000000080000ee2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee2:	1141                	addi	sp,sp,-16
    80000ee4:	e406                	sd	ra,8(sp)
    80000ee6:	e022                	sd	s0,0(sp)
    80000ee8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	aec080e7          	jalr	-1300(ra) # 800019d6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef2:	00008717          	auipc	a4,0x8
    80000ef6:	11a70713          	addi	a4,a4,282 # 8000900c <started>
  if(cpuid() == 0){
    80000efa:	c139                	beqz	a0,80000f40 <main+0x5e>
    while(started == 0)
    80000efc:	431c                	lw	a5,0(a4)
    80000efe:	2781                	sext.w	a5,a5
    80000f00:	dff5                	beqz	a5,80000efc <main+0x1a>
      ;
    __sync_synchronize();
    80000f02:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f06:	00001097          	auipc	ra,0x1
    80000f0a:	ad0080e7          	jalr	-1328(ra) # 800019d6 <cpuid>
    80000f0e:	85aa                	mv	a1,a0
    80000f10:	00007517          	auipc	a0,0x7
    80000f14:	1a850513          	addi	a0,a0,424 # 800080b8 <digits+0x78>
    80000f18:	fffff097          	auipc	ra,0xfffff
    80000f1c:	67a080e7          	jalr	1658(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	0d8080e7          	jalr	216(ra) # 80000ff8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	76c080e7          	jalr	1900(ra) # 80002694 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f30:	00005097          	auipc	ra,0x5
    80000f34:	dd0080e7          	jalr	-560(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	002080e7          	jalr	2(ra) # 80001f3a <scheduler>
    consoleinit();
    80000f40:	fffff097          	auipc	ra,0xfffff
    80000f44:	51a080e7          	jalr	1306(ra) # 8000045a <consoleinit>
    printfinit();
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	830080e7          	jalr	-2000(ra) # 80000778 <printfinit>
    printf("\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	17850513          	addi	a0,a0,376 # 800080c8 <digits+0x88>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	63a080e7          	jalr	1594(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	14050513          	addi	a0,a0,320 # 800080a0 <digits+0x60>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	62a080e7          	jalr	1578(ra) # 80000592 <printf>
    printf("\n");
    80000f70:	00007517          	auipc	a0,0x7
    80000f74:	15850513          	addi	a0,a0,344 # 800080c8 <digits+0x88>
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	61a080e7          	jalr	1562(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	b64080e7          	jalr	-1180(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f88:	00000097          	auipc	ra,0x0
    80000f8c:	2a0080e7          	jalr	672(ra) # 80001228 <kvminit>
    kvminithart();   // turn on paging
    80000f90:	00000097          	auipc	ra,0x0
    80000f94:	068080e7          	jalr	104(ra) # 80000ff8 <kvminithart>
    procinit();      // process table
    80000f98:	00001097          	auipc	ra,0x1
    80000f9c:	96e080e7          	jalr	-1682(ra) # 80001906 <procinit>
    trapinit();      // trap vectors
    80000fa0:	00001097          	auipc	ra,0x1
    80000fa4:	6cc080e7          	jalr	1740(ra) # 8000266c <trapinit>
    trapinithart();  // install kernel trap vector
    80000fa8:	00001097          	auipc	ra,0x1
    80000fac:	6ec080e7          	jalr	1772(ra) # 80002694 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb0:	00005097          	auipc	ra,0x5
    80000fb4:	d3a080e7          	jalr	-710(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fb8:	00005097          	auipc	ra,0x5
    80000fbc:	d48080e7          	jalr	-696(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000fc0:	00002097          	auipc	ra,0x2
    80000fc4:	eea080e7          	jalr	-278(ra) # 80002eaa <binit>
    iinit();         // inode cache
    80000fc8:	00002097          	auipc	ra,0x2
    80000fcc:	57a080e7          	jalr	1402(ra) # 80003542 <iinit>
    fileinit();      // file table
    80000fd0:	00003097          	auipc	ra,0x3
    80000fd4:	514080e7          	jalr	1300(ra) # 800044e4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fd8:	00005097          	auipc	ra,0x5
    80000fdc:	e30080e7          	jalr	-464(ra) # 80005e08 <virtio_disk_init>
    userinit();      // first user process
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	cec080e7          	jalr	-788(ra) # 80001ccc <userinit>
    __sync_synchronize();
    80000fe8:	0ff0000f          	fence
    started = 1;
    80000fec:	4785                	li	a5,1
    80000fee:	00008717          	auipc	a4,0x8
    80000ff2:	00f72f23          	sw	a5,30(a4) # 8000900c <started>
    80000ff6:	b789                	j	80000f38 <main+0x56>

0000000080000ff8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000ff8:	1141                	addi	sp,sp,-16
    80000ffa:	e422                	sd	s0,8(sp)
    80000ffc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffe:	00008797          	auipc	a5,0x8
    80001002:	0127b783          	ld	a5,18(a5) # 80009010 <kernel_pagetable>
    80001006:	83b1                	srli	a5,a5,0xc
    80001008:	577d                	li	a4,-1
    8000100a:	177e                	slli	a4,a4,0x3f
    8000100c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001012:	12000073          	sfence.vma
  sfence_vma();
}
    80001016:	6422                	ld	s0,8(sp)
    80001018:	0141                	addi	sp,sp,16
    8000101a:	8082                	ret

000000008000101c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000101c:	7139                	addi	sp,sp,-64
    8000101e:	fc06                	sd	ra,56(sp)
    80001020:	f822                	sd	s0,48(sp)
    80001022:	f426                	sd	s1,40(sp)
    80001024:	f04a                	sd	s2,32(sp)
    80001026:	ec4e                	sd	s3,24(sp)
    80001028:	e852                	sd	s4,16(sp)
    8000102a:	e456                	sd	s5,8(sp)
    8000102c:	e05a                	sd	s6,0(sp)
    8000102e:	0080                	addi	s0,sp,64
    80001030:	84aa                	mv	s1,a0
    80001032:	89ae                	mv	s3,a1
    80001034:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001036:	57fd                	li	a5,-1
    80001038:	83e9                	srli	a5,a5,0x1a
    8000103a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000103c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000103e:	04b7f263          	bgeu	a5,a1,80001082 <walk+0x66>
    panic("walk");
    80001042:	00007517          	auipc	a0,0x7
    80001046:	08e50513          	addi	a0,a0,142 # 800080d0 <digits+0x90>
    8000104a:	fffff097          	auipc	ra,0xfffff
    8000104e:	4fe080e7          	jalr	1278(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001052:	060a8663          	beqz	s5,800010be <walk+0xa2>
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	aca080e7          	jalr	-1334(ra) # 80000b20 <kalloc>
    8000105e:	84aa                	mv	s1,a0
    80001060:	c529                	beqz	a0,800010aa <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001062:	6605                	lui	a2,0x1
    80001064:	4581                	li	a1,0
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	cca080e7          	jalr	-822(ra) # 80000d30 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000106e:	00c4d793          	srli	a5,s1,0xc
    80001072:	07aa                	slli	a5,a5,0xa
    80001074:	0017e793          	ori	a5,a5,1
    80001078:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000107c:	3a5d                	addiw	s4,s4,-9
    8000107e:	036a0063          	beq	s4,s6,8000109e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001082:	0149d933          	srl	s2,s3,s4
    80001086:	1ff97913          	andi	s2,s2,511
    8000108a:	090e                	slli	s2,s2,0x3
    8000108c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000108e:	00093483          	ld	s1,0(s2)
    80001092:	0014f793          	andi	a5,s1,1
    80001096:	dfd5                	beqz	a5,80001052 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001098:	80a9                	srli	s1,s1,0xa
    8000109a:	04b2                	slli	s1,s1,0xc
    8000109c:	b7c5                	j	8000107c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000109e:	00c9d513          	srli	a0,s3,0xc
    800010a2:	1ff57513          	andi	a0,a0,511
    800010a6:	050e                	slli	a0,a0,0x3
    800010a8:	9526                	add	a0,a0,s1
}
    800010aa:	70e2                	ld	ra,56(sp)
    800010ac:	7442                	ld	s0,48(sp)
    800010ae:	74a2                	ld	s1,40(sp)
    800010b0:	7902                	ld	s2,32(sp)
    800010b2:	69e2                	ld	s3,24(sp)
    800010b4:	6a42                	ld	s4,16(sp)
    800010b6:	6aa2                	ld	s5,8(sp)
    800010b8:	6b02                	ld	s6,0(sp)
    800010ba:	6121                	addi	sp,sp,64
    800010bc:	8082                	ret
        return 0;
    800010be:	4501                	li	a0,0
    800010c0:	b7ed                	j	800010aa <walk+0x8e>

00000000800010c2 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010c2:	57fd                	li	a5,-1
    800010c4:	83e9                	srli	a5,a5,0x1a
    800010c6:	00b7f463          	bgeu	a5,a1,800010ce <walkaddr+0xc>
    return 0;
    800010ca:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010cc:	8082                	ret
{
    800010ce:	1141                	addi	sp,sp,-16
    800010d0:	e406                	sd	ra,8(sp)
    800010d2:	e022                	sd	s0,0(sp)
    800010d4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d6:	4601                	li	a2,0
    800010d8:	00000097          	auipc	ra,0x0
    800010dc:	f44080e7          	jalr	-188(ra) # 8000101c <walk>
  if(pte == 0)
    800010e0:	c105                	beqz	a0,80001100 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010e2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010e4:	0117f693          	andi	a3,a5,17
    800010e8:	4745                	li	a4,17
    return 0;
    800010ea:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ec:	00e68663          	beq	a3,a4,800010f8 <walkaddr+0x36>
}
    800010f0:	60a2                	ld	ra,8(sp)
    800010f2:	6402                	ld	s0,0(sp)
    800010f4:	0141                	addi	sp,sp,16
    800010f6:	8082                	ret
  pa = PTE2PA(*pte);
    800010f8:	00a7d513          	srli	a0,a5,0xa
    800010fc:	0532                	slli	a0,a0,0xc
  return pa;
    800010fe:	bfcd                	j	800010f0 <walkaddr+0x2e>
    return 0;
    80001100:	4501                	li	a0,0
    80001102:	b7fd                	j	800010f0 <walkaddr+0x2e>

0000000080001104 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001104:	1101                	addi	sp,sp,-32
    80001106:	ec06                	sd	ra,24(sp)
    80001108:	e822                	sd	s0,16(sp)
    8000110a:	e426                	sd	s1,8(sp)
    8000110c:	1000                	addi	s0,sp,32
    8000110e:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001110:	1552                	slli	a0,a0,0x34
    80001112:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001116:	4601                	li	a2,0
    80001118:	00008517          	auipc	a0,0x8
    8000111c:	ef853503          	ld	a0,-264(a0) # 80009010 <kernel_pagetable>
    80001120:	00000097          	auipc	ra,0x0
    80001124:	efc080e7          	jalr	-260(ra) # 8000101c <walk>
  if(pte == 0)
    80001128:	cd09                	beqz	a0,80001142 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000112a:	6108                	ld	a0,0(a0)
    8000112c:	00157793          	andi	a5,a0,1
    80001130:	c38d                	beqz	a5,80001152 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001132:	8129                	srli	a0,a0,0xa
    80001134:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001136:	9526                	add	a0,a0,s1
    80001138:	60e2                	ld	ra,24(sp)
    8000113a:	6442                	ld	s0,16(sp)
    8000113c:	64a2                	ld	s1,8(sp)
    8000113e:	6105                	addi	sp,sp,32
    80001140:	8082                	ret
    panic("kvmpa");
    80001142:	00007517          	auipc	a0,0x7
    80001146:	f9650513          	addi	a0,a0,-106 # 800080d8 <digits+0x98>
    8000114a:	fffff097          	auipc	ra,0xfffff
    8000114e:	3fe080e7          	jalr	1022(ra) # 80000548 <panic>
    panic("kvmpa");
    80001152:	00007517          	auipc	a0,0x7
    80001156:	f8650513          	addi	a0,a0,-122 # 800080d8 <digits+0x98>
    8000115a:	fffff097          	auipc	ra,0xfffff
    8000115e:	3ee080e7          	jalr	1006(ra) # 80000548 <panic>

0000000080001162 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001162:	715d                	addi	sp,sp,-80
    80001164:	e486                	sd	ra,72(sp)
    80001166:	e0a2                	sd	s0,64(sp)
    80001168:	fc26                	sd	s1,56(sp)
    8000116a:	f84a                	sd	s2,48(sp)
    8000116c:	f44e                	sd	s3,40(sp)
    8000116e:	f052                	sd	s4,32(sp)
    80001170:	ec56                	sd	s5,24(sp)
    80001172:	e85a                	sd	s6,16(sp)
    80001174:	e45e                	sd	s7,8(sp)
    80001176:	0880                	addi	s0,sp,80
    80001178:	8aaa                	mv	s5,a0
    8000117a:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000117c:	777d                	lui	a4,0xfffff
    8000117e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001182:	167d                	addi	a2,a2,-1
    80001184:	00b609b3          	add	s3,a2,a1
    80001188:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000118c:	893e                	mv	s2,a5
    8000118e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001192:	6b85                	lui	s7,0x1
    80001194:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001198:	4605                	li	a2,1
    8000119a:	85ca                	mv	a1,s2
    8000119c:	8556                	mv	a0,s5
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	e7e080e7          	jalr	-386(ra) # 8000101c <walk>
    800011a6:	c51d                	beqz	a0,800011d4 <mappages+0x72>
    if(*pte & PTE_V)
    800011a8:	611c                	ld	a5,0(a0)
    800011aa:	8b85                	andi	a5,a5,1
    800011ac:	ef81                	bnez	a5,800011c4 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ae:	80b1                	srli	s1,s1,0xc
    800011b0:	04aa                	slli	s1,s1,0xa
    800011b2:	0164e4b3          	or	s1,s1,s6
    800011b6:	0014e493          	ori	s1,s1,1
    800011ba:	e104                	sd	s1,0(a0)
    if(a == last)
    800011bc:	03390863          	beq	s2,s3,800011ec <mappages+0x8a>
    a += PGSIZE;
    800011c0:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c2:	bfc9                	j	80001194 <mappages+0x32>
      panic("remap");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f1c50513          	addi	a0,a0,-228 # 800080e0 <digits+0xa0>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	37c080e7          	jalr	892(ra) # 80000548 <panic>
      return -1;
    800011d4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011d6:	60a6                	ld	ra,72(sp)
    800011d8:	6406                	ld	s0,64(sp)
    800011da:	74e2                	ld	s1,56(sp)
    800011dc:	7942                	ld	s2,48(sp)
    800011de:	79a2                	ld	s3,40(sp)
    800011e0:	7a02                	ld	s4,32(sp)
    800011e2:	6ae2                	ld	s5,24(sp)
    800011e4:	6b42                	ld	s6,16(sp)
    800011e6:	6ba2                	ld	s7,8(sp)
    800011e8:	6161                	addi	sp,sp,80
    800011ea:	8082                	ret
  return 0;
    800011ec:	4501                	li	a0,0
    800011ee:	b7e5                	j	800011d6 <mappages+0x74>

00000000800011f0 <kvmmap>:
{
    800011f0:	1141                	addi	sp,sp,-16
    800011f2:	e406                	sd	ra,8(sp)
    800011f4:	e022                	sd	s0,0(sp)
    800011f6:	0800                	addi	s0,sp,16
    800011f8:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011fa:	86ae                	mv	a3,a1
    800011fc:	85aa                	mv	a1,a0
    800011fe:	00008517          	auipc	a0,0x8
    80001202:	e1253503          	ld	a0,-494(a0) # 80009010 <kernel_pagetable>
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f5c080e7          	jalr	-164(ra) # 80001162 <mappages>
    8000120e:	e509                	bnez	a0,80001218 <kvmmap+0x28>
}
    80001210:	60a2                	ld	ra,8(sp)
    80001212:	6402                	ld	s0,0(sp)
    80001214:	0141                	addi	sp,sp,16
    80001216:	8082                	ret
    panic("kvmmap");
    80001218:	00007517          	auipc	a0,0x7
    8000121c:	ed050513          	addi	a0,a0,-304 # 800080e8 <digits+0xa8>
    80001220:	fffff097          	auipc	ra,0xfffff
    80001224:	328080e7          	jalr	808(ra) # 80000548 <panic>

0000000080001228 <kvminit>:
{
    80001228:	1101                	addi	sp,sp,-32
    8000122a:	ec06                	sd	ra,24(sp)
    8000122c:	e822                	sd	s0,16(sp)
    8000122e:	e426                	sd	s1,8(sp)
    80001230:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001232:	00000097          	auipc	ra,0x0
    80001236:	8ee080e7          	jalr	-1810(ra) # 80000b20 <kalloc>
    8000123a:	00008797          	auipc	a5,0x8
    8000123e:	dca7bb23          	sd	a0,-554(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001242:	6605                	lui	a2,0x1
    80001244:	4581                	li	a1,0
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	aea080e7          	jalr	-1302(ra) # 80000d30 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000124e:	4699                	li	a3,6
    80001250:	6605                	lui	a2,0x1
    80001252:	100005b7          	lui	a1,0x10000
    80001256:	10000537          	lui	a0,0x10000
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f96080e7          	jalr	-106(ra) # 800011f0 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001262:	4699                	li	a3,6
    80001264:	6605                	lui	a2,0x1
    80001266:	100015b7          	lui	a1,0x10001
    8000126a:	10001537          	lui	a0,0x10001
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f82080e7          	jalr	-126(ra) # 800011f0 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	6641                	lui	a2,0x10
    8000127a:	020005b7          	lui	a1,0x2000
    8000127e:	02000537          	lui	a0,0x2000
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f6e080e7          	jalr	-146(ra) # 800011f0 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000128a:	4699                	li	a3,6
    8000128c:	00400637          	lui	a2,0x400
    80001290:	0c0005b7          	lui	a1,0xc000
    80001294:	0c000537          	lui	a0,0xc000
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f58080e7          	jalr	-168(ra) # 800011f0 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012a0:	00007497          	auipc	s1,0x7
    800012a4:	d6048493          	addi	s1,s1,-672 # 80008000 <etext>
    800012a8:	46a9                	li	a3,10
    800012aa:	80007617          	auipc	a2,0x80007
    800012ae:	d5660613          	addi	a2,a2,-682 # 8000 <_entry-0x7fff8000>
    800012b2:	4585                	li	a1,1
    800012b4:	05fe                	slli	a1,a1,0x1f
    800012b6:	852e                	mv	a0,a1
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f38080e7          	jalr	-200(ra) # 800011f0 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012c0:	4699                	li	a3,6
    800012c2:	4645                	li	a2,17
    800012c4:	066e                	slli	a2,a2,0x1b
    800012c6:	8e05                	sub	a2,a2,s1
    800012c8:	85a6                	mv	a1,s1
    800012ca:	8526                	mv	a0,s1
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f24080e7          	jalr	-220(ra) # 800011f0 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d4:	46a9                	li	a3,10
    800012d6:	6605                	lui	a2,0x1
    800012d8:	00006597          	auipc	a1,0x6
    800012dc:	d2858593          	addi	a1,a1,-728 # 80007000 <_trampoline>
    800012e0:	04000537          	lui	a0,0x4000
    800012e4:	157d                	addi	a0,a0,-1
    800012e6:	0532                	slli	a0,a0,0xc
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f08080e7          	jalr	-248(ra) # 800011f0 <kvmmap>
}
    800012f0:	60e2                	ld	ra,24(sp)
    800012f2:	6442                	ld	s0,16(sp)
    800012f4:	64a2                	ld	s1,8(sp)
    800012f6:	6105                	addi	sp,sp,32
    800012f8:	8082                	ret

00000000800012fa <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012fa:	715d                	addi	sp,sp,-80
    800012fc:	e486                	sd	ra,72(sp)
    800012fe:	e0a2                	sd	s0,64(sp)
    80001300:	fc26                	sd	s1,56(sp)
    80001302:	f84a                	sd	s2,48(sp)
    80001304:	f44e                	sd	s3,40(sp)
    80001306:	f052                	sd	s4,32(sp)
    80001308:	ec56                	sd	s5,24(sp)
    8000130a:	e85a                	sd	s6,16(sp)
    8000130c:	e45e                	sd	s7,8(sp)
    8000130e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001310:	03459793          	slli	a5,a1,0x34
    80001314:	e795                	bnez	a5,80001340 <uvmunmap+0x46>
    80001316:	8a2a                	mv	s4,a0
    80001318:	892e                	mv	s2,a1
    8000131a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131c:	0632                	slli	a2,a2,0xc
    8000131e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001322:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001324:	6b05                	lui	s6,0x1
    80001326:	0735e863          	bltu	a1,s3,80001396 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000132a:	60a6                	ld	ra,72(sp)
    8000132c:	6406                	ld	s0,64(sp)
    8000132e:	74e2                	ld	s1,56(sp)
    80001330:	7942                	ld	s2,48(sp)
    80001332:	79a2                	ld	s3,40(sp)
    80001334:	7a02                	ld	s4,32(sp)
    80001336:	6ae2                	ld	s5,24(sp)
    80001338:	6b42                	ld	s6,16(sp)
    8000133a:	6ba2                	ld	s7,8(sp)
    8000133c:	6161                	addi	sp,sp,80
    8000133e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001340:	00007517          	auipc	a0,0x7
    80001344:	db050513          	addi	a0,a0,-592 # 800080f0 <digits+0xb0>
    80001348:	fffff097          	auipc	ra,0xfffff
    8000134c:	200080e7          	jalr	512(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001350:	00007517          	auipc	a0,0x7
    80001354:	db850513          	addi	a0,a0,-584 # 80008108 <digits+0xc8>
    80001358:	fffff097          	auipc	ra,0xfffff
    8000135c:	1f0080e7          	jalr	496(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001360:	00007517          	auipc	a0,0x7
    80001364:	db850513          	addi	a0,a0,-584 # 80008118 <digits+0xd8>
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	1e0080e7          	jalr	480(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001370:	00007517          	auipc	a0,0x7
    80001374:	dc050513          	addi	a0,a0,-576 # 80008130 <digits+0xf0>
    80001378:	fffff097          	auipc	ra,0xfffff
    8000137c:	1d0080e7          	jalr	464(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001380:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001382:	0532                	slli	a0,a0,0xc
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	6a0080e7          	jalr	1696(ra) # 80000a24 <kfree>
    *pte = 0;
    8000138c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001390:	995a                	add	s2,s2,s6
    80001392:	f9397ce3          	bgeu	s2,s3,8000132a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001396:	4601                	li	a2,0
    80001398:	85ca                	mv	a1,s2
    8000139a:	8552                	mv	a0,s4
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	c80080e7          	jalr	-896(ra) # 8000101c <walk>
    800013a4:	84aa                	mv	s1,a0
    800013a6:	d54d                	beqz	a0,80001350 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013a8:	6108                	ld	a0,0(a0)
    800013aa:	00157793          	andi	a5,a0,1
    800013ae:	dbcd                	beqz	a5,80001360 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013b0:	3ff57793          	andi	a5,a0,1023
    800013b4:	fb778ee3          	beq	a5,s7,80001370 <uvmunmap+0x76>
    if(do_free){
    800013b8:	fc0a8ae3          	beqz	s5,8000138c <uvmunmap+0x92>
    800013bc:	b7d1                	j	80001380 <uvmunmap+0x86>

00000000800013be <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	758080e7          	jalr	1880(ra) # 80000b20 <kalloc>
    800013d0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013d2:	c519                	beqz	a0,800013e0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013d4:	6605                	lui	a2,0x1
    800013d6:	4581                	li	a1,0
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	958080e7          	jalr	-1704(ra) # 80000d30 <memset>
  return pagetable;
}
    800013e0:	8526                	mv	a0,s1
    800013e2:	60e2                	ld	ra,24(sp)
    800013e4:	6442                	ld	s0,16(sp)
    800013e6:	64a2                	ld	s1,8(sp)
    800013e8:	6105                	addi	sp,sp,32
    800013ea:	8082                	ret

00000000800013ec <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ec:	7179                	addi	sp,sp,-48
    800013ee:	f406                	sd	ra,40(sp)
    800013f0:	f022                	sd	s0,32(sp)
    800013f2:	ec26                	sd	s1,24(sp)
    800013f4:	e84a                	sd	s2,16(sp)
    800013f6:	e44e                	sd	s3,8(sp)
    800013f8:	e052                	sd	s4,0(sp)
    800013fa:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013fc:	6785                	lui	a5,0x1
    800013fe:	04f67863          	bgeu	a2,a5,8000144e <uvminit+0x62>
    80001402:	8a2a                	mv	s4,a0
    80001404:	89ae                	mv	s3,a1
    80001406:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	718080e7          	jalr	1816(ra) # 80000b20 <kalloc>
    80001410:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	4581                	li	a1,0
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	91a080e7          	jalr	-1766(ra) # 80000d30 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000141e:	4779                	li	a4,30
    80001420:	86ca                	mv	a3,s2
    80001422:	6605                	lui	a2,0x1
    80001424:	4581                	li	a1,0
    80001426:	8552                	mv	a0,s4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	d3a080e7          	jalr	-710(ra) # 80001162 <mappages>
  memmove(mem, src, sz);
    80001430:	8626                	mv	a2,s1
    80001432:	85ce                	mv	a1,s3
    80001434:	854a                	mv	a0,s2
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	95a080e7          	jalr	-1702(ra) # 80000d90 <memmove>
}
    8000143e:	70a2                	ld	ra,40(sp)
    80001440:	7402                	ld	s0,32(sp)
    80001442:	64e2                	ld	s1,24(sp)
    80001444:	6942                	ld	s2,16(sp)
    80001446:	69a2                	ld	s3,8(sp)
    80001448:	6a02                	ld	s4,0(sp)
    8000144a:	6145                	addi	sp,sp,48
    8000144c:	8082                	ret
    panic("inituvm: more than a page");
    8000144e:	00007517          	auipc	a0,0x7
    80001452:	cfa50513          	addi	a0,a0,-774 # 80008148 <digits+0x108>
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	0f2080e7          	jalr	242(ra) # 80000548 <panic>

000000008000145e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000145e:	1101                	addi	sp,sp,-32
    80001460:	ec06                	sd	ra,24(sp)
    80001462:	e822                	sd	s0,16(sp)
    80001464:	e426                	sd	s1,8(sp)
    80001466:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001468:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000146a:	00b67d63          	bgeu	a2,a1,80001484 <uvmdealloc+0x26>
    8000146e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001470:	6785                	lui	a5,0x1
    80001472:	17fd                	addi	a5,a5,-1
    80001474:	00f60733          	add	a4,a2,a5
    80001478:	767d                	lui	a2,0xfffff
    8000147a:	8f71                	and	a4,a4,a2
    8000147c:	97ae                	add	a5,a5,a1
    8000147e:	8ff1                	and	a5,a5,a2
    80001480:	00f76863          	bltu	a4,a5,80001490 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001484:	8526                	mv	a0,s1
    80001486:	60e2                	ld	ra,24(sp)
    80001488:	6442                	ld	s0,16(sp)
    8000148a:	64a2                	ld	s1,8(sp)
    8000148c:	6105                	addi	sp,sp,32
    8000148e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001490:	8f99                	sub	a5,a5,a4
    80001492:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001494:	4685                	li	a3,1
    80001496:	0007861b          	sext.w	a2,a5
    8000149a:	85ba                	mv	a1,a4
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	e5e080e7          	jalr	-418(ra) # 800012fa <uvmunmap>
    800014a4:	b7c5                	j	80001484 <uvmdealloc+0x26>

00000000800014a6 <uvmalloc>:
  if(newsz < oldsz)
    800014a6:	0ab66163          	bltu	a2,a1,80001548 <uvmalloc+0xa2>
{
    800014aa:	7139                	addi	sp,sp,-64
    800014ac:	fc06                	sd	ra,56(sp)
    800014ae:	f822                	sd	s0,48(sp)
    800014b0:	f426                	sd	s1,40(sp)
    800014b2:	f04a                	sd	s2,32(sp)
    800014b4:	ec4e                	sd	s3,24(sp)
    800014b6:	e852                	sd	s4,16(sp)
    800014b8:	e456                	sd	s5,8(sp)
    800014ba:	0080                	addi	s0,sp,64
    800014bc:	8aaa                	mv	s5,a0
    800014be:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014c0:	6985                	lui	s3,0x1
    800014c2:	19fd                	addi	s3,s3,-1
    800014c4:	95ce                	add	a1,a1,s3
    800014c6:	79fd                	lui	s3,0xfffff
    800014c8:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014cc:	08c9f063          	bgeu	s3,a2,8000154c <uvmalloc+0xa6>
    800014d0:	894e                	mv	s2,s3
    mem = kalloc();
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	64e080e7          	jalr	1614(ra) # 80000b20 <kalloc>
    800014da:	84aa                	mv	s1,a0
    if(mem == 0){
    800014dc:	c51d                	beqz	a0,8000150a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014de:	6605                	lui	a2,0x1
    800014e0:	4581                	li	a1,0
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	84e080e7          	jalr	-1970(ra) # 80000d30 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014ea:	4779                	li	a4,30
    800014ec:	86a6                	mv	a3,s1
    800014ee:	6605                	lui	a2,0x1
    800014f0:	85ca                	mv	a1,s2
    800014f2:	8556                	mv	a0,s5
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	c6e080e7          	jalr	-914(ra) # 80001162 <mappages>
    800014fc:	e905                	bnez	a0,8000152c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fe:	6785                	lui	a5,0x1
    80001500:	993e                	add	s2,s2,a5
    80001502:	fd4968e3          	bltu	s2,s4,800014d2 <uvmalloc+0x2c>
  return newsz;
    80001506:	8552                	mv	a0,s4
    80001508:	a809                	j	8000151a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000150a:	864e                	mv	a2,s3
    8000150c:	85ca                	mv	a1,s2
    8000150e:	8556                	mv	a0,s5
    80001510:	00000097          	auipc	ra,0x0
    80001514:	f4e080e7          	jalr	-178(ra) # 8000145e <uvmdealloc>
      return 0;
    80001518:	4501                	li	a0,0
}
    8000151a:	70e2                	ld	ra,56(sp)
    8000151c:	7442                	ld	s0,48(sp)
    8000151e:	74a2                	ld	s1,40(sp)
    80001520:	7902                	ld	s2,32(sp)
    80001522:	69e2                	ld	s3,24(sp)
    80001524:	6a42                	ld	s4,16(sp)
    80001526:	6aa2                	ld	s5,8(sp)
    80001528:	6121                	addi	sp,sp,64
    8000152a:	8082                	ret
      kfree(mem);
    8000152c:	8526                	mv	a0,s1
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	4f6080e7          	jalr	1270(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001536:	864e                	mv	a2,s3
    80001538:	85ca                	mv	a1,s2
    8000153a:	8556                	mv	a0,s5
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f22080e7          	jalr	-222(ra) # 8000145e <uvmdealloc>
      return 0;
    80001544:	4501                	li	a0,0
    80001546:	bfd1                	j	8000151a <uvmalloc+0x74>
    return oldsz;
    80001548:	852e                	mv	a0,a1
}
    8000154a:	8082                	ret
  return newsz;
    8000154c:	8532                	mv	a0,a2
    8000154e:	b7f1                	j	8000151a <uvmalloc+0x74>

0000000080001550 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001550:	7179                	addi	sp,sp,-48
    80001552:	f406                	sd	ra,40(sp)
    80001554:	f022                	sd	s0,32(sp)
    80001556:	ec26                	sd	s1,24(sp)
    80001558:	e84a                	sd	s2,16(sp)
    8000155a:	e44e                	sd	s3,8(sp)
    8000155c:	e052                	sd	s4,0(sp)
    8000155e:	1800                	addi	s0,sp,48
    80001560:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001562:	84aa                	mv	s1,a0
    80001564:	6905                	lui	s2,0x1
    80001566:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001568:	4985                	li	s3,1
    8000156a:	a821                	j	80001582 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000156c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000156e:	0532                	slli	a0,a0,0xc
    80001570:	00000097          	auipc	ra,0x0
    80001574:	fe0080e7          	jalr	-32(ra) # 80001550 <freewalk>
      pagetable[i] = 0;
    80001578:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000157c:	04a1                	addi	s1,s1,8
    8000157e:	03248163          	beq	s1,s2,800015a0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001582:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001584:	00f57793          	andi	a5,a0,15
    80001588:	ff3782e3          	beq	a5,s3,8000156c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000158c:	8905                	andi	a0,a0,1
    8000158e:	d57d                	beqz	a0,8000157c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001590:	00007517          	auipc	a0,0x7
    80001594:	bd850513          	addi	a0,a0,-1064 # 80008168 <digits+0x128>
    80001598:	fffff097          	auipc	ra,0xfffff
    8000159c:	fb0080e7          	jalr	-80(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015a0:	8552                	mv	a0,s4
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	482080e7          	jalr	1154(ra) # 80000a24 <kfree>
}
    800015aa:	70a2                	ld	ra,40(sp)
    800015ac:	7402                	ld	s0,32(sp)
    800015ae:	64e2                	ld	s1,24(sp)
    800015b0:	6942                	ld	s2,16(sp)
    800015b2:	69a2                	ld	s3,8(sp)
    800015b4:	6a02                	ld	s4,0(sp)
    800015b6:	6145                	addi	sp,sp,48
    800015b8:	8082                	ret

00000000800015ba <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015ba:	1101                	addi	sp,sp,-32
    800015bc:	ec06                	sd	ra,24(sp)
    800015be:	e822                	sd	s0,16(sp)
    800015c0:	e426                	sd	s1,8(sp)
    800015c2:	1000                	addi	s0,sp,32
    800015c4:	84aa                	mv	s1,a0
  if(sz > 0)
    800015c6:	e999                	bnez	a1,800015dc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015c8:	8526                	mv	a0,s1
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	f86080e7          	jalr	-122(ra) # 80001550 <freewalk>
}
    800015d2:	60e2                	ld	ra,24(sp)
    800015d4:	6442                	ld	s0,16(sp)
    800015d6:	64a2                	ld	s1,8(sp)
    800015d8:	6105                	addi	sp,sp,32
    800015da:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015dc:	6605                	lui	a2,0x1
    800015de:	167d                	addi	a2,a2,-1
    800015e0:	962e                	add	a2,a2,a1
    800015e2:	4685                	li	a3,1
    800015e4:	8231                	srli	a2,a2,0xc
    800015e6:	4581                	li	a1,0
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	d12080e7          	jalr	-750(ra) # 800012fa <uvmunmap>
    800015f0:	bfe1                	j	800015c8 <uvmfree+0xe>

00000000800015f2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015f2:	c679                	beqz	a2,800016c0 <uvmcopy+0xce>
{
    800015f4:	715d                	addi	sp,sp,-80
    800015f6:	e486                	sd	ra,72(sp)
    800015f8:	e0a2                	sd	s0,64(sp)
    800015fa:	fc26                	sd	s1,56(sp)
    800015fc:	f84a                	sd	s2,48(sp)
    800015fe:	f44e                	sd	s3,40(sp)
    80001600:	f052                	sd	s4,32(sp)
    80001602:	ec56                	sd	s5,24(sp)
    80001604:	e85a                	sd	s6,16(sp)
    80001606:	e45e                	sd	s7,8(sp)
    80001608:	0880                	addi	s0,sp,80
    8000160a:	8b2a                	mv	s6,a0
    8000160c:	8aae                	mv	s5,a1
    8000160e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001610:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001612:	4601                	li	a2,0
    80001614:	85ce                	mv	a1,s3
    80001616:	855a                	mv	a0,s6
    80001618:	00000097          	auipc	ra,0x0
    8000161c:	a04080e7          	jalr	-1532(ra) # 8000101c <walk>
    80001620:	c531                	beqz	a0,8000166c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001622:	6118                	ld	a4,0(a0)
    80001624:	00177793          	andi	a5,a4,1
    80001628:	cbb1                	beqz	a5,8000167c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000162a:	00a75593          	srli	a1,a4,0xa
    8000162e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001632:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	4ea080e7          	jalr	1258(ra) # 80000b20 <kalloc>
    8000163e:	892a                	mv	s2,a0
    80001640:	c939                	beqz	a0,80001696 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001642:	6605                	lui	a2,0x1
    80001644:	85de                	mv	a1,s7
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	74a080e7          	jalr	1866(ra) # 80000d90 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000164e:	8726                	mv	a4,s1
    80001650:	86ca                	mv	a3,s2
    80001652:	6605                	lui	a2,0x1
    80001654:	85ce                	mv	a1,s3
    80001656:	8556                	mv	a0,s5
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	b0a080e7          	jalr	-1270(ra) # 80001162 <mappages>
    80001660:	e515                	bnez	a0,8000168c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001662:	6785                	lui	a5,0x1
    80001664:	99be                	add	s3,s3,a5
    80001666:	fb49e6e3          	bltu	s3,s4,80001612 <uvmcopy+0x20>
    8000166a:	a081                	j	800016aa <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000166c:	00007517          	auipc	a0,0x7
    80001670:	b0c50513          	addi	a0,a0,-1268 # 80008178 <digits+0x138>
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	ed4080e7          	jalr	-300(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000167c:	00007517          	auipc	a0,0x7
    80001680:	b1c50513          	addi	a0,a0,-1252 # 80008198 <digits+0x158>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	ec4080e7          	jalr	-316(ra) # 80000548 <panic>
      kfree(mem);
    8000168c:	854a                	mv	a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	396080e7          	jalr	918(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001696:	4685                	li	a3,1
    80001698:	00c9d613          	srli	a2,s3,0xc
    8000169c:	4581                	li	a1,0
    8000169e:	8556                	mv	a0,s5
    800016a0:	00000097          	auipc	ra,0x0
    800016a4:	c5a080e7          	jalr	-934(ra) # 800012fa <uvmunmap>
  return -1;
    800016a8:	557d                	li	a0,-1
}
    800016aa:	60a6                	ld	ra,72(sp)
    800016ac:	6406                	ld	s0,64(sp)
    800016ae:	74e2                	ld	s1,56(sp)
    800016b0:	7942                	ld	s2,48(sp)
    800016b2:	79a2                	ld	s3,40(sp)
    800016b4:	7a02                	ld	s4,32(sp)
    800016b6:	6ae2                	ld	s5,24(sp)
    800016b8:	6b42                	ld	s6,16(sp)
    800016ba:	6ba2                	ld	s7,8(sp)
    800016bc:	6161                	addi	sp,sp,80
    800016be:	8082                	ret
  return 0;
    800016c0:	4501                	li	a0,0
}
    800016c2:	8082                	ret

00000000800016c4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016c4:	1141                	addi	sp,sp,-16
    800016c6:	e406                	sd	ra,8(sp)
    800016c8:	e022                	sd	s0,0(sp)
    800016ca:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016cc:	4601                	li	a2,0
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	94e080e7          	jalr	-1714(ra) # 8000101c <walk>
  if(pte == 0)
    800016d6:	c901                	beqz	a0,800016e6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016d8:	611c                	ld	a5,0(a0)
    800016da:	9bbd                	andi	a5,a5,-17
    800016dc:	e11c                	sd	a5,0(a0)
}
    800016de:	60a2                	ld	ra,8(sp)
    800016e0:	6402                	ld	s0,0(sp)
    800016e2:	0141                	addi	sp,sp,16
    800016e4:	8082                	ret
    panic("uvmclear");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	ad250513          	addi	a0,a0,-1326 # 800081b8 <digits+0x178>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e5a080e7          	jalr	-422(ra) # 80000548 <panic>

00000000800016f6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f6:	c6bd                	beqz	a3,80001764 <copyout+0x6e>
{
    800016f8:	715d                	addi	sp,sp,-80
    800016fa:	e486                	sd	ra,72(sp)
    800016fc:	e0a2                	sd	s0,64(sp)
    800016fe:	fc26                	sd	s1,56(sp)
    80001700:	f84a                	sd	s2,48(sp)
    80001702:	f44e                	sd	s3,40(sp)
    80001704:	f052                	sd	s4,32(sp)
    80001706:	ec56                	sd	s5,24(sp)
    80001708:	e85a                	sd	s6,16(sp)
    8000170a:	e45e                	sd	s7,8(sp)
    8000170c:	e062                	sd	s8,0(sp)
    8000170e:	0880                	addi	s0,sp,80
    80001710:	8b2a                	mv	s6,a0
    80001712:	8c2e                	mv	s8,a1
    80001714:	8a32                	mv	s4,a2
    80001716:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001718:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000171a:	6a85                	lui	s5,0x1
    8000171c:	a015                	j	80001740 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000171e:	9562                	add	a0,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	85d2                	mv	a1,s4
    80001726:	41250533          	sub	a0,a0,s2
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	666080e7          	jalr	1638(ra) # 80000d90 <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    src += n;
    80001736:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	97a080e7          	jalr	-1670(ra) # 800010c2 <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f3e3          	bgeu	s3,s1,8000171e <copyout+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	b7c1                	j	8000171e <copyout+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyout+0x74>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001782:	c6bd                	beqz	a3,800017f0 <copyin+0x6e>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	e062                	sd	s8,0(sp)
    8000179a:	0880                	addi	s0,sp,80
    8000179c:	8b2a                	mv	s6,a0
    8000179e:	8a2e                	mv	s4,a1
    800017a0:	8c32                	mv	s8,a2
    800017a2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017a4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a6:	6a85                	lui	s5,0x1
    800017a8:	a015                	j	800017cc <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017aa:	9562                	add	a0,a0,s8
    800017ac:	0004861b          	sext.w	a2,s1
    800017b0:	412505b3          	sub	a1,a0,s2
    800017b4:	8552                	mv	a0,s4
    800017b6:	fffff097          	auipc	ra,0xfffff
    800017ba:	5da080e7          	jalr	1498(ra) # 80000d90 <memmove>

    len -= n;
    800017be:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017c2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017c4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017c8:	02098263          	beqz	s3,800017ec <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017cc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017d0:	85ca                	mv	a1,s2
    800017d2:	855a                	mv	a0,s6
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	8ee080e7          	jalr	-1810(ra) # 800010c2 <walkaddr>
    if(pa0 == 0)
    800017dc:	cd01                	beqz	a0,800017f4 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017de:	418904b3          	sub	s1,s2,s8
    800017e2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017e4:	fc99f3e3          	bgeu	s3,s1,800017aa <copyin+0x28>
    800017e8:	84ce                	mv	s1,s3
    800017ea:	b7c1                	j	800017aa <copyin+0x28>
  }
  return 0;
    800017ec:	4501                	li	a0,0
    800017ee:	a021                	j	800017f6 <copyin+0x74>
    800017f0:	4501                	li	a0,0
}
    800017f2:	8082                	ret
      return -1;
    800017f4:	557d                	li	a0,-1
}
    800017f6:	60a6                	ld	ra,72(sp)
    800017f8:	6406                	ld	s0,64(sp)
    800017fa:	74e2                	ld	s1,56(sp)
    800017fc:	7942                	ld	s2,48(sp)
    800017fe:	79a2                	ld	s3,40(sp)
    80001800:	7a02                	ld	s4,32(sp)
    80001802:	6ae2                	ld	s5,24(sp)
    80001804:	6b42                	ld	s6,16(sp)
    80001806:	6ba2                	ld	s7,8(sp)
    80001808:	6c02                	ld	s8,0(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret

000000008000180e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000180e:	c6c5                	beqz	a3,800018b6 <copyinstr+0xa8>
{
    80001810:	715d                	addi	sp,sp,-80
    80001812:	e486                	sd	ra,72(sp)
    80001814:	e0a2                	sd	s0,64(sp)
    80001816:	fc26                	sd	s1,56(sp)
    80001818:	f84a                	sd	s2,48(sp)
    8000181a:	f44e                	sd	s3,40(sp)
    8000181c:	f052                	sd	s4,32(sp)
    8000181e:	ec56                	sd	s5,24(sp)
    80001820:	e85a                	sd	s6,16(sp)
    80001822:	e45e                	sd	s7,8(sp)
    80001824:	0880                	addi	s0,sp,80
    80001826:	8a2a                	mv	s4,a0
    80001828:	8b2e                	mv	s6,a1
    8000182a:	8bb2                	mv	s7,a2
    8000182c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000182e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001830:	6985                	lui	s3,0x1
    80001832:	a035                	j	8000185e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001834:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001838:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000183a:	0017b793          	seqz	a5,a5
    8000183e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001842:	60a6                	ld	ra,72(sp)
    80001844:	6406                	ld	s0,64(sp)
    80001846:	74e2                	ld	s1,56(sp)
    80001848:	7942                	ld	s2,48(sp)
    8000184a:	79a2                	ld	s3,40(sp)
    8000184c:	7a02                	ld	s4,32(sp)
    8000184e:	6ae2                	ld	s5,24(sp)
    80001850:	6b42                	ld	s6,16(sp)
    80001852:	6ba2                	ld	s7,8(sp)
    80001854:	6161                	addi	sp,sp,80
    80001856:	8082                	ret
    srcva = va0 + PGSIZE;
    80001858:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000185c:	c8a9                	beqz	s1,800018ae <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000185e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001862:	85ca                	mv	a1,s2
    80001864:	8552                	mv	a0,s4
    80001866:	00000097          	auipc	ra,0x0
    8000186a:	85c080e7          	jalr	-1956(ra) # 800010c2 <walkaddr>
    if(pa0 == 0)
    8000186e:	c131                	beqz	a0,800018b2 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001870:	41790833          	sub	a6,s2,s7
    80001874:	984e                	add	a6,a6,s3
    if(n > max)
    80001876:	0104f363          	bgeu	s1,a6,8000187c <copyinstr+0x6e>
    8000187a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000187c:	955e                	add	a0,a0,s7
    8000187e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001882:	fc080be3          	beqz	a6,80001858 <copyinstr+0x4a>
    80001886:	985a                	add	a6,a6,s6
    80001888:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000188a:	41650633          	sub	a2,a0,s6
    8000188e:	14fd                	addi	s1,s1,-1
    80001890:	9b26                	add	s6,s6,s1
    80001892:	00f60733          	add	a4,a2,a5
    80001896:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    8000189a:	df49                	beqz	a4,80001834 <copyinstr+0x26>
        *dst = *p;
    8000189c:	00e78023          	sb	a4,0(a5)
      --max;
    800018a0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018a4:	0785                	addi	a5,a5,1
    while(n > 0){
    800018a6:	ff0796e3          	bne	a5,a6,80001892 <copyinstr+0x84>
      dst++;
    800018aa:	8b42                	mv	s6,a6
    800018ac:	b775                	j	80001858 <copyinstr+0x4a>
    800018ae:	4781                	li	a5,0
    800018b0:	b769                	j	8000183a <copyinstr+0x2c>
      return -1;
    800018b2:	557d                	li	a0,-1
    800018b4:	b779                	j	80001842 <copyinstr+0x34>
  int got_null = 0;
    800018b6:	4781                	li	a5,0
  if(got_null){
    800018b8:	0017b793          	seqz	a5,a5
    800018bc:	40f00533          	neg	a0,a5
}
    800018c0:	8082                	ret

00000000800018c2 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018c2:	1101                	addi	sp,sp,-32
    800018c4:	ec06                	sd	ra,24(sp)
    800018c6:	e822                	sd	s0,16(sp)
    800018c8:	e426                	sd	s1,8(sp)
    800018ca:	1000                	addi	s0,sp,32
    800018cc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	2ec080e7          	jalr	748(ra) # 80000bba <holding>
    800018d6:	c909                	beqz	a0,800018e8 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018d8:	749c                	ld	a5,40(s1)
    800018da:	00978f63          	beq	a5,s1,800018f8 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018de:	60e2                	ld	ra,24(sp)
    800018e0:	6442                	ld	s0,16(sp)
    800018e2:	64a2                	ld	s1,8(sp)
    800018e4:	6105                	addi	sp,sp,32
    800018e6:	8082                	ret
    panic("wakeup1");
    800018e8:	00007517          	auipc	a0,0x7
    800018ec:	8e050513          	addi	a0,a0,-1824 # 800081c8 <digits+0x188>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	c58080e7          	jalr	-936(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018f8:	4c98                	lw	a4,24(s1)
    800018fa:	4785                	li	a5,1
    800018fc:	fef711e3          	bne	a4,a5,800018de <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001900:	4789                	li	a5,2
    80001902:	cc9c                	sw	a5,24(s1)
}
    80001904:	bfe9                	j	800018de <wakeup1+0x1c>

0000000080001906 <procinit>:
{
    80001906:	715d                	addi	sp,sp,-80
    80001908:	e486                	sd	ra,72(sp)
    8000190a:	e0a2                	sd	s0,64(sp)
    8000190c:	fc26                	sd	s1,56(sp)
    8000190e:	f84a                	sd	s2,48(sp)
    80001910:	f44e                	sd	s3,40(sp)
    80001912:	f052                	sd	s4,32(sp)
    80001914:	ec56                	sd	s5,24(sp)
    80001916:	e85a                	sd	s6,16(sp)
    80001918:	e45e                	sd	s7,8(sp)
    8000191a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000191c:	00007597          	auipc	a1,0x7
    80001920:	8b458593          	addi	a1,a1,-1868 # 800081d0 <digits+0x190>
    80001924:	00010517          	auipc	a0,0x10
    80001928:	02c50513          	addi	a0,a0,44 # 80011950 <pid_lock>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	278080e7          	jalr	632(ra) # 80000ba4 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001934:	00010917          	auipc	s2,0x10
    80001938:	43490913          	addi	s2,s2,1076 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000193c:	00007b97          	auipc	s7,0x7
    80001940:	89cb8b93          	addi	s7,s7,-1892 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001944:	8b4a                	mv	s6,s2
    80001946:	00006a97          	auipc	s5,0x6
    8000194a:	6baa8a93          	addi	s5,s5,1722 # 80008000 <etext>
    8000194e:	040009b7          	lui	s3,0x4000
    80001952:	19fd                	addi	s3,s3,-1
    80001954:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001956:	00016a17          	auipc	s4,0x16
    8000195a:	012a0a13          	addi	s4,s4,18 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    8000195e:	85de                	mv	a1,s7
    80001960:	854a                	mv	a0,s2
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	242080e7          	jalr	578(ra) # 80000ba4 <initlock>
      char *pa = kalloc();
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	1b6080e7          	jalr	438(ra) # 80000b20 <kalloc>
    80001972:	85aa                	mv	a1,a0
      if(pa == 0)
    80001974:	c929                	beqz	a0,800019c6 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001976:	416904b3          	sub	s1,s2,s6
    8000197a:	8491                	srai	s1,s1,0x4
    8000197c:	000ab783          	ld	a5,0(s5)
    80001980:	02f484b3          	mul	s1,s1,a5
    80001984:	2485                	addiw	s1,s1,1
    80001986:	00d4949b          	slliw	s1,s1,0xd
    8000198a:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000198e:	4699                	li	a3,6
    80001990:	6605                	lui	a2,0x1
    80001992:	8526                	mv	a0,s1
    80001994:	00000097          	auipc	ra,0x0
    80001998:	85c080e7          	jalr	-1956(ra) # 800011f0 <kvmmap>
      p->kstack = va;
    8000199c:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	17090913          	addi	s2,s2,368
    800019a4:	fb491de3          	bne	s2,s4,8000195e <procinit+0x58>
  kvminithart();
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	650080e7          	jalr	1616(ra) # 80000ff8 <kvminithart>
}
    800019b0:	60a6                	ld	ra,72(sp)
    800019b2:	6406                	ld	s0,64(sp)
    800019b4:	74e2                	ld	s1,56(sp)
    800019b6:	7942                	ld	s2,48(sp)
    800019b8:	79a2                	ld	s3,40(sp)
    800019ba:	7a02                	ld	s4,32(sp)
    800019bc:	6ae2                	ld	s5,24(sp)
    800019be:	6b42                	ld	s6,16(sp)
    800019c0:	6ba2                	ld	s7,8(sp)
    800019c2:	6161                	addi	sp,sp,80
    800019c4:	8082                	ret
        panic("kalloc");
    800019c6:	00007517          	auipc	a0,0x7
    800019ca:	81a50513          	addi	a0,a0,-2022 # 800081e0 <digits+0x1a0>
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	b7a080e7          	jalr	-1158(ra) # 80000548 <panic>

00000000800019d6 <cpuid>:
{
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019dc:	8512                	mv	a0,tp
}
    800019de:	2501                	sext.w	a0,a0
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <mycpu>:
mycpu(void) {
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
    800019ec:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ee:	2781                	sext.w	a5,a5
    800019f0:	079e                	slli	a5,a5,0x7
}
    800019f2:	00010517          	auipc	a0,0x10
    800019f6:	f7650513          	addi	a0,a0,-138 # 80011968 <cpus>
    800019fa:	953e                	add	a0,a0,a5
    800019fc:	6422                	ld	s0,8(sp)
    800019fe:	0141                	addi	sp,sp,16
    80001a00:	8082                	ret

0000000080001a02 <myproc>:
myproc(void) {
    80001a02:	1101                	addi	sp,sp,-32
    80001a04:	ec06                	sd	ra,24(sp)
    80001a06:	e822                	sd	s0,16(sp)
    80001a08:	e426                	sd	s1,8(sp)
    80001a0a:	1000                	addi	s0,sp,32
  push_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	1dc080e7          	jalr	476(ra) # 80000be8 <push_off>
    80001a14:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	slli	a5,a5,0x7
    80001a1a:	00010717          	auipc	a4,0x10
    80001a1e:	f3670713          	addi	a4,a4,-202 # 80011950 <pid_lock>
    80001a22:	97ba                	add	a5,a5,a4
    80001a24:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	262080e7          	jalr	610(ra) # 80000c88 <pop_off>
}
    80001a2e:	8526                	mv	a0,s1
    80001a30:	60e2                	ld	ra,24(sp)
    80001a32:	6442                	ld	s0,16(sp)
    80001a34:	64a2                	ld	s1,8(sp)
    80001a36:	6105                	addi	sp,sp,32
    80001a38:	8082                	ret

0000000080001a3a <forkret>:
{
    80001a3a:	1141                	addi	sp,sp,-16
    80001a3c:	e406                	sd	ra,8(sp)
    80001a3e:	e022                	sd	s0,0(sp)
    80001a40:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	fc0080e7          	jalr	-64(ra) # 80001a02 <myproc>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	29e080e7          	jalr	670(ra) # 80000ce8 <release>
  if (first) {
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	e9e7a783          	lw	a5,-354(a5) # 800088f0 <first.1667>
    80001a5a:	eb89                	bnez	a5,80001a6c <forkret+0x32>
  usertrapret();
    80001a5c:	00001097          	auipc	ra,0x1
    80001a60:	c50080e7          	jalr	-944(ra) # 800026ac <usertrapret>
}
    80001a64:	60a2                	ld	ra,8(sp)
    80001a66:	6402                	ld	s0,0(sp)
    80001a68:	0141                	addi	sp,sp,16
    80001a6a:	8082                	ret
    first = 0;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	e807a223          	sw	zero,-380(a5) # 800088f0 <first.1667>
    fsinit(ROOTDEV);
    80001a74:	4505                	li	a0,1
    80001a76:	00002097          	auipc	ra,0x2
    80001a7a:	a4c080e7          	jalr	-1460(ra) # 800034c2 <fsinit>
    80001a7e:	bff9                	j	80001a5c <forkret+0x22>

0000000080001a80 <allocpid>:
allocpid() {
    80001a80:	1101                	addi	sp,sp,-32
    80001a82:	ec06                	sd	ra,24(sp)
    80001a84:	e822                	sd	s0,16(sp)
    80001a86:	e426                	sd	s1,8(sp)
    80001a88:	e04a                	sd	s2,0(sp)
    80001a8a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a8c:	00010917          	auipc	s2,0x10
    80001a90:	ec490913          	addi	s2,s2,-316 # 80011950 <pid_lock>
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	19e080e7          	jalr	414(ra) # 80000c34 <acquire>
  pid = nextpid;
    80001a9e:	00007797          	auipc	a5,0x7
    80001aa2:	e5678793          	addi	a5,a5,-426 # 800088f4 <nextpid>
    80001aa6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa8:	0014871b          	addiw	a4,s1,1
    80001aac:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aae:	854a                	mv	a0,s2
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	238080e7          	jalr	568(ra) # 80000ce8 <release>
}
    80001ab8:	8526                	mv	a0,s1
    80001aba:	60e2                	ld	ra,24(sp)
    80001abc:	6442                	ld	s0,16(sp)
    80001abe:	64a2                	ld	s1,8(sp)
    80001ac0:	6902                	ld	s2,0(sp)
    80001ac2:	6105                	addi	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <proc_pagetable>:
{
    80001ac6:	1101                	addi	sp,sp,-32
    80001ac8:	ec06                	sd	ra,24(sp)
    80001aca:	e822                	sd	s0,16(sp)
    80001acc:	e426                	sd	s1,8(sp)
    80001ace:	e04a                	sd	s2,0(sp)
    80001ad0:	1000                	addi	s0,sp,32
    80001ad2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	8ea080e7          	jalr	-1814(ra) # 800013be <uvmcreate>
    80001adc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ade:	c121                	beqz	a0,80001b1e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae0:	4729                	li	a4,10
    80001ae2:	00005697          	auipc	a3,0x5
    80001ae6:	51e68693          	addi	a3,a3,1310 # 80007000 <_trampoline>
    80001aea:	6605                	lui	a2,0x1
    80001aec:	040005b7          	lui	a1,0x4000
    80001af0:	15fd                	addi	a1,a1,-1
    80001af2:	05b2                	slli	a1,a1,0xc
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	66e080e7          	jalr	1646(ra) # 80001162 <mappages>
    80001afc:	02054863          	bltz	a0,80001b2c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b00:	4719                	li	a4,6
    80001b02:	05893683          	ld	a3,88(s2)
    80001b06:	6605                	lui	a2,0x1
    80001b08:	020005b7          	lui	a1,0x2000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b6                	slli	a1,a1,0xd
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	650080e7          	jalr	1616(ra) # 80001162 <mappages>
    80001b1a:	02054163          	bltz	a0,80001b3c <proc_pagetable+0x76>
}
    80001b1e:	8526                	mv	a0,s1
    80001b20:	60e2                	ld	ra,24(sp)
    80001b22:	6442                	ld	s0,16(sp)
    80001b24:	64a2                	ld	s1,8(sp)
    80001b26:	6902                	ld	s2,0(sp)
    80001b28:	6105                	addi	sp,sp,32
    80001b2a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b2c:	4581                	li	a1,0
    80001b2e:	8526                	mv	a0,s1
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	a8a080e7          	jalr	-1398(ra) # 800015ba <uvmfree>
    return 0;
    80001b38:	4481                	li	s1,0
    80001b3a:	b7d5                	j	80001b1e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	7b0080e7          	jalr	1968(ra) # 800012fa <uvmunmap>
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a64080e7          	jalr	-1436(ra) # 800015ba <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	bf7d                	j	80001b1e <proc_pagetable+0x58>

0000000080001b62 <proc_freepagetable>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	e04a                	sd	s2,0(sp)
    80001b6c:	1000                	addi	s0,sp,32
    80001b6e:	84aa                	mv	s1,a0
    80001b70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	77c080e7          	jalr	1916(ra) # 800012fa <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b86:	4681                	li	a3,0
    80001b88:	4605                	li	a2,1
    80001b8a:	020005b7          	lui	a1,0x2000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b6                	slli	a1,a1,0xd
    80001b92:	8526                	mv	a0,s1
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	766080e7          	jalr	1894(ra) # 800012fa <uvmunmap>
  uvmfree(pagetable, sz);
    80001b9c:	85ca                	mv	a1,s2
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	a1a080e7          	jalr	-1510(ra) # 800015ba <uvmfree>
}
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <freeproc>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
    80001bbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc0:	6d28                	ld	a0,88(a0)
    80001bc2:	c509                	beqz	a0,80001bcc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	e60080e7          	jalr	-416(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bcc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd0:	68a8                	ld	a0,80(s1)
    80001bd2:	c511                	beqz	a0,80001bde <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bd4:	64ac                	ld	a1,72(s1)
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	f8c080e7          	jalr	-116(ra) # 80001b62 <proc_freepagetable>
  p->pagetable = 0;
    80001bde:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001be6:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bea:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bee:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf2:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bf6:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bfa:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bfe:	0004ac23          	sw	zero,24(s1)
}
    80001c02:	60e2                	ld	ra,24(sp)
    80001c04:	6442                	ld	s0,16(sp)
    80001c06:	64a2                	ld	s1,8(sp)
    80001c08:	6105                	addi	sp,sp,32
    80001c0a:	8082                	ret

0000000080001c0c <allocproc>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	e04a                	sd	s2,0(sp)
    80001c16:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c18:	00010497          	auipc	s1,0x10
    80001c1c:	15048493          	addi	s1,s1,336 # 80011d68 <proc>
    80001c20:	00016917          	auipc	s2,0x16
    80001c24:	d4890913          	addi	s2,s2,-696 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	00a080e7          	jalr	10(ra) # 80000c34 <acquire>
    if(p->state == UNUSED) {
    80001c32:	4c9c                	lw	a5,24(s1)
    80001c34:	cf81                	beqz	a5,80001c4c <allocproc+0x40>
      release(&p->lock);
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	0b0080e7          	jalr	176(ra) # 80000ce8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c40:	17048493          	addi	s1,s1,368
    80001c44:	ff2492e3          	bne	s1,s2,80001c28 <allocproc+0x1c>
  return 0;
    80001c48:	4481                	li	s1,0
    80001c4a:	a0b9                	j	80001c98 <allocproc+0x8c>
  p->pid = allocpid();
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	e34080e7          	jalr	-460(ra) # 80001a80 <allocpid>
    80001c54:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	eca080e7          	jalr	-310(ra) # 80000b20 <kalloc>
    80001c5e:	892a                	mv	s2,a0
    80001c60:	eca8                	sd	a0,88(s1)
    80001c62:	c131                	beqz	a0,80001ca6 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e60080e7          	jalr	-416(ra) # 80001ac6 <proc_pagetable>
    80001c6e:	892a                	mv	s2,a0
    80001c70:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c72:	c129                	beqz	a0,80001cb4 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c74:	07000613          	li	a2,112
    80001c78:	4581                	li	a1,0
    80001c7a:	06048513          	addi	a0,s1,96
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	0b2080e7          	jalr	178(ra) # 80000d30 <memset>
  p->context.ra = (uint64)forkret;
    80001c86:	00000797          	auipc	a5,0x0
    80001c8a:	db478793          	addi	a5,a5,-588 # 80001a3a <forkret>
    80001c8e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c90:	60bc                	ld	a5,64(s1)
    80001c92:	6705                	lui	a4,0x1
    80001c94:	97ba                	add	a5,a5,a4
    80001c96:	f4bc                	sd	a5,104(s1)
}
    80001c98:	8526                	mv	a0,s1
    80001c9a:	60e2                	ld	ra,24(sp)
    80001c9c:	6442                	ld	s0,16(sp)
    80001c9e:	64a2                	ld	s1,8(sp)
    80001ca0:	6902                	ld	s2,0(sp)
    80001ca2:	6105                	addi	sp,sp,32
    80001ca4:	8082                	ret
    release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	040080e7          	jalr	64(ra) # 80000ce8 <release>
    return 0;
    80001cb0:	84ca                	mv	s1,s2
    80001cb2:	b7dd                	j	80001c98 <allocproc+0x8c>
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	efe080e7          	jalr	-258(ra) # 80001bb4 <freeproc>
    release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	028080e7          	jalr	40(ra) # 80000ce8 <release>
    return 0;
    80001cc8:	84ca                	mv	s1,s2
    80001cca:	b7f9                	j	80001c98 <allocproc+0x8c>

0000000080001ccc <userinit>:
{
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	f36080e7          	jalr	-202(ra) # 80001c0c <allocproc>
    80001cde:	84aa                	mv	s1,a0
  initproc = p;
    80001ce0:	00007797          	auipc	a5,0x7
    80001ce4:	32a7bc23          	sd	a0,824(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ce8:	03400613          	li	a2,52
    80001cec:	00007597          	auipc	a1,0x7
    80001cf0:	c1458593          	addi	a1,a1,-1004 # 80008900 <initcode>
    80001cf4:	6928                	ld	a0,80(a0)
    80001cf6:	fffff097          	auipc	ra,0xfffff
    80001cfa:	6f6080e7          	jalr	1782(ra) # 800013ec <uvminit>
  p->sz = PGSIZE;
    80001cfe:	6785                	lui	a5,0x1
    80001d00:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d02:	6cb8                	ld	a4,88(s1)
    80001d04:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d0c:	4641                	li	a2,16
    80001d0e:	00006597          	auipc	a1,0x6
    80001d12:	4da58593          	addi	a1,a1,1242 # 800081e8 <digits+0x1a8>
    80001d16:	15848513          	addi	a0,s1,344
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	16c080e7          	jalr	364(ra) # 80000e86 <safestrcpy>
  p->cwd = namei("/");
    80001d22:	00006517          	auipc	a0,0x6
    80001d26:	4d650513          	addi	a0,a0,1238 # 800081f8 <digits+0x1b8>
    80001d2a:	00002097          	auipc	ra,0x2
    80001d2e:	1c0080e7          	jalr	448(ra) # 80003eea <namei>
    80001d32:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d36:	4789                	li	a5,2
    80001d38:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	fac080e7          	jalr	-84(ra) # 80000ce8 <release>
}
    80001d44:	60e2                	ld	ra,24(sp)
    80001d46:	6442                	ld	s0,16(sp)
    80001d48:	64a2                	ld	s1,8(sp)
    80001d4a:	6105                	addi	sp,sp,32
    80001d4c:	8082                	ret

0000000080001d4e <growproc>:
{
    80001d4e:	1101                	addi	sp,sp,-32
    80001d50:	ec06                	sd	ra,24(sp)
    80001d52:	e822                	sd	s0,16(sp)
    80001d54:	e426                	sd	s1,8(sp)
    80001d56:	e04a                	sd	s2,0(sp)
    80001d58:	1000                	addi	s0,sp,32
    80001d5a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	ca6080e7          	jalr	-858(ra) # 80001a02 <myproc>
    80001d64:	892a                	mv	s2,a0
  sz = p->sz;
    80001d66:	652c                	ld	a1,72(a0)
    80001d68:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d6c:	00904f63          	bgtz	s1,80001d8a <growproc+0x3c>
  } else if(n < 0){
    80001d70:	0204cc63          	bltz	s1,80001da8 <growproc+0x5a>
  p->sz = sz;
    80001d74:	1602                	slli	a2,a2,0x20
    80001d76:	9201                	srli	a2,a2,0x20
    80001d78:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d7c:	4501                	li	a0,0
}
    80001d7e:	60e2                	ld	ra,24(sp)
    80001d80:	6442                	ld	s0,16(sp)
    80001d82:	64a2                	ld	s1,8(sp)
    80001d84:	6902                	ld	s2,0(sp)
    80001d86:	6105                	addi	sp,sp,32
    80001d88:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d8a:	9e25                	addw	a2,a2,s1
    80001d8c:	1602                	slli	a2,a2,0x20
    80001d8e:	9201                	srli	a2,a2,0x20
    80001d90:	1582                	slli	a1,a1,0x20
    80001d92:	9181                	srli	a1,a1,0x20
    80001d94:	6928                	ld	a0,80(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	710080e7          	jalr	1808(ra) # 800014a6 <uvmalloc>
    80001d9e:	0005061b          	sext.w	a2,a0
    80001da2:	fa69                	bnez	a2,80001d74 <growproc+0x26>
      return -1;
    80001da4:	557d                	li	a0,-1
    80001da6:	bfe1                	j	80001d7e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da8:	9e25                	addw	a2,a2,s1
    80001daa:	1602                	slli	a2,a2,0x20
    80001dac:	9201                	srli	a2,a2,0x20
    80001dae:	1582                	slli	a1,a1,0x20
    80001db0:	9181                	srli	a1,a1,0x20
    80001db2:	6928                	ld	a0,80(a0)
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	6aa080e7          	jalr	1706(ra) # 8000145e <uvmdealloc>
    80001dbc:	0005061b          	sext.w	a2,a0
    80001dc0:	bf55                	j	80001d74 <growproc+0x26>

0000000080001dc2 <fork>:
{
    80001dc2:	7179                	addi	sp,sp,-48
    80001dc4:	f406                	sd	ra,40(sp)
    80001dc6:	f022                	sd	s0,32(sp)
    80001dc8:	ec26                	sd	s1,24(sp)
    80001dca:	e84a                	sd	s2,16(sp)
    80001dcc:	e44e                	sd	s3,8(sp)
    80001dce:	e052                	sd	s4,0(sp)
    80001dd0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	c30080e7          	jalr	-976(ra) # 80001a02 <myproc>
    80001dda:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	e30080e7          	jalr	-464(ra) # 80001c0c <allocproc>
    80001de4:	c575                	beqz	a0,80001ed0 <fork+0x10e>
    80001de6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de8:	04893603          	ld	a2,72(s2)
    80001dec:	692c                	ld	a1,80(a0)
    80001dee:	05093503          	ld	a0,80(s2)
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	800080e7          	jalr	-2048(ra) # 800015f2 <uvmcopy>
    80001dfa:	04054863          	bltz	a0,80001e4a <fork+0x88>
  np->sz = p->sz;
    80001dfe:	04893783          	ld	a5,72(s2)
    80001e02:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e06:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e0a:	05893683          	ld	a3,88(s2)
    80001e0e:	87b6                	mv	a5,a3
    80001e10:	0589b703          	ld	a4,88(s3)
    80001e14:	12068693          	addi	a3,a3,288
    80001e18:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e1c:	6788                	ld	a0,8(a5)
    80001e1e:	6b8c                	ld	a1,16(a5)
    80001e20:	6f90                	ld	a2,24(a5)
    80001e22:	01073023          	sd	a6,0(a4)
    80001e26:	e708                	sd	a0,8(a4)
    80001e28:	eb0c                	sd	a1,16(a4)
    80001e2a:	ef10                	sd	a2,24(a4)
    80001e2c:	02078793          	addi	a5,a5,32
    80001e30:	02070713          	addi	a4,a4,32
    80001e34:	fed792e3          	bne	a5,a3,80001e18 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e38:	0589b783          	ld	a5,88(s3)
    80001e3c:	0607b823          	sd	zero,112(a5)
    80001e40:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e44:	15000a13          	li	s4,336
    80001e48:	a03d                	j	80001e76 <fork+0xb4>
    freeproc(np);
    80001e4a:	854e                	mv	a0,s3
    80001e4c:	00000097          	auipc	ra,0x0
    80001e50:	d68080e7          	jalr	-664(ra) # 80001bb4 <freeproc>
    release(&np->lock);
    80001e54:	854e                	mv	a0,s3
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	e92080e7          	jalr	-366(ra) # 80000ce8 <release>
    return -1;
    80001e5e:	54fd                	li	s1,-1
    80001e60:	a8b9                	j	80001ebe <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00002097          	auipc	ra,0x2
    80001e66:	714080e7          	jalr	1812(ra) # 80004576 <filedup>
    80001e6a:	009987b3          	add	a5,s3,s1
    80001e6e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e70:	04a1                	addi	s1,s1,8
    80001e72:	01448763          	beq	s1,s4,80001e80 <fork+0xbe>
    if(p->ofile[i])
    80001e76:	009907b3          	add	a5,s2,s1
    80001e7a:	6388                	ld	a0,0(a5)
    80001e7c:	f17d                	bnez	a0,80001e62 <fork+0xa0>
    80001e7e:	bfcd                	j	80001e70 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e80:	15093503          	ld	a0,336(s2)
    80001e84:	00002097          	auipc	ra,0x2
    80001e88:	878080e7          	jalr	-1928(ra) # 800036fc <idup>
    80001e8c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e90:	4641                	li	a2,16
    80001e92:	15890593          	addi	a1,s2,344
    80001e96:	15898513          	addi	a0,s3,344
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	fec080e7          	jalr	-20(ra) # 80000e86 <safestrcpy>
  np->mask = p->mask;
    80001ea2:	16892783          	lw	a5,360(s2)
    80001ea6:	16f9a423          	sw	a5,360(s3)
  pid = np->pid;
    80001eaa:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001eae:	4789                	li	a5,2
    80001eb0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb4:	854e                	mv	a0,s3
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	e32080e7          	jalr	-462(ra) # 80000ce8 <release>
}
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	70a2                	ld	ra,40(sp)
    80001ec2:	7402                	ld	s0,32(sp)
    80001ec4:	64e2                	ld	s1,24(sp)
    80001ec6:	6942                	ld	s2,16(sp)
    80001ec8:	69a2                	ld	s3,8(sp)
    80001eca:	6a02                	ld	s4,0(sp)
    80001ecc:	6145                	addi	sp,sp,48
    80001ece:	8082                	ret
    return -1;
    80001ed0:	54fd                	li	s1,-1
    80001ed2:	b7f5                	j	80001ebe <fork+0xfc>

0000000080001ed4 <reparent>:
{
    80001ed4:	7179                	addi	sp,sp,-48
    80001ed6:	f406                	sd	ra,40(sp)
    80001ed8:	f022                	sd	s0,32(sp)
    80001eda:	ec26                	sd	s1,24(sp)
    80001edc:	e84a                	sd	s2,16(sp)
    80001ede:	e44e                	sd	s3,8(sp)
    80001ee0:	e052                	sd	s4,0(sp)
    80001ee2:	1800                	addi	s0,sp,48
    80001ee4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ee6:	00010497          	auipc	s1,0x10
    80001eea:	e8248493          	addi	s1,s1,-382 # 80011d68 <proc>
      pp->parent = initproc;
    80001eee:	00007a17          	auipc	s4,0x7
    80001ef2:	12aa0a13          	addi	s4,s4,298 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ef6:	00016997          	auipc	s3,0x16
    80001efa:	a7298993          	addi	s3,s3,-1422 # 80017968 <tickslock>
    80001efe:	a029                	j	80001f08 <reparent+0x34>
    80001f00:	17048493          	addi	s1,s1,368
    80001f04:	03348363          	beq	s1,s3,80001f2a <reparent+0x56>
    if(pp->parent == p){
    80001f08:	709c                	ld	a5,32(s1)
    80001f0a:	ff279be3          	bne	a5,s2,80001f00 <reparent+0x2c>
      acquire(&pp->lock);
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	d24080e7          	jalr	-732(ra) # 80000c34 <acquire>
      pp->parent = initproc;
    80001f18:	000a3783          	ld	a5,0(s4)
    80001f1c:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	dc8080e7          	jalr	-568(ra) # 80000ce8 <release>
    80001f28:	bfe1                	j	80001f00 <reparent+0x2c>
}
    80001f2a:	70a2                	ld	ra,40(sp)
    80001f2c:	7402                	ld	s0,32(sp)
    80001f2e:	64e2                	ld	s1,24(sp)
    80001f30:	6942                	ld	s2,16(sp)
    80001f32:	69a2                	ld	s3,8(sp)
    80001f34:	6a02                	ld	s4,0(sp)
    80001f36:	6145                	addi	sp,sp,48
    80001f38:	8082                	ret

0000000080001f3a <scheduler>:
{
    80001f3a:	715d                	addi	sp,sp,-80
    80001f3c:	e486                	sd	ra,72(sp)
    80001f3e:	e0a2                	sd	s0,64(sp)
    80001f40:	fc26                	sd	s1,56(sp)
    80001f42:	f84a                	sd	s2,48(sp)
    80001f44:	f44e                	sd	s3,40(sp)
    80001f46:	f052                	sd	s4,32(sp)
    80001f48:	ec56                	sd	s5,24(sp)
    80001f4a:	e85a                	sd	s6,16(sp)
    80001f4c:	e45e                	sd	s7,8(sp)
    80001f4e:	e062                	sd	s8,0(sp)
    80001f50:	0880                	addi	s0,sp,80
    80001f52:	8792                	mv	a5,tp
  int id = r_tp();
    80001f54:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f56:	00779b13          	slli	s6,a5,0x7
    80001f5a:	00010717          	auipc	a4,0x10
    80001f5e:	9f670713          	addi	a4,a4,-1546 # 80011950 <pid_lock>
    80001f62:	975a                	add	a4,a4,s6
    80001f64:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f68:	00010717          	auipc	a4,0x10
    80001f6c:	a0870713          	addi	a4,a4,-1528 # 80011970 <cpus+0x8>
    80001f70:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f72:	4c0d                	li	s8,3
        c->proc = p;
    80001f74:	079e                	slli	a5,a5,0x7
    80001f76:	00010a17          	auipc	s4,0x10
    80001f7a:	9daa0a13          	addi	s4,s4,-1574 # 80011950 <pid_lock>
    80001f7e:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f80:	00016997          	auipc	s3,0x16
    80001f84:	9e898993          	addi	s3,s3,-1560 # 80017968 <tickslock>
        found = 1;
    80001f88:	4b85                	li	s7,1
    80001f8a:	a899                	j	80001fe0 <scheduler+0xa6>
        p->state = RUNNING;
    80001f8c:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f90:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f94:	06048593          	addi	a1,s1,96
    80001f98:	855a                	mv	a0,s6
    80001f9a:	00000097          	auipc	ra,0x0
    80001f9e:	668080e7          	jalr	1640(ra) # 80002602 <swtch>
        c->proc = 0;
    80001fa2:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fa6:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	d3e080e7          	jalr	-706(ra) # 80000ce8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb2:	17048493          	addi	s1,s1,368
    80001fb6:	01348b63          	beq	s1,s3,80001fcc <scheduler+0x92>
      acquire(&p->lock);
    80001fba:	8526                	mv	a0,s1
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	c78080e7          	jalr	-904(ra) # 80000c34 <acquire>
      if(p->state == RUNNABLE) {
    80001fc4:	4c9c                	lw	a5,24(s1)
    80001fc6:	ff2791e3          	bne	a5,s2,80001fa8 <scheduler+0x6e>
    80001fca:	b7c9                	j	80001f8c <scheduler+0x52>
    if(found == 0) {
    80001fcc:	000a9a63          	bnez	s5,80001fe0 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fd4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fd8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fdc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fe4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fe8:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fec:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fee:	00010497          	auipc	s1,0x10
    80001ff2:	d7a48493          	addi	s1,s1,-646 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001ff6:	4909                	li	s2,2
    80001ff8:	b7c9                	j	80001fba <scheduler+0x80>

0000000080001ffa <sched>:
{
    80001ffa:	7179                	addi	sp,sp,-48
    80001ffc:	f406                	sd	ra,40(sp)
    80001ffe:	f022                	sd	s0,32(sp)
    80002000:	ec26                	sd	s1,24(sp)
    80002002:	e84a                	sd	s2,16(sp)
    80002004:	e44e                	sd	s3,8(sp)
    80002006:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002008:	00000097          	auipc	ra,0x0
    8000200c:	9fa080e7          	jalr	-1542(ra) # 80001a02 <myproc>
    80002010:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002012:	fffff097          	auipc	ra,0xfffff
    80002016:	ba8080e7          	jalr	-1112(ra) # 80000bba <holding>
    8000201a:	c93d                	beqz	a0,80002090 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000201e:	2781                	sext.w	a5,a5
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	00010717          	auipc	a4,0x10
    80002026:	92e70713          	addi	a4,a4,-1746 # 80011950 <pid_lock>
    8000202a:	97ba                	add	a5,a5,a4
    8000202c:	0907a703          	lw	a4,144(a5)
    80002030:	4785                	li	a5,1
    80002032:	06f71763          	bne	a4,a5,800020a0 <sched+0xa6>
  if(p->state == RUNNING)
    80002036:	4c98                	lw	a4,24(s1)
    80002038:	478d                	li	a5,3
    8000203a:	06f70b63          	beq	a4,a5,800020b0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002042:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002044:	efb5                	bnez	a5,800020c0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002046:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002048:	00010917          	auipc	s2,0x10
    8000204c:	90890913          	addi	s2,s2,-1784 # 80011950 <pid_lock>
    80002050:	2781                	sext.w	a5,a5
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	97ca                	add	a5,a5,s2
    80002056:	0947a983          	lw	s3,148(a5)
    8000205a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205c:	2781                	sext.w	a5,a5
    8000205e:	079e                	slli	a5,a5,0x7
    80002060:	00010597          	auipc	a1,0x10
    80002064:	91058593          	addi	a1,a1,-1776 # 80011970 <cpus+0x8>
    80002068:	95be                	add	a1,a1,a5
    8000206a:	06048513          	addi	a0,s1,96
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	594080e7          	jalr	1428(ra) # 80002602 <swtch>
    80002076:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002078:	2781                	sext.w	a5,a5
    8000207a:	079e                	slli	a5,a5,0x7
    8000207c:	97ca                	add	a5,a5,s2
    8000207e:	0937aa23          	sw	s3,148(a5)
}
    80002082:	70a2                	ld	ra,40(sp)
    80002084:	7402                	ld	s0,32(sp)
    80002086:	64e2                	ld	s1,24(sp)
    80002088:	6942                	ld	s2,16(sp)
    8000208a:	69a2                	ld	s3,8(sp)
    8000208c:	6145                	addi	sp,sp,48
    8000208e:	8082                	ret
    panic("sched p->lock");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	17050513          	addi	a0,a0,368 # 80008200 <digits+0x1c0>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4b0080e7          	jalr	1200(ra) # 80000548 <panic>
    panic("sched locks");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	17050513          	addi	a0,a0,368 # 80008210 <digits+0x1d0>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	4a0080e7          	jalr	1184(ra) # 80000548 <panic>
    panic("sched running");
    800020b0:	00006517          	auipc	a0,0x6
    800020b4:	17050513          	addi	a0,a0,368 # 80008220 <digits+0x1e0>
    800020b8:	ffffe097          	auipc	ra,0xffffe
    800020bc:	490080e7          	jalr	1168(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020c0:	00006517          	auipc	a0,0x6
    800020c4:	17050513          	addi	a0,a0,368 # 80008230 <digits+0x1f0>
    800020c8:	ffffe097          	auipc	ra,0xffffe
    800020cc:	480080e7          	jalr	1152(ra) # 80000548 <panic>

00000000800020d0 <exit>:
{
    800020d0:	7179                	addi	sp,sp,-48
    800020d2:	f406                	sd	ra,40(sp)
    800020d4:	f022                	sd	s0,32(sp)
    800020d6:	ec26                	sd	s1,24(sp)
    800020d8:	e84a                	sd	s2,16(sp)
    800020da:	e44e                	sd	s3,8(sp)
    800020dc:	e052                	sd	s4,0(sp)
    800020de:	1800                	addi	s0,sp,48
    800020e0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	920080e7          	jalr	-1760(ra) # 80001a02 <myproc>
    800020ea:	89aa                	mv	s3,a0
  if(p == initproc)
    800020ec:	00007797          	auipc	a5,0x7
    800020f0:	f2c7b783          	ld	a5,-212(a5) # 80009018 <initproc>
    800020f4:	0d050493          	addi	s1,a0,208
    800020f8:	15050913          	addi	s2,a0,336
    800020fc:	02a79363          	bne	a5,a0,80002122 <exit+0x52>
    panic("init exiting");
    80002100:	00006517          	auipc	a0,0x6
    80002104:	14850513          	addi	a0,a0,328 # 80008248 <digits+0x208>
    80002108:	ffffe097          	auipc	ra,0xffffe
    8000210c:	440080e7          	jalr	1088(ra) # 80000548 <panic>
      fileclose(f);
    80002110:	00002097          	auipc	ra,0x2
    80002114:	4b8080e7          	jalr	1208(ra) # 800045c8 <fileclose>
      p->ofile[fd] = 0;
    80002118:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000211c:	04a1                	addi	s1,s1,8
    8000211e:	01248563          	beq	s1,s2,80002128 <exit+0x58>
    if(p->ofile[fd]){
    80002122:	6088                	ld	a0,0(s1)
    80002124:	f575                	bnez	a0,80002110 <exit+0x40>
    80002126:	bfdd                	j	8000211c <exit+0x4c>
  begin_op();
    80002128:	00002097          	auipc	ra,0x2
    8000212c:	fce080e7          	jalr	-50(ra) # 800040f6 <begin_op>
  iput(p->cwd);
    80002130:	1509b503          	ld	a0,336(s3)
    80002134:	00001097          	auipc	ra,0x1
    80002138:	7c0080e7          	jalr	1984(ra) # 800038f4 <iput>
  end_op();
    8000213c:	00002097          	auipc	ra,0x2
    80002140:	03a080e7          	jalr	58(ra) # 80004176 <end_op>
  p->cwd = 0;
    80002144:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002148:	00007497          	auipc	s1,0x7
    8000214c:	ed048493          	addi	s1,s1,-304 # 80009018 <initproc>
    80002150:	6088                	ld	a0,0(s1)
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	ae2080e7          	jalr	-1310(ra) # 80000c34 <acquire>
  wakeup1(initproc);
    8000215a:	6088                	ld	a0,0(s1)
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	766080e7          	jalr	1894(ra) # 800018c2 <wakeup1>
  release(&initproc->lock);
    80002164:	6088                	ld	a0,0(s1)
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	b82080e7          	jalr	-1150(ra) # 80000ce8 <release>
  acquire(&p->lock);
    8000216e:	854e                	mv	a0,s3
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	ac4080e7          	jalr	-1340(ra) # 80000c34 <acquire>
  struct proc *original_parent = p->parent;
    80002178:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000217c:	854e                	mv	a0,s3
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	b6a080e7          	jalr	-1174(ra) # 80000ce8 <release>
  acquire(&original_parent->lock);
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	aac080e7          	jalr	-1364(ra) # 80000c34 <acquire>
  acquire(&p->lock);
    80002190:	854e                	mv	a0,s3
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	aa2080e7          	jalr	-1374(ra) # 80000c34 <acquire>
  reparent(p);
    8000219a:	854e                	mv	a0,s3
    8000219c:	00000097          	auipc	ra,0x0
    800021a0:	d38080e7          	jalr	-712(ra) # 80001ed4 <reparent>
  wakeup1(original_parent);
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	71c080e7          	jalr	1820(ra) # 800018c2 <wakeup1>
  p->xstate = status;
    800021ae:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021b2:	4791                	li	a5,4
    800021b4:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	b2e080e7          	jalr	-1234(ra) # 80000ce8 <release>
  sched();
    800021c2:	00000097          	auipc	ra,0x0
    800021c6:	e38080e7          	jalr	-456(ra) # 80001ffa <sched>
  panic("zombie exit");
    800021ca:	00006517          	auipc	a0,0x6
    800021ce:	08e50513          	addi	a0,a0,142 # 80008258 <digits+0x218>
    800021d2:	ffffe097          	auipc	ra,0xffffe
    800021d6:	376080e7          	jalr	886(ra) # 80000548 <panic>

00000000800021da <yield>:
{
    800021da:	1101                	addi	sp,sp,-32
    800021dc:	ec06                	sd	ra,24(sp)
    800021de:	e822                	sd	s0,16(sp)
    800021e0:	e426                	sd	s1,8(sp)
    800021e2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	81e080e7          	jalr	-2018(ra) # 80001a02 <myproc>
    800021ec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021ee:	fffff097          	auipc	ra,0xfffff
    800021f2:	a46080e7          	jalr	-1466(ra) # 80000c34 <acquire>
  p->state = RUNNABLE;
    800021f6:	4789                	li	a5,2
    800021f8:	cc9c                	sw	a5,24(s1)
  sched();
    800021fa:	00000097          	auipc	ra,0x0
    800021fe:	e00080e7          	jalr	-512(ra) # 80001ffa <sched>
  release(&p->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	ae4080e7          	jalr	-1308(ra) # 80000ce8 <release>
}
    8000220c:	60e2                	ld	ra,24(sp)
    8000220e:	6442                	ld	s0,16(sp)
    80002210:	64a2                	ld	s1,8(sp)
    80002212:	6105                	addi	sp,sp,32
    80002214:	8082                	ret

0000000080002216 <sleep>:
{
    80002216:	7179                	addi	sp,sp,-48
    80002218:	f406                	sd	ra,40(sp)
    8000221a:	f022                	sd	s0,32(sp)
    8000221c:	ec26                	sd	s1,24(sp)
    8000221e:	e84a                	sd	s2,16(sp)
    80002220:	e44e                	sd	s3,8(sp)
    80002222:	1800                	addi	s0,sp,48
    80002224:	89aa                	mv	s3,a0
    80002226:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	7da080e7          	jalr	2010(ra) # 80001a02 <myproc>
    80002230:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002232:	05250663          	beq	a0,s2,8000227e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	9fe080e7          	jalr	-1538(ra) # 80000c34 <acquire>
    release(lk);
    8000223e:	854a                	mv	a0,s2
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	aa8080e7          	jalr	-1368(ra) # 80000ce8 <release>
  p->chan = chan;
    80002248:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000224c:	4785                	li	a5,1
    8000224e:	cc9c                	sw	a5,24(s1)
  sched();
    80002250:	00000097          	auipc	ra,0x0
    80002254:	daa080e7          	jalr	-598(ra) # 80001ffa <sched>
  p->chan = 0;
    80002258:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	a8a080e7          	jalr	-1398(ra) # 80000ce8 <release>
    acquire(lk);
    80002266:	854a                	mv	a0,s2
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	9cc080e7          	jalr	-1588(ra) # 80000c34 <acquire>
}
    80002270:	70a2                	ld	ra,40(sp)
    80002272:	7402                	ld	s0,32(sp)
    80002274:	64e2                	ld	s1,24(sp)
    80002276:	6942                	ld	s2,16(sp)
    80002278:	69a2                	ld	s3,8(sp)
    8000227a:	6145                	addi	sp,sp,48
    8000227c:	8082                	ret
  p->chan = chan;
    8000227e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002282:	4785                	li	a5,1
    80002284:	cd1c                	sw	a5,24(a0)
  sched();
    80002286:	00000097          	auipc	ra,0x0
    8000228a:	d74080e7          	jalr	-652(ra) # 80001ffa <sched>
  p->chan = 0;
    8000228e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002292:	bff9                	j	80002270 <sleep+0x5a>

0000000080002294 <wait>:
{
    80002294:	715d                	addi	sp,sp,-80
    80002296:	e486                	sd	ra,72(sp)
    80002298:	e0a2                	sd	s0,64(sp)
    8000229a:	fc26                	sd	s1,56(sp)
    8000229c:	f84a                	sd	s2,48(sp)
    8000229e:	f44e                	sd	s3,40(sp)
    800022a0:	f052                	sd	s4,32(sp)
    800022a2:	ec56                	sd	s5,24(sp)
    800022a4:	e85a                	sd	s6,16(sp)
    800022a6:	e45e                	sd	s7,8(sp)
    800022a8:	e062                	sd	s8,0(sp)
    800022aa:	0880                	addi	s0,sp,80
    800022ac:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	754080e7          	jalr	1876(ra) # 80001a02 <myproc>
    800022b6:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022b8:	8c2a                	mv	s8,a0
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	97a080e7          	jalr	-1670(ra) # 80000c34 <acquire>
    havekids = 0;
    800022c2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022c4:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022c6:	00015997          	auipc	s3,0x15
    800022ca:	6a298993          	addi	s3,s3,1698 # 80017968 <tickslock>
        havekids = 1;
    800022ce:	4a85                	li	s5,1
    havekids = 0;
    800022d0:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022d2:	00010497          	auipc	s1,0x10
    800022d6:	a9648493          	addi	s1,s1,-1386 # 80011d68 <proc>
    800022da:	a08d                	j	8000233c <wait+0xa8>
          pid = np->pid;
    800022dc:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022e0:	000b0e63          	beqz	s6,800022fc <wait+0x68>
    800022e4:	4691                	li	a3,4
    800022e6:	03448613          	addi	a2,s1,52
    800022ea:	85da                	mv	a1,s6
    800022ec:	05093503          	ld	a0,80(s2)
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	406080e7          	jalr	1030(ra) # 800016f6 <copyout>
    800022f8:	02054263          	bltz	a0,8000231c <wait+0x88>
          freeproc(np);
    800022fc:	8526                	mv	a0,s1
    800022fe:	00000097          	auipc	ra,0x0
    80002302:	8b6080e7          	jalr	-1866(ra) # 80001bb4 <freeproc>
          release(&np->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	9e0080e7          	jalr	-1568(ra) # 80000ce8 <release>
          release(&p->lock);
    80002310:	854a                	mv	a0,s2
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	9d6080e7          	jalr	-1578(ra) # 80000ce8 <release>
          return pid;
    8000231a:	a8a9                	j	80002374 <wait+0xe0>
            release(&np->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	9ca080e7          	jalr	-1590(ra) # 80000ce8 <release>
            release(&p->lock);
    80002326:	854a                	mv	a0,s2
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	9c0080e7          	jalr	-1600(ra) # 80000ce8 <release>
            return -1;
    80002330:	59fd                	li	s3,-1
    80002332:	a089                	j	80002374 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002334:	17048493          	addi	s1,s1,368
    80002338:	03348463          	beq	s1,s3,80002360 <wait+0xcc>
      if(np->parent == p){
    8000233c:	709c                	ld	a5,32(s1)
    8000233e:	ff279be3          	bne	a5,s2,80002334 <wait+0xa0>
        acquire(&np->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	8f0080e7          	jalr	-1808(ra) # 80000c34 <acquire>
        if(np->state == ZOMBIE){
    8000234c:	4c9c                	lw	a5,24(s1)
    8000234e:	f94787e3          	beq	a5,s4,800022dc <wait+0x48>
        release(&np->lock);
    80002352:	8526                	mv	a0,s1
    80002354:	fffff097          	auipc	ra,0xfffff
    80002358:	994080e7          	jalr	-1644(ra) # 80000ce8 <release>
        havekids = 1;
    8000235c:	8756                	mv	a4,s5
    8000235e:	bfd9                	j	80002334 <wait+0xa0>
    if(!havekids || p->killed){
    80002360:	c701                	beqz	a4,80002368 <wait+0xd4>
    80002362:	03092783          	lw	a5,48(s2)
    80002366:	c785                	beqz	a5,8000238e <wait+0xfa>
      release(&p->lock);
    80002368:	854a                	mv	a0,s2
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	97e080e7          	jalr	-1666(ra) # 80000ce8 <release>
      return -1;
    80002372:	59fd                	li	s3,-1
}
    80002374:	854e                	mv	a0,s3
    80002376:	60a6                	ld	ra,72(sp)
    80002378:	6406                	ld	s0,64(sp)
    8000237a:	74e2                	ld	s1,56(sp)
    8000237c:	7942                	ld	s2,48(sp)
    8000237e:	79a2                	ld	s3,40(sp)
    80002380:	7a02                	ld	s4,32(sp)
    80002382:	6ae2                	ld	s5,24(sp)
    80002384:	6b42                	ld	s6,16(sp)
    80002386:	6ba2                	ld	s7,8(sp)
    80002388:	6c02                	ld	s8,0(sp)
    8000238a:	6161                	addi	sp,sp,80
    8000238c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000238e:	85e2                	mv	a1,s8
    80002390:	854a                	mv	a0,s2
    80002392:	00000097          	auipc	ra,0x0
    80002396:	e84080e7          	jalr	-380(ra) # 80002216 <sleep>
    havekids = 0;
    8000239a:	bf1d                	j	800022d0 <wait+0x3c>

000000008000239c <wakeup>:
{
    8000239c:	7139                	addi	sp,sp,-64
    8000239e:	fc06                	sd	ra,56(sp)
    800023a0:	f822                	sd	s0,48(sp)
    800023a2:	f426                	sd	s1,40(sp)
    800023a4:	f04a                	sd	s2,32(sp)
    800023a6:	ec4e                	sd	s3,24(sp)
    800023a8:	e852                	sd	s4,16(sp)
    800023aa:	e456                	sd	s5,8(sp)
    800023ac:	0080                	addi	s0,sp,64
    800023ae:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b0:	00010497          	auipc	s1,0x10
    800023b4:	9b848493          	addi	s1,s1,-1608 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023b8:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023ba:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023bc:	00015917          	auipc	s2,0x15
    800023c0:	5ac90913          	addi	s2,s2,1452 # 80017968 <tickslock>
    800023c4:	a821                	j	800023dc <wakeup+0x40>
      p->state = RUNNABLE;
    800023c6:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	91c080e7          	jalr	-1764(ra) # 80000ce8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d4:	17048493          	addi	s1,s1,368
    800023d8:	01248e63          	beq	s1,s2,800023f4 <wakeup+0x58>
    acquire(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	856080e7          	jalr	-1962(ra) # 80000c34 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e6:	4c9c                	lw	a5,24(s1)
    800023e8:	ff3791e3          	bne	a5,s3,800023ca <wakeup+0x2e>
    800023ec:	749c                	ld	a5,40(s1)
    800023ee:	fd479ee3          	bne	a5,s4,800023ca <wakeup+0x2e>
    800023f2:	bfd1                	j	800023c6 <wakeup+0x2a>
}
    800023f4:	70e2                	ld	ra,56(sp)
    800023f6:	7442                	ld	s0,48(sp)
    800023f8:	74a2                	ld	s1,40(sp)
    800023fa:	7902                	ld	s2,32(sp)
    800023fc:	69e2                	ld	s3,24(sp)
    800023fe:	6a42                	ld	s4,16(sp)
    80002400:	6aa2                	ld	s5,8(sp)
    80002402:	6121                	addi	sp,sp,64
    80002404:	8082                	ret

0000000080002406 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002406:	7179                	addi	sp,sp,-48
    80002408:	f406                	sd	ra,40(sp)
    8000240a:	f022                	sd	s0,32(sp)
    8000240c:	ec26                	sd	s1,24(sp)
    8000240e:	e84a                	sd	s2,16(sp)
    80002410:	e44e                	sd	s3,8(sp)
    80002412:	1800                	addi	s0,sp,48
    80002414:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002416:	00010497          	auipc	s1,0x10
    8000241a:	95248493          	addi	s1,s1,-1710 # 80011d68 <proc>
    8000241e:	00015997          	auipc	s3,0x15
    80002422:	54a98993          	addi	s3,s3,1354 # 80017968 <tickslock>
    acquire(&p->lock);
    80002426:	8526                	mv	a0,s1
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	80c080e7          	jalr	-2036(ra) # 80000c34 <acquire>
    if(p->pid == pid){
    80002430:	5c9c                	lw	a5,56(s1)
    80002432:	01278d63          	beq	a5,s2,8000244c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	8b0080e7          	jalr	-1872(ra) # 80000ce8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002440:	17048493          	addi	s1,s1,368
    80002444:	ff3491e3          	bne	s1,s3,80002426 <kill+0x20>
  }
  return -1;
    80002448:	557d                	li	a0,-1
    8000244a:	a829                	j	80002464 <kill+0x5e>
      p->killed = 1;
    8000244c:	4785                	li	a5,1
    8000244e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002450:	4c98                	lw	a4,24(s1)
    80002452:	4785                	li	a5,1
    80002454:	00f70f63          	beq	a4,a5,80002472 <kill+0x6c>
      release(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	88e080e7          	jalr	-1906(ra) # 80000ce8 <release>
      return 0;
    80002462:	4501                	li	a0,0
}
    80002464:	70a2                	ld	ra,40(sp)
    80002466:	7402                	ld	s0,32(sp)
    80002468:	64e2                	ld	s1,24(sp)
    8000246a:	6942                	ld	s2,16(sp)
    8000246c:	69a2                	ld	s3,8(sp)
    8000246e:	6145                	addi	sp,sp,48
    80002470:	8082                	ret
        p->state = RUNNABLE;
    80002472:	4789                	li	a5,2
    80002474:	cc9c                	sw	a5,24(s1)
    80002476:	b7cd                	j	80002458 <kill+0x52>

0000000080002478 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002478:	7179                	addi	sp,sp,-48
    8000247a:	f406                	sd	ra,40(sp)
    8000247c:	f022                	sd	s0,32(sp)
    8000247e:	ec26                	sd	s1,24(sp)
    80002480:	e84a                	sd	s2,16(sp)
    80002482:	e44e                	sd	s3,8(sp)
    80002484:	e052                	sd	s4,0(sp)
    80002486:	1800                	addi	s0,sp,48
    80002488:	84aa                	mv	s1,a0
    8000248a:	892e                	mv	s2,a1
    8000248c:	89b2                	mv	s3,a2
    8000248e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	572080e7          	jalr	1394(ra) # 80001a02 <myproc>
  if(user_dst){
    80002498:	c08d                	beqz	s1,800024ba <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000249a:	86d2                	mv	a3,s4
    8000249c:	864e                	mv	a2,s3
    8000249e:	85ca                	mv	a1,s2
    800024a0:	6928                	ld	a0,80(a0)
    800024a2:	fffff097          	auipc	ra,0xfffff
    800024a6:	254080e7          	jalr	596(ra) # 800016f6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024aa:	70a2                	ld	ra,40(sp)
    800024ac:	7402                	ld	s0,32(sp)
    800024ae:	64e2                	ld	s1,24(sp)
    800024b0:	6942                	ld	s2,16(sp)
    800024b2:	69a2                	ld	s3,8(sp)
    800024b4:	6a02                	ld	s4,0(sp)
    800024b6:	6145                	addi	sp,sp,48
    800024b8:	8082                	ret
    memmove((char *)dst, src, len);
    800024ba:	000a061b          	sext.w	a2,s4
    800024be:	85ce                	mv	a1,s3
    800024c0:	854a                	mv	a0,s2
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	8ce080e7          	jalr	-1842(ra) # 80000d90 <memmove>
    return 0;
    800024ca:	8526                	mv	a0,s1
    800024cc:	bff9                	j	800024aa <either_copyout+0x32>

00000000800024ce <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ce:	7179                	addi	sp,sp,-48
    800024d0:	f406                	sd	ra,40(sp)
    800024d2:	f022                	sd	s0,32(sp)
    800024d4:	ec26                	sd	s1,24(sp)
    800024d6:	e84a                	sd	s2,16(sp)
    800024d8:	e44e                	sd	s3,8(sp)
    800024da:	e052                	sd	s4,0(sp)
    800024dc:	1800                	addi	s0,sp,48
    800024de:	892a                	mv	s2,a0
    800024e0:	84ae                	mv	s1,a1
    800024e2:	89b2                	mv	s3,a2
    800024e4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	51c080e7          	jalr	1308(ra) # 80001a02 <myproc>
  if(user_src){
    800024ee:	c08d                	beqz	s1,80002510 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f0:	86d2                	mv	a3,s4
    800024f2:	864e                	mv	a2,s3
    800024f4:	85ca                	mv	a1,s2
    800024f6:	6928                	ld	a0,80(a0)
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	28a080e7          	jalr	650(ra) # 80001782 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002500:	70a2                	ld	ra,40(sp)
    80002502:	7402                	ld	s0,32(sp)
    80002504:	64e2                	ld	s1,24(sp)
    80002506:	6942                	ld	s2,16(sp)
    80002508:	69a2                	ld	s3,8(sp)
    8000250a:	6a02                	ld	s4,0(sp)
    8000250c:	6145                	addi	sp,sp,48
    8000250e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002510:	000a061b          	sext.w	a2,s4
    80002514:	85ce                	mv	a1,s3
    80002516:	854a                	mv	a0,s2
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	878080e7          	jalr	-1928(ra) # 80000d90 <memmove>
    return 0;
    80002520:	8526                	mv	a0,s1
    80002522:	bff9                	j	80002500 <either_copyin+0x32>

0000000080002524 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002524:	715d                	addi	sp,sp,-80
    80002526:	e486                	sd	ra,72(sp)
    80002528:	e0a2                	sd	s0,64(sp)
    8000252a:	fc26                	sd	s1,56(sp)
    8000252c:	f84a                	sd	s2,48(sp)
    8000252e:	f44e                	sd	s3,40(sp)
    80002530:	f052                	sd	s4,32(sp)
    80002532:	ec56                	sd	s5,24(sp)
    80002534:	e85a                	sd	s6,16(sp)
    80002536:	e45e                	sd	s7,8(sp)
    80002538:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000253a:	00006517          	auipc	a0,0x6
    8000253e:	b8e50513          	addi	a0,a0,-1138 # 800080c8 <digits+0x88>
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	050080e7          	jalr	80(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000254a:	00010497          	auipc	s1,0x10
    8000254e:	97648493          	addi	s1,s1,-1674 # 80011ec0 <proc+0x158>
    80002552:	00015917          	auipc	s2,0x15
    80002556:	56e90913          	addi	s2,s2,1390 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000255a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000255c:	00006997          	auipc	s3,0x6
    80002560:	d0c98993          	addi	s3,s3,-756 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002564:	00006a97          	auipc	s5,0x6
    80002568:	d0ca8a93          	addi	s5,s5,-756 # 80008270 <digits+0x230>
    printf("\n");
    8000256c:	00006a17          	auipc	s4,0x6
    80002570:	b5ca0a13          	addi	s4,s4,-1188 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002574:	00006b97          	auipc	s7,0x6
    80002578:	d34b8b93          	addi	s7,s7,-716 # 800082a8 <states.1707>
    8000257c:	a00d                	j	8000259e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000257e:	ee06a583          	lw	a1,-288(a3)
    80002582:	8556                	mv	a0,s5
    80002584:	ffffe097          	auipc	ra,0xffffe
    80002588:	00e080e7          	jalr	14(ra) # 80000592 <printf>
    printf("\n");
    8000258c:	8552                	mv	a0,s4
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	004080e7          	jalr	4(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002596:	17048493          	addi	s1,s1,368
    8000259a:	03248163          	beq	s1,s2,800025bc <procdump+0x98>
    if(p->state == UNUSED)
    8000259e:	86a6                	mv	a3,s1
    800025a0:	ec04a783          	lw	a5,-320(s1)
    800025a4:	dbed                	beqz	a5,80002596 <procdump+0x72>
      state = "???";
    800025a6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a8:	fcfb6be3          	bltu	s6,a5,8000257e <procdump+0x5a>
    800025ac:	1782                	slli	a5,a5,0x20
    800025ae:	9381                	srli	a5,a5,0x20
    800025b0:	078e                	slli	a5,a5,0x3
    800025b2:	97de                	add	a5,a5,s7
    800025b4:	6390                	ld	a2,0(a5)
    800025b6:	f661                	bnez	a2,8000257e <procdump+0x5a>
      state = "???";
    800025b8:	864e                	mv	a2,s3
    800025ba:	b7d1                	j	8000257e <procdump+0x5a>
  }
}
    800025bc:	60a6                	ld	ra,72(sp)
    800025be:	6406                	ld	s0,64(sp)
    800025c0:	74e2                	ld	s1,56(sp)
    800025c2:	7942                	ld	s2,48(sp)
    800025c4:	79a2                	ld	s3,40(sp)
    800025c6:	7a02                	ld	s4,32(sp)
    800025c8:	6ae2                	ld	s5,24(sp)
    800025ca:	6b42                	ld	s6,16(sp)
    800025cc:	6ba2                	ld	s7,8(sp)
    800025ce:	6161                	addi	sp,sp,80
    800025d0:	8082                	ret

00000000800025d2 <n_proc>:

int n_proc(void)
{
    800025d2:	1141                	addi	sp,sp,-16
    800025d4:	e422                	sd	s0,8(sp)
    800025d6:	0800                	addi	s0,sp,16
  struct proc *p;
  int n = 0;
    800025d8:	4501                	li	a0,0
  for (p = proc; p < &proc[NPROC]; p++) {
    800025da:	0000f797          	auipc	a5,0xf
    800025de:	78e78793          	addi	a5,a5,1934 # 80011d68 <proc>
    800025e2:	00015697          	auipc	a3,0x15
    800025e6:	38668693          	addi	a3,a3,902 # 80017968 <tickslock>
    800025ea:	a029                	j	800025f4 <n_proc+0x22>
    800025ec:	17078793          	addi	a5,a5,368
    800025f0:	00d78663          	beq	a5,a3,800025fc <n_proc+0x2a>
	if (p->state != UNUSED)
    800025f4:	4f98                	lw	a4,24(a5)
    800025f6:	db7d                	beqz	a4,800025ec <n_proc+0x1a>
	  n++;
    800025f8:	2505                	addiw	a0,a0,1
    800025fa:	bfcd                	j	800025ec <n_proc+0x1a>
  }
  return n;
}
    800025fc:	6422                	ld	s0,8(sp)
    800025fe:	0141                	addi	sp,sp,16
    80002600:	8082                	ret

0000000080002602 <swtch>:
    80002602:	00153023          	sd	ra,0(a0)
    80002606:	00253423          	sd	sp,8(a0)
    8000260a:	e900                	sd	s0,16(a0)
    8000260c:	ed04                	sd	s1,24(a0)
    8000260e:	03253023          	sd	s2,32(a0)
    80002612:	03353423          	sd	s3,40(a0)
    80002616:	03453823          	sd	s4,48(a0)
    8000261a:	03553c23          	sd	s5,56(a0)
    8000261e:	05653023          	sd	s6,64(a0)
    80002622:	05753423          	sd	s7,72(a0)
    80002626:	05853823          	sd	s8,80(a0)
    8000262a:	05953c23          	sd	s9,88(a0)
    8000262e:	07a53023          	sd	s10,96(a0)
    80002632:	07b53423          	sd	s11,104(a0)
    80002636:	0005b083          	ld	ra,0(a1)
    8000263a:	0085b103          	ld	sp,8(a1)
    8000263e:	6980                	ld	s0,16(a1)
    80002640:	6d84                	ld	s1,24(a1)
    80002642:	0205b903          	ld	s2,32(a1)
    80002646:	0285b983          	ld	s3,40(a1)
    8000264a:	0305ba03          	ld	s4,48(a1)
    8000264e:	0385ba83          	ld	s5,56(a1)
    80002652:	0405bb03          	ld	s6,64(a1)
    80002656:	0485bb83          	ld	s7,72(a1)
    8000265a:	0505bc03          	ld	s8,80(a1)
    8000265e:	0585bc83          	ld	s9,88(a1)
    80002662:	0605bd03          	ld	s10,96(a1)
    80002666:	0685bd83          	ld	s11,104(a1)
    8000266a:	8082                	ret

000000008000266c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000266c:	1141                	addi	sp,sp,-16
    8000266e:	e406                	sd	ra,8(sp)
    80002670:	e022                	sd	s0,0(sp)
    80002672:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002674:	00006597          	auipc	a1,0x6
    80002678:	c5c58593          	addi	a1,a1,-932 # 800082d0 <states.1707+0x28>
    8000267c:	00015517          	auipc	a0,0x15
    80002680:	2ec50513          	addi	a0,a0,748 # 80017968 <tickslock>
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	520080e7          	jalr	1312(ra) # 80000ba4 <initlock>
}
    8000268c:	60a2                	ld	ra,8(sp)
    8000268e:	6402                	ld	s0,0(sp)
    80002690:	0141                	addi	sp,sp,16
    80002692:	8082                	ret

0000000080002694 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e422                	sd	s0,8(sp)
    80002698:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000269a:	00003797          	auipc	a5,0x3
    8000269e:	59678793          	addi	a5,a5,1430 # 80005c30 <kernelvec>
    800026a2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026a6:	6422                	ld	s0,8(sp)
    800026a8:	0141                	addi	sp,sp,16
    800026aa:	8082                	ret

00000000800026ac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ac:	1141                	addi	sp,sp,-16
    800026ae:	e406                	sd	ra,8(sp)
    800026b0:	e022                	sd	s0,0(sp)
    800026b2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026b4:	fffff097          	auipc	ra,0xfffff
    800026b8:	34e080e7          	jalr	846(ra) # 80001a02 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026c6:	00005617          	auipc	a2,0x5
    800026ca:	93a60613          	addi	a2,a2,-1734 # 80007000 <_trampoline>
    800026ce:	00005697          	auipc	a3,0x5
    800026d2:	93268693          	addi	a3,a3,-1742 # 80007000 <_trampoline>
    800026d6:	8e91                	sub	a3,a3,a2
    800026d8:	040007b7          	lui	a5,0x4000
    800026dc:	17fd                	addi	a5,a5,-1
    800026de:	07b2                	slli	a5,a5,0xc
    800026e0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026e6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026e8:	180026f3          	csrr	a3,satp
    800026ec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026ee:	6d38                	ld	a4,88(a0)
    800026f0:	6134                	ld	a3,64(a0)
    800026f2:	6585                	lui	a1,0x1
    800026f4:	96ae                	add	a3,a3,a1
    800026f6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026f8:	6d38                	ld	a4,88(a0)
    800026fa:	00000697          	auipc	a3,0x0
    800026fe:	13868693          	addi	a3,a3,312 # 80002832 <usertrap>
    80002702:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002704:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002706:	8692                	mv	a3,tp
    80002708:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000270e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002712:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002716:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000271a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000271c:	6f18                	ld	a4,24(a4)
    8000271e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002722:	692c                	ld	a1,80(a0)
    80002724:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002726:	00005717          	auipc	a4,0x5
    8000272a:	96a70713          	addi	a4,a4,-1686 # 80007090 <userret>
    8000272e:	8f11                	sub	a4,a4,a2
    80002730:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002732:	577d                	li	a4,-1
    80002734:	177e                	slli	a4,a4,0x3f
    80002736:	8dd9                	or	a1,a1,a4
    80002738:	02000537          	lui	a0,0x2000
    8000273c:	157d                	addi	a0,a0,-1
    8000273e:	0536                	slli	a0,a0,0xd
    80002740:	9782                	jalr	a5
}
    80002742:	60a2                	ld	ra,8(sp)
    80002744:	6402                	ld	s0,0(sp)
    80002746:	0141                	addi	sp,sp,16
    80002748:	8082                	ret

000000008000274a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000274a:	1101                	addi	sp,sp,-32
    8000274c:	ec06                	sd	ra,24(sp)
    8000274e:	e822                	sd	s0,16(sp)
    80002750:	e426                	sd	s1,8(sp)
    80002752:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002754:	00015497          	auipc	s1,0x15
    80002758:	21448493          	addi	s1,s1,532 # 80017968 <tickslock>
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	4d6080e7          	jalr	1238(ra) # 80000c34 <acquire>
  ticks++;
    80002766:	00007517          	auipc	a0,0x7
    8000276a:	8ba50513          	addi	a0,a0,-1862 # 80009020 <ticks>
    8000276e:	411c                	lw	a5,0(a0)
    80002770:	2785                	addiw	a5,a5,1
    80002772:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002774:	00000097          	auipc	ra,0x0
    80002778:	c28080e7          	jalr	-984(ra) # 8000239c <wakeup>
  release(&tickslock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	56a080e7          	jalr	1386(ra) # 80000ce8 <release>
}
    80002786:	60e2                	ld	ra,24(sp)
    80002788:	6442                	ld	s0,16(sp)
    8000278a:	64a2                	ld	s1,8(sp)
    8000278c:	6105                	addi	sp,sp,32
    8000278e:	8082                	ret

0000000080002790 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002790:	1101                	addi	sp,sp,-32
    80002792:	ec06                	sd	ra,24(sp)
    80002794:	e822                	sd	s0,16(sp)
    80002796:	e426                	sd	s1,8(sp)
    80002798:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000279e:	00074d63          	bltz	a4,800027b8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027a2:	57fd                	li	a5,-1
    800027a4:	17fe                	slli	a5,a5,0x3f
    800027a6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027a8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027aa:	06f70363          	beq	a4,a5,80002810 <devintr+0x80>
  }
}
    800027ae:	60e2                	ld	ra,24(sp)
    800027b0:	6442                	ld	s0,16(sp)
    800027b2:	64a2                	ld	s1,8(sp)
    800027b4:	6105                	addi	sp,sp,32
    800027b6:	8082                	ret
     (scause & 0xff) == 9){
    800027b8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027bc:	46a5                	li	a3,9
    800027be:	fed792e3          	bne	a5,a3,800027a2 <devintr+0x12>
    int irq = plic_claim();
    800027c2:	00003097          	auipc	ra,0x3
    800027c6:	576080e7          	jalr	1398(ra) # 80005d38 <plic_claim>
    800027ca:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027cc:	47a9                	li	a5,10
    800027ce:	02f50763          	beq	a0,a5,800027fc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027d2:	4785                	li	a5,1
    800027d4:	02f50963          	beq	a0,a5,80002806 <devintr+0x76>
    return 1;
    800027d8:	4505                	li	a0,1
    } else if(irq){
    800027da:	d8f1                	beqz	s1,800027ae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027dc:	85a6                	mv	a1,s1
    800027de:	00006517          	auipc	a0,0x6
    800027e2:	afa50513          	addi	a0,a0,-1286 # 800082d8 <states.1707+0x30>
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	dac080e7          	jalr	-596(ra) # 80000592 <printf>
      plic_complete(irq);
    800027ee:	8526                	mv	a0,s1
    800027f0:	00003097          	auipc	ra,0x3
    800027f4:	56c080e7          	jalr	1388(ra) # 80005d5c <plic_complete>
    return 1;
    800027f8:	4505                	li	a0,1
    800027fa:	bf55                	j	800027ae <devintr+0x1e>
      uartintr();
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	1d8080e7          	jalr	472(ra) # 800009d4 <uartintr>
    80002804:	b7ed                	j	800027ee <devintr+0x5e>
      virtio_disk_intr();
    80002806:	00004097          	auipc	ra,0x4
    8000280a:	9f0080e7          	jalr	-1552(ra) # 800061f6 <virtio_disk_intr>
    8000280e:	b7c5                	j	800027ee <devintr+0x5e>
    if(cpuid() == 0){
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	1c6080e7          	jalr	454(ra) # 800019d6 <cpuid>
    80002818:	c901                	beqz	a0,80002828 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000281a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000281e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002820:	14479073          	csrw	sip,a5
    return 2;
    80002824:	4509                	li	a0,2
    80002826:	b761                	j	800027ae <devintr+0x1e>
      clockintr();
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	f22080e7          	jalr	-222(ra) # 8000274a <clockintr>
    80002830:	b7ed                	j	8000281a <devintr+0x8a>

0000000080002832 <usertrap>:
{
    80002832:	1101                	addi	sp,sp,-32
    80002834:	ec06                	sd	ra,24(sp)
    80002836:	e822                	sd	s0,16(sp)
    80002838:	e426                	sd	s1,8(sp)
    8000283a:	e04a                	sd	s2,0(sp)
    8000283c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002842:	1007f793          	andi	a5,a5,256
    80002846:	e3ad                	bnez	a5,800028a8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002848:	00003797          	auipc	a5,0x3
    8000284c:	3e878793          	addi	a5,a5,1000 # 80005c30 <kernelvec>
    80002850:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	1ae080e7          	jalr	430(ra) # 80001a02 <myproc>
    8000285c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000285e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002860:	14102773          	csrr	a4,sepc
    80002864:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002866:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000286a:	47a1                	li	a5,8
    8000286c:	04f71c63          	bne	a4,a5,800028c4 <usertrap+0x92>
    if(p->killed)
    80002870:	591c                	lw	a5,48(a0)
    80002872:	e3b9                	bnez	a5,800028b8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002874:	6cb8                	ld	a4,88(s1)
    80002876:	6f1c                	ld	a5,24(a4)
    80002878:	0791                	addi	a5,a5,4
    8000287a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002880:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002884:	10079073          	csrw	sstatus,a5
    syscall();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	2e0080e7          	jalr	736(ra) # 80002b68 <syscall>
  if(p->killed)
    80002890:	589c                	lw	a5,48(s1)
    80002892:	ebc1                	bnez	a5,80002922 <usertrap+0xf0>
  usertrapret();
    80002894:	00000097          	auipc	ra,0x0
    80002898:	e18080e7          	jalr	-488(ra) # 800026ac <usertrapret>
}
    8000289c:	60e2                	ld	ra,24(sp)
    8000289e:	6442                	ld	s0,16(sp)
    800028a0:	64a2                	ld	s1,8(sp)
    800028a2:	6902                	ld	s2,0(sp)
    800028a4:	6105                	addi	sp,sp,32
    800028a6:	8082                	ret
    panic("usertrap: not from user mode");
    800028a8:	00006517          	auipc	a0,0x6
    800028ac:	a5050513          	addi	a0,a0,-1456 # 800082f8 <states.1707+0x50>
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	c98080e7          	jalr	-872(ra) # 80000548 <panic>
      exit(-1);
    800028b8:	557d                	li	a0,-1
    800028ba:	00000097          	auipc	ra,0x0
    800028be:	816080e7          	jalr	-2026(ra) # 800020d0 <exit>
    800028c2:	bf4d                	j	80002874 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	ecc080e7          	jalr	-308(ra) # 80002790 <devintr>
    800028cc:	892a                	mv	s2,a0
    800028ce:	c501                	beqz	a0,800028d6 <usertrap+0xa4>
  if(p->killed)
    800028d0:	589c                	lw	a5,48(s1)
    800028d2:	c3a1                	beqz	a5,80002912 <usertrap+0xe0>
    800028d4:	a815                	j	80002908 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028da:	5c90                	lw	a2,56(s1)
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	a3c50513          	addi	a0,a0,-1476 # 80008318 <states.1707+0x70>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	cae080e7          	jalr	-850(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a5450513          	addi	a0,a0,-1452 # 80008348 <states.1707+0xa0>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c96080e7          	jalr	-874(ra) # 80000592 <printf>
    p->killed = 1;
    80002904:	4785                	li	a5,1
    80002906:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002908:	557d                	li	a0,-1
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	7c6080e7          	jalr	1990(ra) # 800020d0 <exit>
  if(which_dev == 2)
    80002912:	4789                	li	a5,2
    80002914:	f8f910e3          	bne	s2,a5,80002894 <usertrap+0x62>
    yield();
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	8c2080e7          	jalr	-1854(ra) # 800021da <yield>
    80002920:	bf95                	j	80002894 <usertrap+0x62>
  int which_dev = 0;
    80002922:	4901                	li	s2,0
    80002924:	b7d5                	j	80002908 <usertrap+0xd6>

0000000080002926 <kerneltrap>:
{
    80002926:	7179                	addi	sp,sp,-48
    80002928:	f406                	sd	ra,40(sp)
    8000292a:	f022                	sd	s0,32(sp)
    8000292c:	ec26                	sd	s1,24(sp)
    8000292e:	e84a                	sd	s2,16(sp)
    80002930:	e44e                	sd	s3,8(sp)
    80002932:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002934:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002938:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000293c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002940:	1004f793          	andi	a5,s1,256
    80002944:	cb85                	beqz	a5,80002974 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002946:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000294a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000294c:	ef85                	bnez	a5,80002984 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000294e:	00000097          	auipc	ra,0x0
    80002952:	e42080e7          	jalr	-446(ra) # 80002790 <devintr>
    80002956:	cd1d                	beqz	a0,80002994 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002958:	4789                	li	a5,2
    8000295a:	06f50a63          	beq	a0,a5,800029ce <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000295e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002962:	10049073          	csrw	sstatus,s1
}
    80002966:	70a2                	ld	ra,40(sp)
    80002968:	7402                	ld	s0,32(sp)
    8000296a:	64e2                	ld	s1,24(sp)
    8000296c:	6942                	ld	s2,16(sp)
    8000296e:	69a2                	ld	s3,8(sp)
    80002970:	6145                	addi	sp,sp,48
    80002972:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	9f450513          	addi	a0,a0,-1548 # 80008368 <states.1707+0xc0>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bcc080e7          	jalr	-1076(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002984:	00006517          	auipc	a0,0x6
    80002988:	a0c50513          	addi	a0,a0,-1524 # 80008390 <states.1707+0xe8>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	bbc080e7          	jalr	-1092(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002994:	85ce                	mv	a1,s3
    80002996:	00006517          	auipc	a0,0x6
    8000299a:	a1a50513          	addi	a0,a0,-1510 # 800083b0 <states.1707+0x108>
    8000299e:	ffffe097          	auipc	ra,0xffffe
    800029a2:	bf4080e7          	jalr	-1036(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029aa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	a1250513          	addi	a0,a0,-1518 # 800083c0 <states.1707+0x118>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	bdc080e7          	jalr	-1060(ra) # 80000592 <printf>
    panic("kerneltrap");
    800029be:	00006517          	auipc	a0,0x6
    800029c2:	a1a50513          	addi	a0,a0,-1510 # 800083d8 <states.1707+0x130>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	b82080e7          	jalr	-1150(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	034080e7          	jalr	52(ra) # 80001a02 <myproc>
    800029d6:	d541                	beqz	a0,8000295e <kerneltrap+0x38>
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	02a080e7          	jalr	42(ra) # 80001a02 <myproc>
    800029e0:	4d18                	lw	a4,24(a0)
    800029e2:	478d                	li	a5,3
    800029e4:	f6f71de3          	bne	a4,a5,8000295e <kerneltrap+0x38>
    yield();
    800029e8:	fffff097          	auipc	ra,0xfffff
    800029ec:	7f2080e7          	jalr	2034(ra) # 800021da <yield>
    800029f0:	b7bd                	j	8000295e <kerneltrap+0x38>

00000000800029f2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029f2:	1101                	addi	sp,sp,-32
    800029f4:	ec06                	sd	ra,24(sp)
    800029f6:	e822                	sd	s0,16(sp)
    800029f8:	e426                	sd	s1,8(sp)
    800029fa:	1000                	addi	s0,sp,32
    800029fc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029fe:	fffff097          	auipc	ra,0xfffff
    80002a02:	004080e7          	jalr	4(ra) # 80001a02 <myproc>
  switch (n) {
    80002a06:	4795                	li	a5,5
    80002a08:	0497e163          	bltu	a5,s1,80002a4a <argraw+0x58>
    80002a0c:	048a                	slli	s1,s1,0x2
    80002a0e:	00006717          	auipc	a4,0x6
    80002a12:	ad270713          	addi	a4,a4,-1326 # 800084e0 <states.1707+0x238>
    80002a16:	94ba                	add	s1,s1,a4
    80002a18:	409c                	lw	a5,0(s1)
    80002a1a:	97ba                	add	a5,a5,a4
    80002a1c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a1e:	6d3c                	ld	a5,88(a0)
    80002a20:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6105                	addi	sp,sp,32
    80002a2a:	8082                	ret
    return p->trapframe->a1;
    80002a2c:	6d3c                	ld	a5,88(a0)
    80002a2e:	7fa8                	ld	a0,120(a5)
    80002a30:	bfcd                	j	80002a22 <argraw+0x30>
    return p->trapframe->a2;
    80002a32:	6d3c                	ld	a5,88(a0)
    80002a34:	63c8                	ld	a0,128(a5)
    80002a36:	b7f5                	j	80002a22 <argraw+0x30>
    return p->trapframe->a3;
    80002a38:	6d3c                	ld	a5,88(a0)
    80002a3a:	67c8                	ld	a0,136(a5)
    80002a3c:	b7dd                	j	80002a22 <argraw+0x30>
    return p->trapframe->a4;
    80002a3e:	6d3c                	ld	a5,88(a0)
    80002a40:	6bc8                	ld	a0,144(a5)
    80002a42:	b7c5                	j	80002a22 <argraw+0x30>
    return p->trapframe->a5;
    80002a44:	6d3c                	ld	a5,88(a0)
    80002a46:	6fc8                	ld	a0,152(a5)
    80002a48:	bfe9                	j	80002a22 <argraw+0x30>
  panic("argraw");
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	99e50513          	addi	a0,a0,-1634 # 800083e8 <states.1707+0x140>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	af6080e7          	jalr	-1290(ra) # 80000548 <panic>

0000000080002a5a <fetchaddr>:
{
    80002a5a:	1101                	addi	sp,sp,-32
    80002a5c:	ec06                	sd	ra,24(sp)
    80002a5e:	e822                	sd	s0,16(sp)
    80002a60:	e426                	sd	s1,8(sp)
    80002a62:	e04a                	sd	s2,0(sp)
    80002a64:	1000                	addi	s0,sp,32
    80002a66:	84aa                	mv	s1,a0
    80002a68:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	f98080e7          	jalr	-104(ra) # 80001a02 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a72:	653c                	ld	a5,72(a0)
    80002a74:	02f4f863          	bgeu	s1,a5,80002aa4 <fetchaddr+0x4a>
    80002a78:	00848713          	addi	a4,s1,8
    80002a7c:	02e7e663          	bltu	a5,a4,80002aa8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a80:	46a1                	li	a3,8
    80002a82:	8626                	mv	a2,s1
    80002a84:	85ca                	mv	a1,s2
    80002a86:	6928                	ld	a0,80(a0)
    80002a88:	fffff097          	auipc	ra,0xfffff
    80002a8c:	cfa080e7          	jalr	-774(ra) # 80001782 <copyin>
    80002a90:	00a03533          	snez	a0,a0
    80002a94:	40a00533          	neg	a0,a0
}
    80002a98:	60e2                	ld	ra,24(sp)
    80002a9a:	6442                	ld	s0,16(sp)
    80002a9c:	64a2                	ld	s1,8(sp)
    80002a9e:	6902                	ld	s2,0(sp)
    80002aa0:	6105                	addi	sp,sp,32
    80002aa2:	8082                	ret
    return -1;
    80002aa4:	557d                	li	a0,-1
    80002aa6:	bfcd                	j	80002a98 <fetchaddr+0x3e>
    80002aa8:	557d                	li	a0,-1
    80002aaa:	b7fd                	j	80002a98 <fetchaddr+0x3e>

0000000080002aac <fetchstr>:
{
    80002aac:	7179                	addi	sp,sp,-48
    80002aae:	f406                	sd	ra,40(sp)
    80002ab0:	f022                	sd	s0,32(sp)
    80002ab2:	ec26                	sd	s1,24(sp)
    80002ab4:	e84a                	sd	s2,16(sp)
    80002ab6:	e44e                	sd	s3,8(sp)
    80002ab8:	1800                	addi	s0,sp,48
    80002aba:	892a                	mv	s2,a0
    80002abc:	84ae                	mv	s1,a1
    80002abe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	f42080e7          	jalr	-190(ra) # 80001a02 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ac8:	86ce                	mv	a3,s3
    80002aca:	864a                	mv	a2,s2
    80002acc:	85a6                	mv	a1,s1
    80002ace:	6928                	ld	a0,80(a0)
    80002ad0:	fffff097          	auipc	ra,0xfffff
    80002ad4:	d3e080e7          	jalr	-706(ra) # 8000180e <copyinstr>
  if(err < 0)
    80002ad8:	00054763          	bltz	a0,80002ae6 <fetchstr+0x3a>
  return strlen(buf);
    80002adc:	8526                	mv	a0,s1
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	3da080e7          	jalr	986(ra) # 80000eb8 <strlen>
}
    80002ae6:	70a2                	ld	ra,40(sp)
    80002ae8:	7402                	ld	s0,32(sp)
    80002aea:	64e2                	ld	s1,24(sp)
    80002aec:	6942                	ld	s2,16(sp)
    80002aee:	69a2                	ld	s3,8(sp)
    80002af0:	6145                	addi	sp,sp,48
    80002af2:	8082                	ret

0000000080002af4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002af4:	1101                	addi	sp,sp,-32
    80002af6:	ec06                	sd	ra,24(sp)
    80002af8:	e822                	sd	s0,16(sp)
    80002afa:	e426                	sd	s1,8(sp)
    80002afc:	1000                	addi	s0,sp,32
    80002afe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	ef2080e7          	jalr	-270(ra) # 800029f2 <argraw>
    80002b08:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b0a:	4501                	li	a0,0
    80002b0c:	60e2                	ld	ra,24(sp)
    80002b0e:	6442                	ld	s0,16(sp)
    80002b10:	64a2                	ld	s1,8(sp)
    80002b12:	6105                	addi	sp,sp,32
    80002b14:	8082                	ret

0000000080002b16 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	1000                	addi	s0,sp,32
    80002b20:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b22:	00000097          	auipc	ra,0x0
    80002b26:	ed0080e7          	jalr	-304(ra) # 800029f2 <argraw>
    80002b2a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b2c:	4501                	li	a0,0
    80002b2e:	60e2                	ld	ra,24(sp)
    80002b30:	6442                	ld	s0,16(sp)
    80002b32:	64a2                	ld	s1,8(sp)
    80002b34:	6105                	addi	sp,sp,32
    80002b36:	8082                	ret

0000000080002b38 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b38:	1101                	addi	sp,sp,-32
    80002b3a:	ec06                	sd	ra,24(sp)
    80002b3c:	e822                	sd	s0,16(sp)
    80002b3e:	e426                	sd	s1,8(sp)
    80002b40:	e04a                	sd	s2,0(sp)
    80002b42:	1000                	addi	s0,sp,32
    80002b44:	84ae                	mv	s1,a1
    80002b46:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b48:	00000097          	auipc	ra,0x0
    80002b4c:	eaa080e7          	jalr	-342(ra) # 800029f2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b50:	864a                	mv	a2,s2
    80002b52:	85a6                	mv	a1,s1
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	f58080e7          	jalr	-168(ra) # 80002aac <fetchstr>
}
    80002b5c:	60e2                	ld	ra,24(sp)
    80002b5e:	6442                	ld	s0,16(sp)
    80002b60:	64a2                	ld	s1,8(sp)
    80002b62:	6902                	ld	s2,0(sp)
    80002b64:	6105                	addi	sp,sp,32
    80002b66:	8082                	ret

0000000080002b68 <syscall>:
[SYS_sysinfo] "sys_info",
};

void
syscall(void)
{
    80002b68:	7179                	addi	sp,sp,-48
    80002b6a:	f406                	sd	ra,40(sp)
    80002b6c:	f022                	sd	s0,32(sp)
    80002b6e:	ec26                	sd	s1,24(sp)
    80002b70:	e84a                	sd	s2,16(sp)
    80002b72:	e44e                	sd	s3,8(sp)
    80002b74:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	e8c080e7          	jalr	-372(ra) # 80001a02 <myproc>
    80002b7e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b80:	05853903          	ld	s2,88(a0)
    80002b84:	0a893783          	ld	a5,168(s2)
    80002b88:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b8c:	37fd                	addiw	a5,a5,-1
    80002b8e:	4759                	li	a4,22
    80002b90:	04f76863          	bltu	a4,a5,80002be0 <syscall+0x78>
    80002b94:	00399713          	slli	a4,s3,0x3
    80002b98:	00006797          	auipc	a5,0x6
    80002b9c:	96078793          	addi	a5,a5,-1696 # 800084f8 <syscalls>
    80002ba0:	97ba                	add	a5,a5,a4
    80002ba2:	639c                	ld	a5,0(a5)
    80002ba4:	cf95                	beqz	a5,80002be0 <syscall+0x78>
    p->trapframe->a0 = syscalls[num]();
    80002ba6:	9782                	jalr	a5
    80002ba8:	06a93823          	sd	a0,112(s2)
	if ((1 << num) & p->mask) {
    80002bac:	1684a783          	lw	a5,360(s1)
    80002bb0:	4137d7bb          	sraw	a5,a5,s3
    80002bb4:	8b85                	andi	a5,a5,1
    80002bb6:	c7a1                	beqz	a5,80002bfe <syscall+0x96>
	  printf("%d: syscall %s -> %d\n", p->pid, syscalls_name[num], p->trapframe->a0);
    80002bb8:	6cb8                	ld	a4,88(s1)
    80002bba:	098e                	slli	s3,s3,0x3
    80002bbc:	00006797          	auipc	a5,0x6
    80002bc0:	d7c78793          	addi	a5,a5,-644 # 80008938 <syscalls_name>
    80002bc4:	99be                	add	s3,s3,a5
    80002bc6:	7b34                	ld	a3,112(a4)
    80002bc8:	0009b603          	ld	a2,0(s3)
    80002bcc:	5c8c                	lw	a1,56(s1)
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	82250513          	addi	a0,a0,-2014 # 800083f0 <states.1707+0x148>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	9bc080e7          	jalr	-1604(ra) # 80000592 <printf>
    80002bde:	a005                	j	80002bfe <syscall+0x96>
	}
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002be0:	86ce                	mv	a3,s3
    80002be2:	15848613          	addi	a2,s1,344
    80002be6:	5c8c                	lw	a1,56(s1)
    80002be8:	00006517          	auipc	a0,0x6
    80002bec:	82050513          	addi	a0,a0,-2016 # 80008408 <states.1707+0x160>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	9a2080e7          	jalr	-1630(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bf8:	6cbc                	ld	a5,88(s1)
    80002bfa:	577d                	li	a4,-1
    80002bfc:	fbb8                	sd	a4,112(a5)
  }
}
    80002bfe:	70a2                	ld	ra,40(sp)
    80002c00:	7402                	ld	s0,32(sp)
    80002c02:	64e2                	ld	s1,24(sp)
    80002c04:	6942                	ld	s2,16(sp)
    80002c06:	69a2                	ld	s3,8(sp)
    80002c08:	6145                	addi	sp,sp,48
    80002c0a:	8082                	ret

0000000080002c0c <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002c0c:	1101                	addi	sp,sp,-32
    80002c0e:	ec06                	sd	ra,24(sp)
    80002c10:	e822                	sd	s0,16(sp)
    80002c12:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c14:	fec40593          	addi	a1,s0,-20
    80002c18:	4501                	li	a0,0
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	eda080e7          	jalr	-294(ra) # 80002af4 <argint>
    return -1;
    80002c22:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c24:	00054963          	bltz	a0,80002c36 <sys_exit+0x2a>
  exit(n);
    80002c28:	fec42503          	lw	a0,-20(s0)
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	4a4080e7          	jalr	1188(ra) # 800020d0 <exit>
  return 0;  // not reached
    80002c34:	4781                	li	a5,0
}
    80002c36:	853e                	mv	a0,a5
    80002c38:	60e2                	ld	ra,24(sp)
    80002c3a:	6442                	ld	s0,16(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c40:	1141                	addi	sp,sp,-16
    80002c42:	e406                	sd	ra,8(sp)
    80002c44:	e022                	sd	s0,0(sp)
    80002c46:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	dba080e7          	jalr	-582(ra) # 80001a02 <myproc>
}
    80002c50:	5d08                	lw	a0,56(a0)
    80002c52:	60a2                	ld	ra,8(sp)
    80002c54:	6402                	ld	s0,0(sp)
    80002c56:	0141                	addi	sp,sp,16
    80002c58:	8082                	ret

0000000080002c5a <sys_fork>:

uint64
sys_fork(void)
{
    80002c5a:	1141                	addi	sp,sp,-16
    80002c5c:	e406                	sd	ra,8(sp)
    80002c5e:	e022                	sd	s0,0(sp)
    80002c60:	0800                	addi	s0,sp,16
  return fork();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	160080e7          	jalr	352(ra) # 80001dc2 <fork>
}
    80002c6a:	60a2                	ld	ra,8(sp)
    80002c6c:	6402                	ld	s0,0(sp)
    80002c6e:	0141                	addi	sp,sp,16
    80002c70:	8082                	ret

0000000080002c72 <sys_wait>:

uint64
sys_wait(void)
{
    80002c72:	1101                	addi	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c7a:	fe840593          	addi	a1,s0,-24
    80002c7e:	4501                	li	a0,0
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	e96080e7          	jalr	-362(ra) # 80002b16 <argaddr>
    80002c88:	87aa                	mv	a5,a0
    return -1;
    80002c8a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c8c:	0007c863          	bltz	a5,80002c9c <sys_wait+0x2a>
  return wait(p);
    80002c90:	fe843503          	ld	a0,-24(s0)
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	600080e7          	jalr	1536(ra) # 80002294 <wait>
}
    80002c9c:	60e2                	ld	ra,24(sp)
    80002c9e:	6442                	ld	s0,16(sp)
    80002ca0:	6105                	addi	sp,sp,32
    80002ca2:	8082                	ret

0000000080002ca4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002ca4:	7179                	addi	sp,sp,-48
    80002ca6:	f406                	sd	ra,40(sp)
    80002ca8:	f022                	sd	s0,32(sp)
    80002caa:	ec26                	sd	s1,24(sp)
    80002cac:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cae:	fdc40593          	addi	a1,s0,-36
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	e40080e7          	jalr	-448(ra) # 80002af4 <argint>
    80002cbc:	87aa                	mv	a5,a0
    return -1;
    80002cbe:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cc0:	0207c063          	bltz	a5,80002ce0 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	d3e080e7          	jalr	-706(ra) # 80001a02 <myproc>
    80002ccc:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cce:	fdc42503          	lw	a0,-36(s0)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	07c080e7          	jalr	124(ra) # 80001d4e <growproc>
    80002cda:	00054863          	bltz	a0,80002cea <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cde:	8526                	mv	a0,s1
}
    80002ce0:	70a2                	ld	ra,40(sp)
    80002ce2:	7402                	ld	s0,32(sp)
    80002ce4:	64e2                	ld	s1,24(sp)
    80002ce6:	6145                	addi	sp,sp,48
    80002ce8:	8082                	ret
    return -1;
    80002cea:	557d                	li	a0,-1
    80002cec:	bfd5                	j	80002ce0 <sys_sbrk+0x3c>

0000000080002cee <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cee:	7139                	addi	sp,sp,-64
    80002cf0:	fc06                	sd	ra,56(sp)
    80002cf2:	f822                	sd	s0,48(sp)
    80002cf4:	f426                	sd	s1,40(sp)
    80002cf6:	f04a                	sd	s2,32(sp)
    80002cf8:	ec4e                	sd	s3,24(sp)
    80002cfa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002cfc:	fcc40593          	addi	a1,s0,-52
    80002d00:	4501                	li	a0,0
    80002d02:	00000097          	auipc	ra,0x0
    80002d06:	df2080e7          	jalr	-526(ra) # 80002af4 <argint>
    return -1;
    80002d0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d0c:	06054563          	bltz	a0,80002d76 <sys_sleep+0x88>
  acquire(&tickslock);
    80002d10:	00015517          	auipc	a0,0x15
    80002d14:	c5850513          	addi	a0,a0,-936 # 80017968 <tickslock>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	f1c080e7          	jalr	-228(ra) # 80000c34 <acquire>
  ticks0 = ticks;
    80002d20:	00006917          	auipc	s2,0x6
    80002d24:	30092903          	lw	s2,768(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d28:	fcc42783          	lw	a5,-52(s0)
    80002d2c:	cf85                	beqz	a5,80002d64 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d2e:	00015997          	auipc	s3,0x15
    80002d32:	c3a98993          	addi	s3,s3,-966 # 80017968 <tickslock>
    80002d36:	00006497          	auipc	s1,0x6
    80002d3a:	2ea48493          	addi	s1,s1,746 # 80009020 <ticks>
    if(myproc()->killed){
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	cc4080e7          	jalr	-828(ra) # 80001a02 <myproc>
    80002d46:	591c                	lw	a5,48(a0)
    80002d48:	ef9d                	bnez	a5,80002d86 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d4a:	85ce                	mv	a1,s3
    80002d4c:	8526                	mv	a0,s1
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	4c8080e7          	jalr	1224(ra) # 80002216 <sleep>
  while(ticks - ticks0 < n){
    80002d56:	409c                	lw	a5,0(s1)
    80002d58:	412787bb          	subw	a5,a5,s2
    80002d5c:	fcc42703          	lw	a4,-52(s0)
    80002d60:	fce7efe3          	bltu	a5,a4,80002d3e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d64:	00015517          	auipc	a0,0x15
    80002d68:	c0450513          	addi	a0,a0,-1020 # 80017968 <tickslock>
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	f7c080e7          	jalr	-132(ra) # 80000ce8 <release>
  return 0;
    80002d74:	4781                	li	a5,0
}
    80002d76:	853e                	mv	a0,a5
    80002d78:	70e2                	ld	ra,56(sp)
    80002d7a:	7442                	ld	s0,48(sp)
    80002d7c:	74a2                	ld	s1,40(sp)
    80002d7e:	7902                	ld	s2,32(sp)
    80002d80:	69e2                	ld	s3,24(sp)
    80002d82:	6121                	addi	sp,sp,64
    80002d84:	8082                	ret
      release(&tickslock);
    80002d86:	00015517          	auipc	a0,0x15
    80002d8a:	be250513          	addi	a0,a0,-1054 # 80017968 <tickslock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	f5a080e7          	jalr	-166(ra) # 80000ce8 <release>
      return -1;
    80002d96:	57fd                	li	a5,-1
    80002d98:	bff9                	j	80002d76 <sys_sleep+0x88>

0000000080002d9a <sys_kill>:

uint64
sys_kill(void)
{
    80002d9a:	1101                	addi	sp,sp,-32
    80002d9c:	ec06                	sd	ra,24(sp)
    80002d9e:	e822                	sd	s0,16(sp)
    80002da0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002da2:	fec40593          	addi	a1,s0,-20
    80002da6:	4501                	li	a0,0
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	d4c080e7          	jalr	-692(ra) # 80002af4 <argint>
    80002db0:	87aa                	mv	a5,a0
    return -1;
    80002db2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002db4:	0007c863          	bltz	a5,80002dc4 <sys_kill+0x2a>
  return kill(pid);
    80002db8:	fec42503          	lw	a0,-20(s0)
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	64a080e7          	jalr	1610(ra) # 80002406 <kill>
}
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dd6:	00015517          	auipc	a0,0x15
    80002dda:	b9250513          	addi	a0,a0,-1134 # 80017968 <tickslock>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	e56080e7          	jalr	-426(ra) # 80000c34 <acquire>
  xticks = ticks;
    80002de6:	00006497          	auipc	s1,0x6
    80002dea:	23a4a483          	lw	s1,570(s1) # 80009020 <ticks>
  release(&tickslock);
    80002dee:	00015517          	auipc	a0,0x15
    80002df2:	b7a50513          	addi	a0,a0,-1158 # 80017968 <tickslock>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	ef2080e7          	jalr	-270(ra) # 80000ce8 <release>
  return xticks;
}
    80002dfe:	02049513          	slli	a0,s1,0x20
    80002e02:	9101                	srli	a0,a0,0x20
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <sys_trace>:

uint64 sys_trace(void)
{
    80002e0e:	1101                	addi	sp,sp,-32
    80002e10:	ec06                	sd	ra,24(sp)
    80002e12:	e822                	sd	s0,16(sp)
    80002e14:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0) 
    80002e16:	fec40593          	addi	a1,s0,-20
    80002e1a:	4501                	li	a0,0
    80002e1c:	00000097          	auipc	ra,0x0
    80002e20:	cd8080e7          	jalr	-808(ra) # 80002af4 <argint>
	return -1;
    80002e24:	57fd                	li	a5,-1
  if(argint(0, &mask) < 0) 
    80002e26:	00054b63          	bltz	a0,80002e3c <sys_trace+0x2e>
  myproc()->mask = mask;
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	bd8080e7          	jalr	-1064(ra) # 80001a02 <myproc>
    80002e32:	fec42783          	lw	a5,-20(s0)
    80002e36:	16f52423          	sw	a5,360(a0)
  return 0;
    80002e3a:	4781                	li	a5,0
}
    80002e3c:	853e                	mv	a0,a5
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	6105                	addi	sp,sp,32
    80002e44:	8082                	ret

0000000080002e46 <sys_sysinfo>:

uint64 sys_sysinfo(void)
{
    80002e46:	7139                	addi	sp,sp,-64
    80002e48:	fc06                	sd	ra,56(sp)
    80002e4a:	f822                	sd	s0,48(sp)
    80002e4c:	f426                	sd	s1,40(sp)
    80002e4e:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 addr;
  struct proc* p = myproc();
    80002e50:	fffff097          	auipc	ra,0xfffff
    80002e54:	bb2080e7          	jalr	-1102(ra) # 80001a02 <myproc>
    80002e58:	84aa                	mv	s1,a0
  if(argaddr(0, &addr) < 0) {
    80002e5a:	fc840593          	addi	a1,s0,-56
    80002e5e:	4501                	li	a0,0
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	cb6080e7          	jalr	-842(ra) # 80002b16 <argaddr>
    return -1;
    80002e68:	57fd                	li	a5,-1
  if(argaddr(0, &addr) < 0) {
    80002e6a:	02054a63          	bltz	a0,80002e9e <sys_sysinfo+0x58>
  }
  info.freemem = free_mem();
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	d12080e7          	jalr	-750(ra) # 80000b80 <free_mem>
    80002e76:	fca43823          	sd	a0,-48(s0)
  info.nproc = n_proc();
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	758080e7          	jalr	1880(ra) # 800025d2 <n_proc>
    80002e82:	fca43c23          	sd	a0,-40(s0)
  if (copyout(p->pagetable, addr, (char*)&info, sizeof(info)) < 0) {
    80002e86:	46c1                	li	a3,16
    80002e88:	fd040613          	addi	a2,s0,-48
    80002e8c:	fc843583          	ld	a1,-56(s0)
    80002e90:	68a8                	ld	a0,80(s1)
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	864080e7          	jalr	-1948(ra) # 800016f6 <copyout>
    80002e9a:	43f55793          	srai	a5,a0,0x3f
    return -1;
  }
  return 0;
}
    80002e9e:	853e                	mv	a0,a5
    80002ea0:	70e2                	ld	ra,56(sp)
    80002ea2:	7442                	ld	s0,48(sp)
    80002ea4:	74a2                	ld	s1,40(sp)
    80002ea6:	6121                	addi	sp,sp,64
    80002ea8:	8082                	ret

0000000080002eaa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eaa:	7179                	addi	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	e84a                	sd	s2,16(sp)
    80002eb4:	e44e                	sd	s3,8(sp)
    80002eb6:	e052                	sd	s4,0(sp)
    80002eb8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eba:	00005597          	auipc	a1,0x5
    80002ebe:	6fe58593          	addi	a1,a1,1790 # 800085b8 <syscalls+0xc0>
    80002ec2:	00015517          	auipc	a0,0x15
    80002ec6:	abe50513          	addi	a0,a0,-1346 # 80017980 <bcache>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	cda080e7          	jalr	-806(ra) # 80000ba4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed2:	0001d797          	auipc	a5,0x1d
    80002ed6:	aae78793          	addi	a5,a5,-1362 # 8001f980 <bcache+0x8000>
    80002eda:	0001d717          	auipc	a4,0x1d
    80002ede:	d0e70713          	addi	a4,a4,-754 # 8001fbe8 <bcache+0x8268>
    80002ee2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eea:	00015497          	auipc	s1,0x15
    80002eee:	aae48493          	addi	s1,s1,-1362 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef6:	00005a17          	auipc	s4,0x5
    80002efa:	6caa0a13          	addi	s4,s4,1738 # 800085c0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002efe:	2b893783          	ld	a5,696(s2)
    80002f02:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f04:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f08:	85d2                	mv	a1,s4
    80002f0a:	01048513          	addi	a0,s1,16
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	4ac080e7          	jalr	1196(ra) # 800043ba <initsleeplock>
    bcache.head.next->prev = b;
    80002f16:	2b893783          	ld	a5,696(s2)
    80002f1a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f20:	45848493          	addi	s1,s1,1112
    80002f24:	fd349de3          	bne	s1,s3,80002efe <binit+0x54>
  }
}
    80002f28:	70a2                	ld	ra,40(sp)
    80002f2a:	7402                	ld	s0,32(sp)
    80002f2c:	64e2                	ld	s1,24(sp)
    80002f2e:	6942                	ld	s2,16(sp)
    80002f30:	69a2                	ld	s3,8(sp)
    80002f32:	6a02                	ld	s4,0(sp)
    80002f34:	6145                	addi	sp,sp,48
    80002f36:	8082                	ret

0000000080002f38 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	e84a                	sd	s2,16(sp)
    80002f42:	e44e                	sd	s3,8(sp)
    80002f44:	1800                	addi	s0,sp,48
    80002f46:	89aa                	mv	s3,a0
    80002f48:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f4a:	00015517          	auipc	a0,0x15
    80002f4e:	a3650513          	addi	a0,a0,-1482 # 80017980 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	ce2080e7          	jalr	-798(ra) # 80000c34 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f5a:	0001d497          	auipc	s1,0x1d
    80002f5e:	cde4b483          	ld	s1,-802(s1) # 8001fc38 <bcache+0x82b8>
    80002f62:	0001d797          	auipc	a5,0x1d
    80002f66:	c8678793          	addi	a5,a5,-890 # 8001fbe8 <bcache+0x8268>
    80002f6a:	02f48f63          	beq	s1,a5,80002fa8 <bread+0x70>
    80002f6e:	873e                	mv	a4,a5
    80002f70:	a021                	j	80002f78 <bread+0x40>
    80002f72:	68a4                	ld	s1,80(s1)
    80002f74:	02e48a63          	beq	s1,a4,80002fa8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f78:	449c                	lw	a5,8(s1)
    80002f7a:	ff379ce3          	bne	a5,s3,80002f72 <bread+0x3a>
    80002f7e:	44dc                	lw	a5,12(s1)
    80002f80:	ff2799e3          	bne	a5,s2,80002f72 <bread+0x3a>
      b->refcnt++;
    80002f84:	40bc                	lw	a5,64(s1)
    80002f86:	2785                	addiw	a5,a5,1
    80002f88:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f8a:	00015517          	auipc	a0,0x15
    80002f8e:	9f650513          	addi	a0,a0,-1546 # 80017980 <bcache>
    80002f92:	ffffe097          	auipc	ra,0xffffe
    80002f96:	d56080e7          	jalr	-682(ra) # 80000ce8 <release>
      acquiresleep(&b->lock);
    80002f9a:	01048513          	addi	a0,s1,16
    80002f9e:	00001097          	auipc	ra,0x1
    80002fa2:	456080e7          	jalr	1110(ra) # 800043f4 <acquiresleep>
      return b;
    80002fa6:	a8b9                	j	80003004 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa8:	0001d497          	auipc	s1,0x1d
    80002fac:	c884b483          	ld	s1,-888(s1) # 8001fc30 <bcache+0x82b0>
    80002fb0:	0001d797          	auipc	a5,0x1d
    80002fb4:	c3878793          	addi	a5,a5,-968 # 8001fbe8 <bcache+0x8268>
    80002fb8:	00f48863          	beq	s1,a5,80002fc8 <bread+0x90>
    80002fbc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fbe:	40bc                	lw	a5,64(s1)
    80002fc0:	cf81                	beqz	a5,80002fd8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc2:	64a4                	ld	s1,72(s1)
    80002fc4:	fee49de3          	bne	s1,a4,80002fbe <bread+0x86>
  panic("bget: no buffers");
    80002fc8:	00005517          	auipc	a0,0x5
    80002fcc:	60050513          	addi	a0,a0,1536 # 800085c8 <syscalls+0xd0>
    80002fd0:	ffffd097          	auipc	ra,0xffffd
    80002fd4:	578080e7          	jalr	1400(ra) # 80000548 <panic>
      b->dev = dev;
    80002fd8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fdc:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fe0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe4:	4785                	li	a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00015517          	auipc	a0,0x15
    80002fec:	99850513          	addi	a0,a0,-1640 # 80017980 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	cf8080e7          	jalr	-776(ra) # 80000ce8 <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	3f8080e7          	jalr	1016(ra) # 800043f4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003004:	409c                	lw	a5,0(s1)
    80003006:	cb89                	beqz	a5,80003018 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003008:	8526                	mv	a0,s1
    8000300a:	70a2                	ld	ra,40(sp)
    8000300c:	7402                	ld	s0,32(sp)
    8000300e:	64e2                	ld	s1,24(sp)
    80003010:	6942                	ld	s2,16(sp)
    80003012:	69a2                	ld	s3,8(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret
    virtio_disk_rw(b, 0);
    80003018:	4581                	li	a1,0
    8000301a:	8526                	mv	a0,s1
    8000301c:	00003097          	auipc	ra,0x3
    80003020:	f30080e7          	jalr	-208(ra) # 80005f4c <virtio_disk_rw>
    b->valid = 1;
    80003024:	4785                	li	a5,1
    80003026:	c09c                	sw	a5,0(s1)
  return b;
    80003028:	b7c5                	j	80003008 <bread+0xd0>

000000008000302a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	e426                	sd	s1,8(sp)
    80003032:	1000                	addi	s0,sp,32
    80003034:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003036:	0541                	addi	a0,a0,16
    80003038:	00001097          	auipc	ra,0x1
    8000303c:	456080e7          	jalr	1110(ra) # 8000448e <holdingsleep>
    80003040:	cd01                	beqz	a0,80003058 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003042:	4585                	li	a1,1
    80003044:	8526                	mv	a0,s1
    80003046:	00003097          	auipc	ra,0x3
    8000304a:	f06080e7          	jalr	-250(ra) # 80005f4c <virtio_disk_rw>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6105                	addi	sp,sp,32
    80003056:	8082                	ret
    panic("bwrite");
    80003058:	00005517          	auipc	a0,0x5
    8000305c:	58850513          	addi	a0,a0,1416 # 800085e0 <syscalls+0xe8>
    80003060:	ffffd097          	auipc	ra,0xffffd
    80003064:	4e8080e7          	jalr	1256(ra) # 80000548 <panic>

0000000080003068 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	e04a                	sd	s2,0(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003076:	01050913          	addi	s2,a0,16
    8000307a:	854a                	mv	a0,s2
    8000307c:	00001097          	auipc	ra,0x1
    80003080:	412080e7          	jalr	1042(ra) # 8000448e <holdingsleep>
    80003084:	c92d                	beqz	a0,800030f6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003086:	854a                	mv	a0,s2
    80003088:	00001097          	auipc	ra,0x1
    8000308c:	3c2080e7          	jalr	962(ra) # 8000444a <releasesleep>

  acquire(&bcache.lock);
    80003090:	00015517          	auipc	a0,0x15
    80003094:	8f050513          	addi	a0,a0,-1808 # 80017980 <bcache>
    80003098:	ffffe097          	auipc	ra,0xffffe
    8000309c:	b9c080e7          	jalr	-1124(ra) # 80000c34 <acquire>
  b->refcnt--;
    800030a0:	40bc                	lw	a5,64(s1)
    800030a2:	37fd                	addiw	a5,a5,-1
    800030a4:	0007871b          	sext.w	a4,a5
    800030a8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030aa:	eb05                	bnez	a4,800030da <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ac:	68bc                	ld	a5,80(s1)
    800030ae:	64b8                	ld	a4,72(s1)
    800030b0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b2:	64bc                	ld	a5,72(s1)
    800030b4:	68b8                	ld	a4,80(s1)
    800030b6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b8:	0001d797          	auipc	a5,0x1d
    800030bc:	8c878793          	addi	a5,a5,-1848 # 8001f980 <bcache+0x8000>
    800030c0:	2b87b703          	ld	a4,696(a5)
    800030c4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c6:	0001d717          	auipc	a4,0x1d
    800030ca:	b2270713          	addi	a4,a4,-1246 # 8001fbe8 <bcache+0x8268>
    800030ce:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030d0:	2b87b703          	ld	a4,696(a5)
    800030d4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030da:	00015517          	auipc	a0,0x15
    800030de:	8a650513          	addi	a0,a0,-1882 # 80017980 <bcache>
    800030e2:	ffffe097          	auipc	ra,0xffffe
    800030e6:	c06080e7          	jalr	-1018(ra) # 80000ce8 <release>
}
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	64a2                	ld	s1,8(sp)
    800030f0:	6902                	ld	s2,0(sp)
    800030f2:	6105                	addi	sp,sp,32
    800030f4:	8082                	ret
    panic("brelse");
    800030f6:	00005517          	auipc	a0,0x5
    800030fa:	4f250513          	addi	a0,a0,1266 # 800085e8 <syscalls+0xf0>
    800030fe:	ffffd097          	auipc	ra,0xffffd
    80003102:	44a080e7          	jalr	1098(ra) # 80000548 <panic>

0000000080003106 <bpin>:

void
bpin(struct buf *b) {
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
    80003110:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003112:	00015517          	auipc	a0,0x15
    80003116:	86e50513          	addi	a0,a0,-1938 # 80017980 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	b1a080e7          	jalr	-1254(ra) # 80000c34 <acquire>
  b->refcnt++;
    80003122:	40bc                	lw	a5,64(s1)
    80003124:	2785                	addiw	a5,a5,1
    80003126:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003128:	00015517          	auipc	a0,0x15
    8000312c:	85850513          	addi	a0,a0,-1960 # 80017980 <bcache>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	bb8080e7          	jalr	-1096(ra) # 80000ce8 <release>
}
    80003138:	60e2                	ld	ra,24(sp)
    8000313a:	6442                	ld	s0,16(sp)
    8000313c:	64a2                	ld	s1,8(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <bunpin>:

void
bunpin(struct buf *b) {
    80003142:	1101                	addi	sp,sp,-32
    80003144:	ec06                	sd	ra,24(sp)
    80003146:	e822                	sd	s0,16(sp)
    80003148:	e426                	sd	s1,8(sp)
    8000314a:	1000                	addi	s0,sp,32
    8000314c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314e:	00015517          	auipc	a0,0x15
    80003152:	83250513          	addi	a0,a0,-1998 # 80017980 <bcache>
    80003156:	ffffe097          	auipc	ra,0xffffe
    8000315a:	ade080e7          	jalr	-1314(ra) # 80000c34 <acquire>
  b->refcnt--;
    8000315e:	40bc                	lw	a5,64(s1)
    80003160:	37fd                	addiw	a5,a5,-1
    80003162:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003164:	00015517          	auipc	a0,0x15
    80003168:	81c50513          	addi	a0,a0,-2020 # 80017980 <bcache>
    8000316c:	ffffe097          	auipc	ra,0xffffe
    80003170:	b7c080e7          	jalr	-1156(ra) # 80000ce8 <release>
}
    80003174:	60e2                	ld	ra,24(sp)
    80003176:	6442                	ld	s0,16(sp)
    80003178:	64a2                	ld	s1,8(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret

000000008000317e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000317e:	1101                	addi	sp,sp,-32
    80003180:	ec06                	sd	ra,24(sp)
    80003182:	e822                	sd	s0,16(sp)
    80003184:	e426                	sd	s1,8(sp)
    80003186:	e04a                	sd	s2,0(sp)
    80003188:	1000                	addi	s0,sp,32
    8000318a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000318c:	00d5d59b          	srliw	a1,a1,0xd
    80003190:	0001d797          	auipc	a5,0x1d
    80003194:	ecc7a783          	lw	a5,-308(a5) # 8002005c <sb+0x1c>
    80003198:	9dbd                	addw	a1,a1,a5
    8000319a:	00000097          	auipc	ra,0x0
    8000319e:	d9e080e7          	jalr	-610(ra) # 80002f38 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a2:	0074f713          	andi	a4,s1,7
    800031a6:	4785                	li	a5,1
    800031a8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ac:	14ce                	slli	s1,s1,0x33
    800031ae:	90d9                	srli	s1,s1,0x36
    800031b0:	00950733          	add	a4,a0,s1
    800031b4:	05874703          	lbu	a4,88(a4)
    800031b8:	00e7f6b3          	and	a3,a5,a4
    800031bc:	c69d                	beqz	a3,800031ea <bfree+0x6c>
    800031be:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031c0:	94aa                	add	s1,s1,a0
    800031c2:	fff7c793          	not	a5,a5
    800031c6:	8ff9                	and	a5,a5,a4
    800031c8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	100080e7          	jalr	256(ra) # 800042cc <log_write>
  brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	e92080e7          	jalr	-366(ra) # 80003068 <brelse>
}
    800031de:	60e2                	ld	ra,24(sp)
    800031e0:	6442                	ld	s0,16(sp)
    800031e2:	64a2                	ld	s1,8(sp)
    800031e4:	6902                	ld	s2,0(sp)
    800031e6:	6105                	addi	sp,sp,32
    800031e8:	8082                	ret
    panic("freeing free block");
    800031ea:	00005517          	auipc	a0,0x5
    800031ee:	40650513          	addi	a0,a0,1030 # 800085f0 <syscalls+0xf8>
    800031f2:	ffffd097          	auipc	ra,0xffffd
    800031f6:	356080e7          	jalr	854(ra) # 80000548 <panic>

00000000800031fa <balloc>:
{
    800031fa:	711d                	addi	sp,sp,-96
    800031fc:	ec86                	sd	ra,88(sp)
    800031fe:	e8a2                	sd	s0,80(sp)
    80003200:	e4a6                	sd	s1,72(sp)
    80003202:	e0ca                	sd	s2,64(sp)
    80003204:	fc4e                	sd	s3,56(sp)
    80003206:	f852                	sd	s4,48(sp)
    80003208:	f456                	sd	s5,40(sp)
    8000320a:	f05a                	sd	s6,32(sp)
    8000320c:	ec5e                	sd	s7,24(sp)
    8000320e:	e862                	sd	s8,16(sp)
    80003210:	e466                	sd	s9,8(sp)
    80003212:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003214:	0001d797          	auipc	a5,0x1d
    80003218:	e307a783          	lw	a5,-464(a5) # 80020044 <sb+0x4>
    8000321c:	cbd1                	beqz	a5,800032b0 <balloc+0xb6>
    8000321e:	8baa                	mv	s7,a0
    80003220:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003222:	0001db17          	auipc	s6,0x1d
    80003226:	e1eb0b13          	addi	s6,s6,-482 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000322c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003230:	6c89                	lui	s9,0x2
    80003232:	a831                	j	8000324e <balloc+0x54>
    brelse(bp);
    80003234:	854a                	mv	a0,s2
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	e32080e7          	jalr	-462(ra) # 80003068 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000323e:	015c87bb          	addw	a5,s9,s5
    80003242:	00078a9b          	sext.w	s5,a5
    80003246:	004b2703          	lw	a4,4(s6)
    8000324a:	06eaf363          	bgeu	s5,a4,800032b0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000324e:	41fad79b          	sraiw	a5,s5,0x1f
    80003252:	0137d79b          	srliw	a5,a5,0x13
    80003256:	015787bb          	addw	a5,a5,s5
    8000325a:	40d7d79b          	sraiw	a5,a5,0xd
    8000325e:	01cb2583          	lw	a1,28(s6)
    80003262:	9dbd                	addw	a1,a1,a5
    80003264:	855e                	mv	a0,s7
    80003266:	00000097          	auipc	ra,0x0
    8000326a:	cd2080e7          	jalr	-814(ra) # 80002f38 <bread>
    8000326e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	004b2503          	lw	a0,4(s6)
    80003274:	000a849b          	sext.w	s1,s5
    80003278:	8662                	mv	a2,s8
    8000327a:	faa4fde3          	bgeu	s1,a0,80003234 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000327e:	41f6579b          	sraiw	a5,a2,0x1f
    80003282:	01d7d69b          	srliw	a3,a5,0x1d
    80003286:	00c6873b          	addw	a4,a3,a2
    8000328a:	00777793          	andi	a5,a4,7
    8000328e:	9f95                	subw	a5,a5,a3
    80003290:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003294:	4037571b          	sraiw	a4,a4,0x3
    80003298:	00e906b3          	add	a3,s2,a4
    8000329c:	0586c683          	lbu	a3,88(a3)
    800032a0:	00d7f5b3          	and	a1,a5,a3
    800032a4:	cd91                	beqz	a1,800032c0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	2605                	addiw	a2,a2,1
    800032a8:	2485                	addiw	s1,s1,1
    800032aa:	fd4618e3          	bne	a2,s4,8000327a <balloc+0x80>
    800032ae:	b759                	j	80003234 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032b0:	00005517          	auipc	a0,0x5
    800032b4:	35850513          	addi	a0,a0,856 # 80008608 <syscalls+0x110>
    800032b8:	ffffd097          	auipc	ra,0xffffd
    800032bc:	290080e7          	jalr	656(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032c0:	974a                	add	a4,a4,s2
    800032c2:	8fd5                	or	a5,a5,a3
    800032c4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032c8:	854a                	mv	a0,s2
    800032ca:	00001097          	auipc	ra,0x1
    800032ce:	002080e7          	jalr	2(ra) # 800042cc <log_write>
        brelse(bp);
    800032d2:	854a                	mv	a0,s2
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	d94080e7          	jalr	-620(ra) # 80003068 <brelse>
  bp = bread(dev, bno);
    800032dc:	85a6                	mv	a1,s1
    800032de:	855e                	mv	a0,s7
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	c58080e7          	jalr	-936(ra) # 80002f38 <bread>
    800032e8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ea:	40000613          	li	a2,1024
    800032ee:	4581                	li	a1,0
    800032f0:	05850513          	addi	a0,a0,88
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	a3c080e7          	jalr	-1476(ra) # 80000d30 <memset>
  log_write(bp);
    800032fc:	854a                	mv	a0,s2
    800032fe:	00001097          	auipc	ra,0x1
    80003302:	fce080e7          	jalr	-50(ra) # 800042cc <log_write>
  brelse(bp);
    80003306:	854a                	mv	a0,s2
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	d60080e7          	jalr	-672(ra) # 80003068 <brelse>
}
    80003310:	8526                	mv	a0,s1
    80003312:	60e6                	ld	ra,88(sp)
    80003314:	6446                	ld	s0,80(sp)
    80003316:	64a6                	ld	s1,72(sp)
    80003318:	6906                	ld	s2,64(sp)
    8000331a:	79e2                	ld	s3,56(sp)
    8000331c:	7a42                	ld	s4,48(sp)
    8000331e:	7aa2                	ld	s5,40(sp)
    80003320:	7b02                	ld	s6,32(sp)
    80003322:	6be2                	ld	s7,24(sp)
    80003324:	6c42                	ld	s8,16(sp)
    80003326:	6ca2                	ld	s9,8(sp)
    80003328:	6125                	addi	sp,sp,96
    8000332a:	8082                	ret

000000008000332c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000332c:	7179                	addi	sp,sp,-48
    8000332e:	f406                	sd	ra,40(sp)
    80003330:	f022                	sd	s0,32(sp)
    80003332:	ec26                	sd	s1,24(sp)
    80003334:	e84a                	sd	s2,16(sp)
    80003336:	e44e                	sd	s3,8(sp)
    80003338:	e052                	sd	s4,0(sp)
    8000333a:	1800                	addi	s0,sp,48
    8000333c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333e:	47ad                	li	a5,11
    80003340:	04b7fe63          	bgeu	a5,a1,8000339c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003344:	ff45849b          	addiw	s1,a1,-12
    80003348:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000334c:	0ff00793          	li	a5,255
    80003350:	0ae7e363          	bltu	a5,a4,800033f6 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003354:	08052583          	lw	a1,128(a0)
    80003358:	c5ad                	beqz	a1,800033c2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000335a:	00092503          	lw	a0,0(s2)
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	bda080e7          	jalr	-1062(ra) # 80002f38 <bread>
    80003366:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003368:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000336c:	02049593          	slli	a1,s1,0x20
    80003370:	9181                	srli	a1,a1,0x20
    80003372:	058a                	slli	a1,a1,0x2
    80003374:	00b784b3          	add	s1,a5,a1
    80003378:	0004a983          	lw	s3,0(s1)
    8000337c:	04098d63          	beqz	s3,800033d6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003380:	8552                	mv	a0,s4
    80003382:	00000097          	auipc	ra,0x0
    80003386:	ce6080e7          	jalr	-794(ra) # 80003068 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000338a:	854e                	mv	a0,s3
    8000338c:	70a2                	ld	ra,40(sp)
    8000338e:	7402                	ld	s0,32(sp)
    80003390:	64e2                	ld	s1,24(sp)
    80003392:	6942                	ld	s2,16(sp)
    80003394:	69a2                	ld	s3,8(sp)
    80003396:	6a02                	ld	s4,0(sp)
    80003398:	6145                	addi	sp,sp,48
    8000339a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000339c:	02059493          	slli	s1,a1,0x20
    800033a0:	9081                	srli	s1,s1,0x20
    800033a2:	048a                	slli	s1,s1,0x2
    800033a4:	94aa                	add	s1,s1,a0
    800033a6:	0504a983          	lw	s3,80(s1)
    800033aa:	fe0990e3          	bnez	s3,8000338a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ae:	4108                	lw	a0,0(a0)
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	e4a080e7          	jalr	-438(ra) # 800031fa <balloc>
    800033b8:	0005099b          	sext.w	s3,a0
    800033bc:	0534a823          	sw	s3,80(s1)
    800033c0:	b7e9                	j	8000338a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033c2:	4108                	lw	a0,0(a0)
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	e36080e7          	jalr	-458(ra) # 800031fa <balloc>
    800033cc:	0005059b          	sext.w	a1,a0
    800033d0:	08b92023          	sw	a1,128(s2)
    800033d4:	b759                	j	8000335a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033d6:	00092503          	lw	a0,0(s2)
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e20080e7          	jalr	-480(ra) # 800031fa <balloc>
    800033e2:	0005099b          	sext.w	s3,a0
    800033e6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ea:	8552                	mv	a0,s4
    800033ec:	00001097          	auipc	ra,0x1
    800033f0:	ee0080e7          	jalr	-288(ra) # 800042cc <log_write>
    800033f4:	b771                	j	80003380 <bmap+0x54>
  panic("bmap: out of range");
    800033f6:	00005517          	auipc	a0,0x5
    800033fa:	22a50513          	addi	a0,a0,554 # 80008620 <syscalls+0x128>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	14a080e7          	jalr	330(ra) # 80000548 <panic>

0000000080003406 <iget>:
{
    80003406:	7179                	addi	sp,sp,-48
    80003408:	f406                	sd	ra,40(sp)
    8000340a:	f022                	sd	s0,32(sp)
    8000340c:	ec26                	sd	s1,24(sp)
    8000340e:	e84a                	sd	s2,16(sp)
    80003410:	e44e                	sd	s3,8(sp)
    80003412:	e052                	sd	s4,0(sp)
    80003414:	1800                	addi	s0,sp,48
    80003416:	89aa                	mv	s3,a0
    80003418:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000341a:	0001d517          	auipc	a0,0x1d
    8000341e:	c4650513          	addi	a0,a0,-954 # 80020060 <icache>
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	812080e7          	jalr	-2030(ra) # 80000c34 <acquire>
  empty = 0;
    8000342a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000342c:	0001d497          	auipc	s1,0x1d
    80003430:	c4c48493          	addi	s1,s1,-948 # 80020078 <icache+0x18>
    80003434:	0001e697          	auipc	a3,0x1e
    80003438:	6d468693          	addi	a3,a3,1748 # 80021b08 <log>
    8000343c:	a039                	j	8000344a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343e:	02090b63          	beqz	s2,80003474 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003442:	08848493          	addi	s1,s1,136
    80003446:	02d48a63          	beq	s1,a3,8000347a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000344a:	449c                	lw	a5,8(s1)
    8000344c:	fef059e3          	blez	a5,8000343e <iget+0x38>
    80003450:	4098                	lw	a4,0(s1)
    80003452:	ff3716e3          	bne	a4,s3,8000343e <iget+0x38>
    80003456:	40d8                	lw	a4,4(s1)
    80003458:	ff4713e3          	bne	a4,s4,8000343e <iget+0x38>
      ip->ref++;
    8000345c:	2785                	addiw	a5,a5,1
    8000345e:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003460:	0001d517          	auipc	a0,0x1d
    80003464:	c0050513          	addi	a0,a0,-1024 # 80020060 <icache>
    80003468:	ffffe097          	auipc	ra,0xffffe
    8000346c:	880080e7          	jalr	-1920(ra) # 80000ce8 <release>
      return ip;
    80003470:	8926                	mv	s2,s1
    80003472:	a03d                	j	800034a0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003474:	f7f9                	bnez	a5,80003442 <iget+0x3c>
    80003476:	8926                	mv	s2,s1
    80003478:	b7e9                	j	80003442 <iget+0x3c>
  if(empty == 0)
    8000347a:	02090c63          	beqz	s2,800034b2 <iget+0xac>
  ip->dev = dev;
    8000347e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003482:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003486:	4785                	li	a5,1
    80003488:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000348c:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003490:	0001d517          	auipc	a0,0x1d
    80003494:	bd050513          	addi	a0,a0,-1072 # 80020060 <icache>
    80003498:	ffffe097          	auipc	ra,0xffffe
    8000349c:	850080e7          	jalr	-1968(ra) # 80000ce8 <release>
}
    800034a0:	854a                	mv	a0,s2
    800034a2:	70a2                	ld	ra,40(sp)
    800034a4:	7402                	ld	s0,32(sp)
    800034a6:	64e2                	ld	s1,24(sp)
    800034a8:	6942                	ld	s2,16(sp)
    800034aa:	69a2                	ld	s3,8(sp)
    800034ac:	6a02                	ld	s4,0(sp)
    800034ae:	6145                	addi	sp,sp,48
    800034b0:	8082                	ret
    panic("iget: no inodes");
    800034b2:	00005517          	auipc	a0,0x5
    800034b6:	18650513          	addi	a0,a0,390 # 80008638 <syscalls+0x140>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	08e080e7          	jalr	142(ra) # 80000548 <panic>

00000000800034c2 <fsinit>:
fsinit(int dev) {
    800034c2:	7179                	addi	sp,sp,-48
    800034c4:	f406                	sd	ra,40(sp)
    800034c6:	f022                	sd	s0,32(sp)
    800034c8:	ec26                	sd	s1,24(sp)
    800034ca:	e84a                	sd	s2,16(sp)
    800034cc:	e44e                	sd	s3,8(sp)
    800034ce:	1800                	addi	s0,sp,48
    800034d0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d2:	4585                	li	a1,1
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	a64080e7          	jalr	-1436(ra) # 80002f38 <bread>
    800034dc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034de:	0001d997          	auipc	s3,0x1d
    800034e2:	b6298993          	addi	s3,s3,-1182 # 80020040 <sb>
    800034e6:	02000613          	li	a2,32
    800034ea:	05850593          	addi	a1,a0,88
    800034ee:	854e                	mv	a0,s3
    800034f0:	ffffe097          	auipc	ra,0xffffe
    800034f4:	8a0080e7          	jalr	-1888(ra) # 80000d90 <memmove>
  brelse(bp);
    800034f8:	8526                	mv	a0,s1
    800034fa:	00000097          	auipc	ra,0x0
    800034fe:	b6e080e7          	jalr	-1170(ra) # 80003068 <brelse>
  if(sb.magic != FSMAGIC)
    80003502:	0009a703          	lw	a4,0(s3)
    80003506:	102037b7          	lui	a5,0x10203
    8000350a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000350e:	02f71263          	bne	a4,a5,80003532 <fsinit+0x70>
  initlog(dev, &sb);
    80003512:	0001d597          	auipc	a1,0x1d
    80003516:	b2e58593          	addi	a1,a1,-1234 # 80020040 <sb>
    8000351a:	854a                	mv	a0,s2
    8000351c:	00001097          	auipc	ra,0x1
    80003520:	b38080e7          	jalr	-1224(ra) # 80004054 <initlog>
}
    80003524:	70a2                	ld	ra,40(sp)
    80003526:	7402                	ld	s0,32(sp)
    80003528:	64e2                	ld	s1,24(sp)
    8000352a:	6942                	ld	s2,16(sp)
    8000352c:	69a2                	ld	s3,8(sp)
    8000352e:	6145                	addi	sp,sp,48
    80003530:	8082                	ret
    panic("invalid file system");
    80003532:	00005517          	auipc	a0,0x5
    80003536:	11650513          	addi	a0,a0,278 # 80008648 <syscalls+0x150>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	00e080e7          	jalr	14(ra) # 80000548 <panic>

0000000080003542 <iinit>:
{
    80003542:	7179                	addi	sp,sp,-48
    80003544:	f406                	sd	ra,40(sp)
    80003546:	f022                	sd	s0,32(sp)
    80003548:	ec26                	sd	s1,24(sp)
    8000354a:	e84a                	sd	s2,16(sp)
    8000354c:	e44e                	sd	s3,8(sp)
    8000354e:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003550:	00005597          	auipc	a1,0x5
    80003554:	11058593          	addi	a1,a1,272 # 80008660 <syscalls+0x168>
    80003558:	0001d517          	auipc	a0,0x1d
    8000355c:	b0850513          	addi	a0,a0,-1272 # 80020060 <icache>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	644080e7          	jalr	1604(ra) # 80000ba4 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003568:	0001d497          	auipc	s1,0x1d
    8000356c:	b2048493          	addi	s1,s1,-1248 # 80020088 <icache+0x28>
    80003570:	0001e997          	auipc	s3,0x1e
    80003574:	5a898993          	addi	s3,s3,1448 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003578:	00005917          	auipc	s2,0x5
    8000357c:	0f090913          	addi	s2,s2,240 # 80008668 <syscalls+0x170>
    80003580:	85ca                	mv	a1,s2
    80003582:	8526                	mv	a0,s1
    80003584:	00001097          	auipc	ra,0x1
    80003588:	e36080e7          	jalr	-458(ra) # 800043ba <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000358c:	08848493          	addi	s1,s1,136
    80003590:	ff3498e3          	bne	s1,s3,80003580 <iinit+0x3e>
}
    80003594:	70a2                	ld	ra,40(sp)
    80003596:	7402                	ld	s0,32(sp)
    80003598:	64e2                	ld	s1,24(sp)
    8000359a:	6942                	ld	s2,16(sp)
    8000359c:	69a2                	ld	s3,8(sp)
    8000359e:	6145                	addi	sp,sp,48
    800035a0:	8082                	ret

00000000800035a2 <ialloc>:
{
    800035a2:	715d                	addi	sp,sp,-80
    800035a4:	e486                	sd	ra,72(sp)
    800035a6:	e0a2                	sd	s0,64(sp)
    800035a8:	fc26                	sd	s1,56(sp)
    800035aa:	f84a                	sd	s2,48(sp)
    800035ac:	f44e                	sd	s3,40(sp)
    800035ae:	f052                	sd	s4,32(sp)
    800035b0:	ec56                	sd	s5,24(sp)
    800035b2:	e85a                	sd	s6,16(sp)
    800035b4:	e45e                	sd	s7,8(sp)
    800035b6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b8:	0001d717          	auipc	a4,0x1d
    800035bc:	a9472703          	lw	a4,-1388(a4) # 8002004c <sb+0xc>
    800035c0:	4785                	li	a5,1
    800035c2:	04e7fa63          	bgeu	a5,a4,80003616 <ialloc+0x74>
    800035c6:	8aaa                	mv	s5,a0
    800035c8:	8bae                	mv	s7,a1
    800035ca:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035cc:	0001da17          	auipc	s4,0x1d
    800035d0:	a74a0a13          	addi	s4,s4,-1420 # 80020040 <sb>
    800035d4:	00048b1b          	sext.w	s6,s1
    800035d8:	0044d593          	srli	a1,s1,0x4
    800035dc:	018a2783          	lw	a5,24(s4)
    800035e0:	9dbd                	addw	a1,a1,a5
    800035e2:	8556                	mv	a0,s5
    800035e4:	00000097          	auipc	ra,0x0
    800035e8:	954080e7          	jalr	-1708(ra) # 80002f38 <bread>
    800035ec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035ee:	05850993          	addi	s3,a0,88
    800035f2:	00f4f793          	andi	a5,s1,15
    800035f6:	079a                	slli	a5,a5,0x6
    800035f8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035fa:	00099783          	lh	a5,0(s3)
    800035fe:	c785                	beqz	a5,80003626 <ialloc+0x84>
    brelse(bp);
    80003600:	00000097          	auipc	ra,0x0
    80003604:	a68080e7          	jalr	-1432(ra) # 80003068 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003608:	0485                	addi	s1,s1,1
    8000360a:	00ca2703          	lw	a4,12(s4)
    8000360e:	0004879b          	sext.w	a5,s1
    80003612:	fce7e1e3          	bltu	a5,a4,800035d4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003616:	00005517          	auipc	a0,0x5
    8000361a:	05a50513          	addi	a0,a0,90 # 80008670 <syscalls+0x178>
    8000361e:	ffffd097          	auipc	ra,0xffffd
    80003622:	f2a080e7          	jalr	-214(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003626:	04000613          	li	a2,64
    8000362a:	4581                	li	a1,0
    8000362c:	854e                	mv	a0,s3
    8000362e:	ffffd097          	auipc	ra,0xffffd
    80003632:	702080e7          	jalr	1794(ra) # 80000d30 <memset>
      dip->type = type;
    80003636:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000363a:	854a                	mv	a0,s2
    8000363c:	00001097          	auipc	ra,0x1
    80003640:	c90080e7          	jalr	-880(ra) # 800042cc <log_write>
      brelse(bp);
    80003644:	854a                	mv	a0,s2
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	a22080e7          	jalr	-1502(ra) # 80003068 <brelse>
      return iget(dev, inum);
    8000364e:	85da                	mv	a1,s6
    80003650:	8556                	mv	a0,s5
    80003652:	00000097          	auipc	ra,0x0
    80003656:	db4080e7          	jalr	-588(ra) # 80003406 <iget>
}
    8000365a:	60a6                	ld	ra,72(sp)
    8000365c:	6406                	ld	s0,64(sp)
    8000365e:	74e2                	ld	s1,56(sp)
    80003660:	7942                	ld	s2,48(sp)
    80003662:	79a2                	ld	s3,40(sp)
    80003664:	7a02                	ld	s4,32(sp)
    80003666:	6ae2                	ld	s5,24(sp)
    80003668:	6b42                	ld	s6,16(sp)
    8000366a:	6ba2                	ld	s7,8(sp)
    8000366c:	6161                	addi	sp,sp,80
    8000366e:	8082                	ret

0000000080003670 <iupdate>:
{
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	e04a                	sd	s2,0(sp)
    8000367a:	1000                	addi	s0,sp,32
    8000367c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000367e:	415c                	lw	a5,4(a0)
    80003680:	0047d79b          	srliw	a5,a5,0x4
    80003684:	0001d597          	auipc	a1,0x1d
    80003688:	9d45a583          	lw	a1,-1580(a1) # 80020058 <sb+0x18>
    8000368c:	9dbd                	addw	a1,a1,a5
    8000368e:	4108                	lw	a0,0(a0)
    80003690:	00000097          	auipc	ra,0x0
    80003694:	8a8080e7          	jalr	-1880(ra) # 80002f38 <bread>
    80003698:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000369a:	05850793          	addi	a5,a0,88
    8000369e:	40c8                	lw	a0,4(s1)
    800036a0:	893d                	andi	a0,a0,15
    800036a2:	051a                	slli	a0,a0,0x6
    800036a4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036a6:	04449703          	lh	a4,68(s1)
    800036aa:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036ae:	04649703          	lh	a4,70(s1)
    800036b2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036b6:	04849703          	lh	a4,72(s1)
    800036ba:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036be:	04a49703          	lh	a4,74(s1)
    800036c2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036c6:	44f8                	lw	a4,76(s1)
    800036c8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036ca:	03400613          	li	a2,52
    800036ce:	05048593          	addi	a1,s1,80
    800036d2:	0531                	addi	a0,a0,12
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	6bc080e7          	jalr	1724(ra) # 80000d90 <memmove>
  log_write(bp);
    800036dc:	854a                	mv	a0,s2
    800036de:	00001097          	auipc	ra,0x1
    800036e2:	bee080e7          	jalr	-1042(ra) # 800042cc <log_write>
  brelse(bp);
    800036e6:	854a                	mv	a0,s2
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	980080e7          	jalr	-1664(ra) # 80003068 <brelse>
}
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	64a2                	ld	s1,8(sp)
    800036f6:	6902                	ld	s2,0(sp)
    800036f8:	6105                	addi	sp,sp,32
    800036fa:	8082                	ret

00000000800036fc <idup>:
{
    800036fc:	1101                	addi	sp,sp,-32
    800036fe:	ec06                	sd	ra,24(sp)
    80003700:	e822                	sd	s0,16(sp)
    80003702:	e426                	sd	s1,8(sp)
    80003704:	1000                	addi	s0,sp,32
    80003706:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003708:	0001d517          	auipc	a0,0x1d
    8000370c:	95850513          	addi	a0,a0,-1704 # 80020060 <icache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	524080e7          	jalr	1316(ra) # 80000c34 <acquire>
  ip->ref++;
    80003718:	449c                	lw	a5,8(s1)
    8000371a:	2785                	addiw	a5,a5,1
    8000371c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000371e:	0001d517          	auipc	a0,0x1d
    80003722:	94250513          	addi	a0,a0,-1726 # 80020060 <icache>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	5c2080e7          	jalr	1474(ra) # 80000ce8 <release>
}
    8000372e:	8526                	mv	a0,s1
    80003730:	60e2                	ld	ra,24(sp)
    80003732:	6442                	ld	s0,16(sp)
    80003734:	64a2                	ld	s1,8(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret

000000008000373a <ilock>:
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	e04a                	sd	s2,0(sp)
    80003744:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003746:	c115                	beqz	a0,8000376a <ilock+0x30>
    80003748:	84aa                	mv	s1,a0
    8000374a:	451c                	lw	a5,8(a0)
    8000374c:	00f05f63          	blez	a5,8000376a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003750:	0541                	addi	a0,a0,16
    80003752:	00001097          	auipc	ra,0x1
    80003756:	ca2080e7          	jalr	-862(ra) # 800043f4 <acquiresleep>
  if(ip->valid == 0){
    8000375a:	40bc                	lw	a5,64(s1)
    8000375c:	cf99                	beqz	a5,8000377a <ilock+0x40>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6902                	ld	s2,0(sp)
    80003766:	6105                	addi	sp,sp,32
    80003768:	8082                	ret
    panic("ilock");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	f1e50513          	addi	a0,a0,-226 # 80008688 <syscalls+0x190>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dd6080e7          	jalr	-554(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377a:	40dc                	lw	a5,4(s1)
    8000377c:	0047d79b          	srliw	a5,a5,0x4
    80003780:	0001d597          	auipc	a1,0x1d
    80003784:	8d85a583          	lw	a1,-1832(a1) # 80020058 <sb+0x18>
    80003788:	9dbd                	addw	a1,a1,a5
    8000378a:	4088                	lw	a0,0(s1)
    8000378c:	fffff097          	auipc	ra,0xfffff
    80003790:	7ac080e7          	jalr	1964(ra) # 80002f38 <bread>
    80003794:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003796:	05850593          	addi	a1,a0,88
    8000379a:	40dc                	lw	a5,4(s1)
    8000379c:	8bbd                	andi	a5,a5,15
    8000379e:	079a                	slli	a5,a5,0x6
    800037a0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a2:	00059783          	lh	a5,0(a1)
    800037a6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037aa:	00259783          	lh	a5,2(a1)
    800037ae:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b2:	00459783          	lh	a5,4(a1)
    800037b6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ba:	00659783          	lh	a5,6(a1)
    800037be:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c2:	459c                	lw	a5,8(a1)
    800037c4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037c6:	03400613          	li	a2,52
    800037ca:	05b1                	addi	a1,a1,12
    800037cc:	05048513          	addi	a0,s1,80
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	5c0080e7          	jalr	1472(ra) # 80000d90 <memmove>
    brelse(bp);
    800037d8:	854a                	mv	a0,s2
    800037da:	00000097          	auipc	ra,0x0
    800037de:	88e080e7          	jalr	-1906(ra) # 80003068 <brelse>
    ip->valid = 1;
    800037e2:	4785                	li	a5,1
    800037e4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037e6:	04449783          	lh	a5,68(s1)
    800037ea:	fbb5                	bnez	a5,8000375e <ilock+0x24>
      panic("ilock: no type");
    800037ec:	00005517          	auipc	a0,0x5
    800037f0:	ea450513          	addi	a0,a0,-348 # 80008690 <syscalls+0x198>
    800037f4:	ffffd097          	auipc	ra,0xffffd
    800037f8:	d54080e7          	jalr	-684(ra) # 80000548 <panic>

00000000800037fc <iunlock>:
{
    800037fc:	1101                	addi	sp,sp,-32
    800037fe:	ec06                	sd	ra,24(sp)
    80003800:	e822                	sd	s0,16(sp)
    80003802:	e426                	sd	s1,8(sp)
    80003804:	e04a                	sd	s2,0(sp)
    80003806:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003808:	c905                	beqz	a0,80003838 <iunlock+0x3c>
    8000380a:	84aa                	mv	s1,a0
    8000380c:	01050913          	addi	s2,a0,16
    80003810:	854a                	mv	a0,s2
    80003812:	00001097          	auipc	ra,0x1
    80003816:	c7c080e7          	jalr	-900(ra) # 8000448e <holdingsleep>
    8000381a:	cd19                	beqz	a0,80003838 <iunlock+0x3c>
    8000381c:	449c                	lw	a5,8(s1)
    8000381e:	00f05d63          	blez	a5,80003838 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	c26080e7          	jalr	-986(ra) # 8000444a <releasesleep>
}
    8000382c:	60e2                	ld	ra,24(sp)
    8000382e:	6442                	ld	s0,16(sp)
    80003830:	64a2                	ld	s1,8(sp)
    80003832:	6902                	ld	s2,0(sp)
    80003834:	6105                	addi	sp,sp,32
    80003836:	8082                	ret
    panic("iunlock");
    80003838:	00005517          	auipc	a0,0x5
    8000383c:	e6850513          	addi	a0,a0,-408 # 800086a0 <syscalls+0x1a8>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	d08080e7          	jalr	-760(ra) # 80000548 <panic>

0000000080003848 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003848:	7179                	addi	sp,sp,-48
    8000384a:	f406                	sd	ra,40(sp)
    8000384c:	f022                	sd	s0,32(sp)
    8000384e:	ec26                	sd	s1,24(sp)
    80003850:	e84a                	sd	s2,16(sp)
    80003852:	e44e                	sd	s3,8(sp)
    80003854:	e052                	sd	s4,0(sp)
    80003856:	1800                	addi	s0,sp,48
    80003858:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000385a:	05050493          	addi	s1,a0,80
    8000385e:	08050913          	addi	s2,a0,128
    80003862:	a021                	j	8000386a <itrunc+0x22>
    80003864:	0491                	addi	s1,s1,4
    80003866:	01248d63          	beq	s1,s2,80003880 <itrunc+0x38>
    if(ip->addrs[i]){
    8000386a:	408c                	lw	a1,0(s1)
    8000386c:	dde5                	beqz	a1,80003864 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000386e:	0009a503          	lw	a0,0(s3)
    80003872:	00000097          	auipc	ra,0x0
    80003876:	90c080e7          	jalr	-1780(ra) # 8000317e <bfree>
      ip->addrs[i] = 0;
    8000387a:	0004a023          	sw	zero,0(s1)
    8000387e:	b7dd                	j	80003864 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003880:	0809a583          	lw	a1,128(s3)
    80003884:	e185                	bnez	a1,800038a4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003886:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000388a:	854e                	mv	a0,s3
    8000388c:	00000097          	auipc	ra,0x0
    80003890:	de4080e7          	jalr	-540(ra) # 80003670 <iupdate>
}
    80003894:	70a2                	ld	ra,40(sp)
    80003896:	7402                	ld	s0,32(sp)
    80003898:	64e2                	ld	s1,24(sp)
    8000389a:	6942                	ld	s2,16(sp)
    8000389c:	69a2                	ld	s3,8(sp)
    8000389e:	6a02                	ld	s4,0(sp)
    800038a0:	6145                	addi	sp,sp,48
    800038a2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a4:	0009a503          	lw	a0,0(s3)
    800038a8:	fffff097          	auipc	ra,0xfffff
    800038ac:	690080e7          	jalr	1680(ra) # 80002f38 <bread>
    800038b0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b2:	05850493          	addi	s1,a0,88
    800038b6:	45850913          	addi	s2,a0,1112
    800038ba:	a811                	j	800038ce <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038bc:	0009a503          	lw	a0,0(s3)
    800038c0:	00000097          	auipc	ra,0x0
    800038c4:	8be080e7          	jalr	-1858(ra) # 8000317e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038c8:	0491                	addi	s1,s1,4
    800038ca:	01248563          	beq	s1,s2,800038d4 <itrunc+0x8c>
      if(a[j])
    800038ce:	408c                	lw	a1,0(s1)
    800038d0:	dde5                	beqz	a1,800038c8 <itrunc+0x80>
    800038d2:	b7ed                	j	800038bc <itrunc+0x74>
    brelse(bp);
    800038d4:	8552                	mv	a0,s4
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	792080e7          	jalr	1938(ra) # 80003068 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038de:	0809a583          	lw	a1,128(s3)
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	898080e7          	jalr	-1896(ra) # 8000317e <bfree>
    ip->addrs[NDIRECT] = 0;
    800038ee:	0809a023          	sw	zero,128(s3)
    800038f2:	bf51                	j	80003886 <itrunc+0x3e>

00000000800038f4 <iput>:
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	e04a                	sd	s2,0(sp)
    800038fe:	1000                	addi	s0,sp,32
    80003900:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003902:	0001c517          	auipc	a0,0x1c
    80003906:	75e50513          	addi	a0,a0,1886 # 80020060 <icache>
    8000390a:	ffffd097          	auipc	ra,0xffffd
    8000390e:	32a080e7          	jalr	810(ra) # 80000c34 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003912:	4498                	lw	a4,8(s1)
    80003914:	4785                	li	a5,1
    80003916:	02f70363          	beq	a4,a5,8000393c <iput+0x48>
  ip->ref--;
    8000391a:	449c                	lw	a5,8(s1)
    8000391c:	37fd                	addiw	a5,a5,-1
    8000391e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003920:	0001c517          	auipc	a0,0x1c
    80003924:	74050513          	addi	a0,a0,1856 # 80020060 <icache>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	3c0080e7          	jalr	960(ra) # 80000ce8 <release>
}
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6902                	ld	s2,0(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393c:	40bc                	lw	a5,64(s1)
    8000393e:	dff1                	beqz	a5,8000391a <iput+0x26>
    80003940:	04a49783          	lh	a5,74(s1)
    80003944:	fbf9                	bnez	a5,8000391a <iput+0x26>
    acquiresleep(&ip->lock);
    80003946:	01048913          	addi	s2,s1,16
    8000394a:	854a                	mv	a0,s2
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	aa8080e7          	jalr	-1368(ra) # 800043f4 <acquiresleep>
    release(&icache.lock);
    80003954:	0001c517          	auipc	a0,0x1c
    80003958:	70c50513          	addi	a0,a0,1804 # 80020060 <icache>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	38c080e7          	jalr	908(ra) # 80000ce8 <release>
    itrunc(ip);
    80003964:	8526                	mv	a0,s1
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	ee2080e7          	jalr	-286(ra) # 80003848 <itrunc>
    ip->type = 0;
    8000396e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003972:	8526                	mv	a0,s1
    80003974:	00000097          	auipc	ra,0x0
    80003978:	cfc080e7          	jalr	-772(ra) # 80003670 <iupdate>
    ip->valid = 0;
    8000397c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003980:	854a                	mv	a0,s2
    80003982:	00001097          	auipc	ra,0x1
    80003986:	ac8080e7          	jalr	-1336(ra) # 8000444a <releasesleep>
    acquire(&icache.lock);
    8000398a:	0001c517          	auipc	a0,0x1c
    8000398e:	6d650513          	addi	a0,a0,1750 # 80020060 <icache>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	2a2080e7          	jalr	674(ra) # 80000c34 <acquire>
    8000399a:	b741                	j	8000391a <iput+0x26>

000000008000399c <iunlockput>:
{
    8000399c:	1101                	addi	sp,sp,-32
    8000399e:	ec06                	sd	ra,24(sp)
    800039a0:	e822                	sd	s0,16(sp)
    800039a2:	e426                	sd	s1,8(sp)
    800039a4:	1000                	addi	s0,sp,32
    800039a6:	84aa                	mv	s1,a0
  iunlock(ip);
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	e54080e7          	jalr	-428(ra) # 800037fc <iunlock>
  iput(ip);
    800039b0:	8526                	mv	a0,s1
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	f42080e7          	jalr	-190(ra) # 800038f4 <iput>
}
    800039ba:	60e2                	ld	ra,24(sp)
    800039bc:	6442                	ld	s0,16(sp)
    800039be:	64a2                	ld	s1,8(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret

00000000800039c4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c4:	1141                	addi	sp,sp,-16
    800039c6:	e422                	sd	s0,8(sp)
    800039c8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039ca:	411c                	lw	a5,0(a0)
    800039cc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039ce:	415c                	lw	a5,4(a0)
    800039d0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d2:	04451783          	lh	a5,68(a0)
    800039d6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039da:	04a51783          	lh	a5,74(a0)
    800039de:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e2:	04c56783          	lwu	a5,76(a0)
    800039e6:	e99c                	sd	a5,16(a1)
}
    800039e8:	6422                	ld	s0,8(sp)
    800039ea:	0141                	addi	sp,sp,16
    800039ec:	8082                	ret

00000000800039ee <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ee:	457c                	lw	a5,76(a0)
    800039f0:	0ed7e863          	bltu	a5,a3,80003ae0 <readi+0xf2>
{
    800039f4:	7159                	addi	sp,sp,-112
    800039f6:	f486                	sd	ra,104(sp)
    800039f8:	f0a2                	sd	s0,96(sp)
    800039fa:	eca6                	sd	s1,88(sp)
    800039fc:	e8ca                	sd	s2,80(sp)
    800039fe:	e4ce                	sd	s3,72(sp)
    80003a00:	e0d2                	sd	s4,64(sp)
    80003a02:	fc56                	sd	s5,56(sp)
    80003a04:	f85a                	sd	s6,48(sp)
    80003a06:	f45e                	sd	s7,40(sp)
    80003a08:	f062                	sd	s8,32(sp)
    80003a0a:	ec66                	sd	s9,24(sp)
    80003a0c:	e86a                	sd	s10,16(sp)
    80003a0e:	e46e                	sd	s11,8(sp)
    80003a10:	1880                	addi	s0,sp,112
    80003a12:	8baa                	mv	s7,a0
    80003a14:	8c2e                	mv	s8,a1
    80003a16:	8ab2                	mv	s5,a2
    80003a18:	84b6                	mv	s1,a3
    80003a1a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a1c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a1e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a20:	08d76f63          	bltu	a4,a3,80003abe <readi+0xd0>
  if(off + n > ip->size)
    80003a24:	00e7f463          	bgeu	a5,a4,80003a2c <readi+0x3e>
    n = ip->size - off;
    80003a28:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2c:	0a0b0863          	beqz	s6,80003adc <readi+0xee>
    80003a30:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a32:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a36:	5cfd                	li	s9,-1
    80003a38:	a82d                	j	80003a72 <readi+0x84>
    80003a3a:	020a1d93          	slli	s11,s4,0x20
    80003a3e:	020ddd93          	srli	s11,s11,0x20
    80003a42:	05890613          	addi	a2,s2,88
    80003a46:	86ee                	mv	a3,s11
    80003a48:	963a                	add	a2,a2,a4
    80003a4a:	85d6                	mv	a1,s5
    80003a4c:	8562                	mv	a0,s8
    80003a4e:	fffff097          	auipc	ra,0xfffff
    80003a52:	a2a080e7          	jalr	-1494(ra) # 80002478 <either_copyout>
    80003a56:	05950d63          	beq	a0,s9,80003ab0 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	fffff097          	auipc	ra,0xfffff
    80003a60:	60c080e7          	jalr	1548(ra) # 80003068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a64:	013a09bb          	addw	s3,s4,s3
    80003a68:	009a04bb          	addw	s1,s4,s1
    80003a6c:	9aee                	add	s5,s5,s11
    80003a6e:	0569f663          	bgeu	s3,s6,80003aba <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a72:	000ba903          	lw	s2,0(s7)
    80003a76:	00a4d59b          	srliw	a1,s1,0xa
    80003a7a:	855e                	mv	a0,s7
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	8b0080e7          	jalr	-1872(ra) # 8000332c <bmap>
    80003a84:	0005059b          	sext.w	a1,a0
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	4ae080e7          	jalr	1198(ra) # 80002f38 <bread>
    80003a92:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a94:	3ff4f713          	andi	a4,s1,1023
    80003a98:	40ed07bb          	subw	a5,s10,a4
    80003a9c:	413b06bb          	subw	a3,s6,s3
    80003aa0:	8a3e                	mv	s4,a5
    80003aa2:	2781                	sext.w	a5,a5
    80003aa4:	0006861b          	sext.w	a2,a3
    80003aa8:	f8f679e3          	bgeu	a2,a5,80003a3a <readi+0x4c>
    80003aac:	8a36                	mv	s4,a3
    80003aae:	b771                	j	80003a3a <readi+0x4c>
      brelse(bp);
    80003ab0:	854a                	mv	a0,s2
    80003ab2:	fffff097          	auipc	ra,0xfffff
    80003ab6:	5b6080e7          	jalr	1462(ra) # 80003068 <brelse>
  }
  return tot;
    80003aba:	0009851b          	sext.w	a0,s3
}
    80003abe:	70a6                	ld	ra,104(sp)
    80003ac0:	7406                	ld	s0,96(sp)
    80003ac2:	64e6                	ld	s1,88(sp)
    80003ac4:	6946                	ld	s2,80(sp)
    80003ac6:	69a6                	ld	s3,72(sp)
    80003ac8:	6a06                	ld	s4,64(sp)
    80003aca:	7ae2                	ld	s5,56(sp)
    80003acc:	7b42                	ld	s6,48(sp)
    80003ace:	7ba2                	ld	s7,40(sp)
    80003ad0:	7c02                	ld	s8,32(sp)
    80003ad2:	6ce2                	ld	s9,24(sp)
    80003ad4:	6d42                	ld	s10,16(sp)
    80003ad6:	6da2                	ld	s11,8(sp)
    80003ad8:	6165                	addi	sp,sp,112
    80003ada:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003adc:	89da                	mv	s3,s6
    80003ade:	bff1                	j	80003aba <readi+0xcc>
    return 0;
    80003ae0:	4501                	li	a0,0
}
    80003ae2:	8082                	ret

0000000080003ae4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae4:	457c                	lw	a5,76(a0)
    80003ae6:	10d7e663          	bltu	a5,a3,80003bf2 <writei+0x10e>
{
    80003aea:	7159                	addi	sp,sp,-112
    80003aec:	f486                	sd	ra,104(sp)
    80003aee:	f0a2                	sd	s0,96(sp)
    80003af0:	eca6                	sd	s1,88(sp)
    80003af2:	e8ca                	sd	s2,80(sp)
    80003af4:	e4ce                	sd	s3,72(sp)
    80003af6:	e0d2                	sd	s4,64(sp)
    80003af8:	fc56                	sd	s5,56(sp)
    80003afa:	f85a                	sd	s6,48(sp)
    80003afc:	f45e                	sd	s7,40(sp)
    80003afe:	f062                	sd	s8,32(sp)
    80003b00:	ec66                	sd	s9,24(sp)
    80003b02:	e86a                	sd	s10,16(sp)
    80003b04:	e46e                	sd	s11,8(sp)
    80003b06:	1880                	addi	s0,sp,112
    80003b08:	8baa                	mv	s7,a0
    80003b0a:	8c2e                	mv	s8,a1
    80003b0c:	8ab2                	mv	s5,a2
    80003b0e:	8936                	mv	s2,a3
    80003b10:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b12:	00e687bb          	addw	a5,a3,a4
    80003b16:	0ed7e063          	bltu	a5,a3,80003bf6 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1a:	00043737          	lui	a4,0x43
    80003b1e:	0cf76e63          	bltu	a4,a5,80003bfa <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b22:	0a0b0763          	beqz	s6,80003bd0 <writei+0xec>
    80003b26:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b2c:	5cfd                	li	s9,-1
    80003b2e:	a091                	j	80003b72 <writei+0x8e>
    80003b30:	02099d93          	slli	s11,s3,0x20
    80003b34:	020ddd93          	srli	s11,s11,0x20
    80003b38:	05848513          	addi	a0,s1,88
    80003b3c:	86ee                	mv	a3,s11
    80003b3e:	8656                	mv	a2,s5
    80003b40:	85e2                	mv	a1,s8
    80003b42:	953a                	add	a0,a0,a4
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	98a080e7          	jalr	-1654(ra) # 800024ce <either_copyin>
    80003b4c:	07950263          	beq	a0,s9,80003bb0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b50:	8526                	mv	a0,s1
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	77a080e7          	jalr	1914(ra) # 800042cc <log_write>
    brelse(bp);
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	50c080e7          	jalr	1292(ra) # 80003068 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b64:	01498a3b          	addw	s4,s3,s4
    80003b68:	0129893b          	addw	s2,s3,s2
    80003b6c:	9aee                	add	s5,s5,s11
    80003b6e:	056a7663          	bgeu	s4,s6,80003bba <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b72:	000ba483          	lw	s1,0(s7)
    80003b76:	00a9559b          	srliw	a1,s2,0xa
    80003b7a:	855e                	mv	a0,s7
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	7b0080e7          	jalr	1968(ra) # 8000332c <bmap>
    80003b84:	0005059b          	sext.w	a1,a0
    80003b88:	8526                	mv	a0,s1
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	3ae080e7          	jalr	942(ra) # 80002f38 <bread>
    80003b92:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b94:	3ff97713          	andi	a4,s2,1023
    80003b98:	40ed07bb          	subw	a5,s10,a4
    80003b9c:	414b06bb          	subw	a3,s6,s4
    80003ba0:	89be                	mv	s3,a5
    80003ba2:	2781                	sext.w	a5,a5
    80003ba4:	0006861b          	sext.w	a2,a3
    80003ba8:	f8f674e3          	bgeu	a2,a5,80003b30 <writei+0x4c>
    80003bac:	89b6                	mv	s3,a3
    80003bae:	b749                	j	80003b30 <writei+0x4c>
      brelse(bp);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	4b6080e7          	jalr	1206(ra) # 80003068 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bba:	04cba783          	lw	a5,76(s7)
    80003bbe:	0127f463          	bgeu	a5,s2,80003bc6 <writei+0xe2>
      ip->size = off;
    80003bc2:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bc6:	855e                	mv	a0,s7
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	aa8080e7          	jalr	-1368(ra) # 80003670 <iupdate>
  }

  return n;
    80003bd0:	000b051b          	sext.w	a0,s6
}
    80003bd4:	70a6                	ld	ra,104(sp)
    80003bd6:	7406                	ld	s0,96(sp)
    80003bd8:	64e6                	ld	s1,88(sp)
    80003bda:	6946                	ld	s2,80(sp)
    80003bdc:	69a6                	ld	s3,72(sp)
    80003bde:	6a06                	ld	s4,64(sp)
    80003be0:	7ae2                	ld	s5,56(sp)
    80003be2:	7b42                	ld	s6,48(sp)
    80003be4:	7ba2                	ld	s7,40(sp)
    80003be6:	7c02                	ld	s8,32(sp)
    80003be8:	6ce2                	ld	s9,24(sp)
    80003bea:	6d42                	ld	s10,16(sp)
    80003bec:	6da2                	ld	s11,8(sp)
    80003bee:	6165                	addi	sp,sp,112
    80003bf0:	8082                	ret
    return -1;
    80003bf2:	557d                	li	a0,-1
}
    80003bf4:	8082                	ret
    return -1;
    80003bf6:	557d                	li	a0,-1
    80003bf8:	bff1                	j	80003bd4 <writei+0xf0>
    return -1;
    80003bfa:	557d                	li	a0,-1
    80003bfc:	bfe1                	j	80003bd4 <writei+0xf0>

0000000080003bfe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bfe:	1141                	addi	sp,sp,-16
    80003c00:	e406                	sd	ra,8(sp)
    80003c02:	e022                	sd	s0,0(sp)
    80003c04:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c06:	4639                	li	a2,14
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	204080e7          	jalr	516(ra) # 80000e0c <strncmp>
}
    80003c10:	60a2                	ld	ra,8(sp)
    80003c12:	6402                	ld	s0,0(sp)
    80003c14:	0141                	addi	sp,sp,16
    80003c16:	8082                	ret

0000000080003c18 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c18:	7139                	addi	sp,sp,-64
    80003c1a:	fc06                	sd	ra,56(sp)
    80003c1c:	f822                	sd	s0,48(sp)
    80003c1e:	f426                	sd	s1,40(sp)
    80003c20:	f04a                	sd	s2,32(sp)
    80003c22:	ec4e                	sd	s3,24(sp)
    80003c24:	e852                	sd	s4,16(sp)
    80003c26:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c28:	04451703          	lh	a4,68(a0)
    80003c2c:	4785                	li	a5,1
    80003c2e:	00f71a63          	bne	a4,a5,80003c42 <dirlookup+0x2a>
    80003c32:	892a                	mv	s2,a0
    80003c34:	89ae                	mv	s3,a1
    80003c36:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c38:	457c                	lw	a5,76(a0)
    80003c3a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c3c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3e:	e79d                	bnez	a5,80003c6c <dirlookup+0x54>
    80003c40:	a8a5                	j	80003cb8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c42:	00005517          	auipc	a0,0x5
    80003c46:	a6650513          	addi	a0,a0,-1434 # 800086a8 <syscalls+0x1b0>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8fe080e7          	jalr	-1794(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c52:	00005517          	auipc	a0,0x5
    80003c56:	a6e50513          	addi	a0,a0,-1426 # 800086c0 <syscalls+0x1c8>
    80003c5a:	ffffd097          	auipc	ra,0xffffd
    80003c5e:	8ee080e7          	jalr	-1810(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c62:	24c1                	addiw	s1,s1,16
    80003c64:	04c92783          	lw	a5,76(s2)
    80003c68:	04f4f763          	bgeu	s1,a5,80003cb6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c6c:	4741                	li	a4,16
    80003c6e:	86a6                	mv	a3,s1
    80003c70:	fc040613          	addi	a2,s0,-64
    80003c74:	4581                	li	a1,0
    80003c76:	854a                	mv	a0,s2
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	d76080e7          	jalr	-650(ra) # 800039ee <readi>
    80003c80:	47c1                	li	a5,16
    80003c82:	fcf518e3          	bne	a0,a5,80003c52 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c86:	fc045783          	lhu	a5,-64(s0)
    80003c8a:	dfe1                	beqz	a5,80003c62 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c8c:	fc240593          	addi	a1,s0,-62
    80003c90:	854e                	mv	a0,s3
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	f6c080e7          	jalr	-148(ra) # 80003bfe <namecmp>
    80003c9a:	f561                	bnez	a0,80003c62 <dirlookup+0x4a>
      if(poff)
    80003c9c:	000a0463          	beqz	s4,80003ca4 <dirlookup+0x8c>
        *poff = off;
    80003ca0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ca4:	fc045583          	lhu	a1,-64(s0)
    80003ca8:	00092503          	lw	a0,0(s2)
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	75a080e7          	jalr	1882(ra) # 80003406 <iget>
    80003cb4:	a011                	j	80003cb8 <dirlookup+0xa0>
  return 0;
    80003cb6:	4501                	li	a0,0
}
    80003cb8:	70e2                	ld	ra,56(sp)
    80003cba:	7442                	ld	s0,48(sp)
    80003cbc:	74a2                	ld	s1,40(sp)
    80003cbe:	7902                	ld	s2,32(sp)
    80003cc0:	69e2                	ld	s3,24(sp)
    80003cc2:	6a42                	ld	s4,16(sp)
    80003cc4:	6121                	addi	sp,sp,64
    80003cc6:	8082                	ret

0000000080003cc8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cc8:	711d                	addi	sp,sp,-96
    80003cca:	ec86                	sd	ra,88(sp)
    80003ccc:	e8a2                	sd	s0,80(sp)
    80003cce:	e4a6                	sd	s1,72(sp)
    80003cd0:	e0ca                	sd	s2,64(sp)
    80003cd2:	fc4e                	sd	s3,56(sp)
    80003cd4:	f852                	sd	s4,48(sp)
    80003cd6:	f456                	sd	s5,40(sp)
    80003cd8:	f05a                	sd	s6,32(sp)
    80003cda:	ec5e                	sd	s7,24(sp)
    80003cdc:	e862                	sd	s8,16(sp)
    80003cde:	e466                	sd	s9,8(sp)
    80003ce0:	1080                	addi	s0,sp,96
    80003ce2:	84aa                	mv	s1,a0
    80003ce4:	8b2e                	mv	s6,a1
    80003ce6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ce8:	00054703          	lbu	a4,0(a0)
    80003cec:	02f00793          	li	a5,47
    80003cf0:	02f70363          	beq	a4,a5,80003d16 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cf4:	ffffe097          	auipc	ra,0xffffe
    80003cf8:	d0e080e7          	jalr	-754(ra) # 80001a02 <myproc>
    80003cfc:	15053503          	ld	a0,336(a0)
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	9fc080e7          	jalr	-1540(ra) # 800036fc <idup>
    80003d08:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d0a:	02f00913          	li	s2,47
  len = path - s;
    80003d0e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d10:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d12:	4c05                	li	s8,1
    80003d14:	a865                	j	80003dcc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d16:	4585                	li	a1,1
    80003d18:	4505                	li	a0,1
    80003d1a:	fffff097          	auipc	ra,0xfffff
    80003d1e:	6ec080e7          	jalr	1772(ra) # 80003406 <iget>
    80003d22:	89aa                	mv	s3,a0
    80003d24:	b7dd                	j	80003d0a <namex+0x42>
      iunlockput(ip);
    80003d26:	854e                	mv	a0,s3
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	c74080e7          	jalr	-908(ra) # 8000399c <iunlockput>
      return 0;
    80003d30:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d32:	854e                	mv	a0,s3
    80003d34:	60e6                	ld	ra,88(sp)
    80003d36:	6446                	ld	s0,80(sp)
    80003d38:	64a6                	ld	s1,72(sp)
    80003d3a:	6906                	ld	s2,64(sp)
    80003d3c:	79e2                	ld	s3,56(sp)
    80003d3e:	7a42                	ld	s4,48(sp)
    80003d40:	7aa2                	ld	s5,40(sp)
    80003d42:	7b02                	ld	s6,32(sp)
    80003d44:	6be2                	ld	s7,24(sp)
    80003d46:	6c42                	ld	s8,16(sp)
    80003d48:	6ca2                	ld	s9,8(sp)
    80003d4a:	6125                	addi	sp,sp,96
    80003d4c:	8082                	ret
      iunlock(ip);
    80003d4e:	854e                	mv	a0,s3
    80003d50:	00000097          	auipc	ra,0x0
    80003d54:	aac080e7          	jalr	-1364(ra) # 800037fc <iunlock>
      return ip;
    80003d58:	bfe9                	j	80003d32 <namex+0x6a>
      iunlockput(ip);
    80003d5a:	854e                	mv	a0,s3
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	c40080e7          	jalr	-960(ra) # 8000399c <iunlockput>
      return 0;
    80003d64:	89d2                	mv	s3,s4
    80003d66:	b7f1                	j	80003d32 <namex+0x6a>
  len = path - s;
    80003d68:	40b48633          	sub	a2,s1,a1
    80003d6c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d70:	094cd463          	bge	s9,s4,80003df8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d74:	4639                	li	a2,14
    80003d76:	8556                	mv	a0,s5
    80003d78:	ffffd097          	auipc	ra,0xffffd
    80003d7c:	018080e7          	jalr	24(ra) # 80000d90 <memmove>
  while(*path == '/')
    80003d80:	0004c783          	lbu	a5,0(s1)
    80003d84:	01279763          	bne	a5,s2,80003d92 <namex+0xca>
    path++;
    80003d88:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d8a:	0004c783          	lbu	a5,0(s1)
    80003d8e:	ff278de3          	beq	a5,s2,80003d88 <namex+0xc0>
    ilock(ip);
    80003d92:	854e                	mv	a0,s3
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	9a6080e7          	jalr	-1626(ra) # 8000373a <ilock>
    if(ip->type != T_DIR){
    80003d9c:	04499783          	lh	a5,68(s3)
    80003da0:	f98793e3          	bne	a5,s8,80003d26 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003da4:	000b0563          	beqz	s6,80003dae <namex+0xe6>
    80003da8:	0004c783          	lbu	a5,0(s1)
    80003dac:	d3cd                	beqz	a5,80003d4e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dae:	865e                	mv	a2,s7
    80003db0:	85d6                	mv	a1,s5
    80003db2:	854e                	mv	a0,s3
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	e64080e7          	jalr	-412(ra) # 80003c18 <dirlookup>
    80003dbc:	8a2a                	mv	s4,a0
    80003dbe:	dd51                	beqz	a0,80003d5a <namex+0x92>
    iunlockput(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	bda080e7          	jalr	-1062(ra) # 8000399c <iunlockput>
    ip = next;
    80003dca:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dcc:	0004c783          	lbu	a5,0(s1)
    80003dd0:	05279763          	bne	a5,s2,80003e1e <namex+0x156>
    path++;
    80003dd4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dd6:	0004c783          	lbu	a5,0(s1)
    80003dda:	ff278de3          	beq	a5,s2,80003dd4 <namex+0x10c>
  if(*path == 0)
    80003dde:	c79d                	beqz	a5,80003e0c <namex+0x144>
    path++;
    80003de0:	85a6                	mv	a1,s1
  len = path - s;
    80003de2:	8a5e                	mv	s4,s7
    80003de4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003de6:	01278963          	beq	a5,s2,80003df8 <namex+0x130>
    80003dea:	dfbd                	beqz	a5,80003d68 <namex+0xa0>
    path++;
    80003dec:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003dee:	0004c783          	lbu	a5,0(s1)
    80003df2:	ff279ce3          	bne	a5,s2,80003dea <namex+0x122>
    80003df6:	bf8d                	j	80003d68 <namex+0xa0>
    memmove(name, s, len);
    80003df8:	2601                	sext.w	a2,a2
    80003dfa:	8556                	mv	a0,s5
    80003dfc:	ffffd097          	auipc	ra,0xffffd
    80003e00:	f94080e7          	jalr	-108(ra) # 80000d90 <memmove>
    name[len] = 0;
    80003e04:	9a56                	add	s4,s4,s5
    80003e06:	000a0023          	sb	zero,0(s4)
    80003e0a:	bf9d                	j	80003d80 <namex+0xb8>
  if(nameiparent){
    80003e0c:	f20b03e3          	beqz	s6,80003d32 <namex+0x6a>
    iput(ip);
    80003e10:	854e                	mv	a0,s3
    80003e12:	00000097          	auipc	ra,0x0
    80003e16:	ae2080e7          	jalr	-1310(ra) # 800038f4 <iput>
    return 0;
    80003e1a:	4981                	li	s3,0
    80003e1c:	bf19                	j	80003d32 <namex+0x6a>
  if(*path == 0)
    80003e1e:	d7fd                	beqz	a5,80003e0c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e20:	0004c783          	lbu	a5,0(s1)
    80003e24:	85a6                	mv	a1,s1
    80003e26:	b7d1                	j	80003dea <namex+0x122>

0000000080003e28 <dirlink>:
{
    80003e28:	7139                	addi	sp,sp,-64
    80003e2a:	fc06                	sd	ra,56(sp)
    80003e2c:	f822                	sd	s0,48(sp)
    80003e2e:	f426                	sd	s1,40(sp)
    80003e30:	f04a                	sd	s2,32(sp)
    80003e32:	ec4e                	sd	s3,24(sp)
    80003e34:	e852                	sd	s4,16(sp)
    80003e36:	0080                	addi	s0,sp,64
    80003e38:	892a                	mv	s2,a0
    80003e3a:	8a2e                	mv	s4,a1
    80003e3c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e3e:	4601                	li	a2,0
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	dd8080e7          	jalr	-552(ra) # 80003c18 <dirlookup>
    80003e48:	e93d                	bnez	a0,80003ebe <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4a:	04c92483          	lw	s1,76(s2)
    80003e4e:	c49d                	beqz	s1,80003e7c <dirlink+0x54>
    80003e50:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e52:	4741                	li	a4,16
    80003e54:	86a6                	mv	a3,s1
    80003e56:	fc040613          	addi	a2,s0,-64
    80003e5a:	4581                	li	a1,0
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	b90080e7          	jalr	-1136(ra) # 800039ee <readi>
    80003e66:	47c1                	li	a5,16
    80003e68:	06f51163          	bne	a0,a5,80003eca <dirlink+0xa2>
    if(de.inum == 0)
    80003e6c:	fc045783          	lhu	a5,-64(s0)
    80003e70:	c791                	beqz	a5,80003e7c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e72:	24c1                	addiw	s1,s1,16
    80003e74:	04c92783          	lw	a5,76(s2)
    80003e78:	fcf4ede3          	bltu	s1,a5,80003e52 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e7c:	4639                	li	a2,14
    80003e7e:	85d2                	mv	a1,s4
    80003e80:	fc240513          	addi	a0,s0,-62
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	fc4080e7          	jalr	-60(ra) # 80000e48 <strncpy>
  de.inum = inum;
    80003e8c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e90:	4741                	li	a4,16
    80003e92:	86a6                	mv	a3,s1
    80003e94:	fc040613          	addi	a2,s0,-64
    80003e98:	4581                	li	a1,0
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	c48080e7          	jalr	-952(ra) # 80003ae4 <writei>
    80003ea4:	872a                	mv	a4,a0
    80003ea6:	47c1                	li	a5,16
  return 0;
    80003ea8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eaa:	02f71863          	bne	a4,a5,80003eda <dirlink+0xb2>
}
    80003eae:	70e2                	ld	ra,56(sp)
    80003eb0:	7442                	ld	s0,48(sp)
    80003eb2:	74a2                	ld	s1,40(sp)
    80003eb4:	7902                	ld	s2,32(sp)
    80003eb6:	69e2                	ld	s3,24(sp)
    80003eb8:	6a42                	ld	s4,16(sp)
    80003eba:	6121                	addi	sp,sp,64
    80003ebc:	8082                	ret
    iput(ip);
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	a36080e7          	jalr	-1482(ra) # 800038f4 <iput>
    return -1;
    80003ec6:	557d                	li	a0,-1
    80003ec8:	b7dd                	j	80003eae <dirlink+0x86>
      panic("dirlink read");
    80003eca:	00005517          	auipc	a0,0x5
    80003ece:	80650513          	addi	a0,a0,-2042 # 800086d0 <syscalls+0x1d8>
    80003ed2:	ffffc097          	auipc	ra,0xffffc
    80003ed6:	676080e7          	jalr	1654(ra) # 80000548 <panic>
    panic("dirlink");
    80003eda:	00005517          	auipc	a0,0x5
    80003ede:	90e50513          	addi	a0,a0,-1778 # 800087e8 <syscalls+0x2f0>
    80003ee2:	ffffc097          	auipc	ra,0xffffc
    80003ee6:	666080e7          	jalr	1638(ra) # 80000548 <panic>

0000000080003eea <namei>:

struct inode*
namei(char *path)
{
    80003eea:	1101                	addi	sp,sp,-32
    80003eec:	ec06                	sd	ra,24(sp)
    80003eee:	e822                	sd	s0,16(sp)
    80003ef0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef2:	fe040613          	addi	a2,s0,-32
    80003ef6:	4581                	li	a1,0
    80003ef8:	00000097          	auipc	ra,0x0
    80003efc:	dd0080e7          	jalr	-560(ra) # 80003cc8 <namex>
}
    80003f00:	60e2                	ld	ra,24(sp)
    80003f02:	6442                	ld	s0,16(sp)
    80003f04:	6105                	addi	sp,sp,32
    80003f06:	8082                	ret

0000000080003f08 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f08:	1141                	addi	sp,sp,-16
    80003f0a:	e406                	sd	ra,8(sp)
    80003f0c:	e022                	sd	s0,0(sp)
    80003f0e:	0800                	addi	s0,sp,16
    80003f10:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f12:	4585                	li	a1,1
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	db4080e7          	jalr	-588(ra) # 80003cc8 <namex>
}
    80003f1c:	60a2                	ld	ra,8(sp)
    80003f1e:	6402                	ld	s0,0(sp)
    80003f20:	0141                	addi	sp,sp,16
    80003f22:	8082                	ret

0000000080003f24 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f24:	1101                	addi	sp,sp,-32
    80003f26:	ec06                	sd	ra,24(sp)
    80003f28:	e822                	sd	s0,16(sp)
    80003f2a:	e426                	sd	s1,8(sp)
    80003f2c:	e04a                	sd	s2,0(sp)
    80003f2e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f30:	0001e917          	auipc	s2,0x1e
    80003f34:	bd890913          	addi	s2,s2,-1064 # 80021b08 <log>
    80003f38:	01892583          	lw	a1,24(s2)
    80003f3c:	02892503          	lw	a0,40(s2)
    80003f40:	fffff097          	auipc	ra,0xfffff
    80003f44:	ff8080e7          	jalr	-8(ra) # 80002f38 <bread>
    80003f48:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f4a:	02c92683          	lw	a3,44(s2)
    80003f4e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f50:	02d05763          	blez	a3,80003f7e <write_head+0x5a>
    80003f54:	0001e797          	auipc	a5,0x1e
    80003f58:	be478793          	addi	a5,a5,-1052 # 80021b38 <log+0x30>
    80003f5c:	05c50713          	addi	a4,a0,92
    80003f60:	36fd                	addiw	a3,a3,-1
    80003f62:	1682                	slli	a3,a3,0x20
    80003f64:	9281                	srli	a3,a3,0x20
    80003f66:	068a                	slli	a3,a3,0x2
    80003f68:	0001e617          	auipc	a2,0x1e
    80003f6c:	bd460613          	addi	a2,a2,-1068 # 80021b3c <log+0x34>
    80003f70:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f72:	4390                	lw	a2,0(a5)
    80003f74:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f76:	0791                	addi	a5,a5,4
    80003f78:	0711                	addi	a4,a4,4
    80003f7a:	fed79ce3          	bne	a5,a3,80003f72 <write_head+0x4e>
  }
  bwrite(buf);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	0aa080e7          	jalr	170(ra) # 8000302a <bwrite>
  brelse(buf);
    80003f88:	8526                	mv	a0,s1
    80003f8a:	fffff097          	auipc	ra,0xfffff
    80003f8e:	0de080e7          	jalr	222(ra) # 80003068 <brelse>
}
    80003f92:	60e2                	ld	ra,24(sp)
    80003f94:	6442                	ld	s0,16(sp)
    80003f96:	64a2                	ld	s1,8(sp)
    80003f98:	6902                	ld	s2,0(sp)
    80003f9a:	6105                	addi	sp,sp,32
    80003f9c:	8082                	ret

0000000080003f9e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f9e:	0001e797          	auipc	a5,0x1e
    80003fa2:	b967a783          	lw	a5,-1130(a5) # 80021b34 <log+0x2c>
    80003fa6:	0af05663          	blez	a5,80004052 <install_trans+0xb4>
{
    80003faa:	7139                	addi	sp,sp,-64
    80003fac:	fc06                	sd	ra,56(sp)
    80003fae:	f822                	sd	s0,48(sp)
    80003fb0:	f426                	sd	s1,40(sp)
    80003fb2:	f04a                	sd	s2,32(sp)
    80003fb4:	ec4e                	sd	s3,24(sp)
    80003fb6:	e852                	sd	s4,16(sp)
    80003fb8:	e456                	sd	s5,8(sp)
    80003fba:	0080                	addi	s0,sp,64
    80003fbc:	0001ea97          	auipc	s5,0x1e
    80003fc0:	b7ca8a93          	addi	s5,s5,-1156 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fc6:	0001e997          	auipc	s3,0x1e
    80003fca:	b4298993          	addi	s3,s3,-1214 # 80021b08 <log>
    80003fce:	0189a583          	lw	a1,24(s3)
    80003fd2:	014585bb          	addw	a1,a1,s4
    80003fd6:	2585                	addiw	a1,a1,1
    80003fd8:	0289a503          	lw	a0,40(s3)
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	f5c080e7          	jalr	-164(ra) # 80002f38 <bread>
    80003fe4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fe6:	000aa583          	lw	a1,0(s5)
    80003fea:	0289a503          	lw	a0,40(s3)
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	f4a080e7          	jalr	-182(ra) # 80002f38 <bread>
    80003ff6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ff8:	40000613          	li	a2,1024
    80003ffc:	05890593          	addi	a1,s2,88
    80004000:	05850513          	addi	a0,a0,88
    80004004:	ffffd097          	auipc	ra,0xffffd
    80004008:	d8c080e7          	jalr	-628(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000400c:	8526                	mv	a0,s1
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	01c080e7          	jalr	28(ra) # 8000302a <bwrite>
    bunpin(dbuf);
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	12a080e7          	jalr	298(ra) # 80003142 <bunpin>
    brelse(lbuf);
    80004020:	854a                	mv	a0,s2
    80004022:	fffff097          	auipc	ra,0xfffff
    80004026:	046080e7          	jalr	70(ra) # 80003068 <brelse>
    brelse(dbuf);
    8000402a:	8526                	mv	a0,s1
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	03c080e7          	jalr	60(ra) # 80003068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004034:	2a05                	addiw	s4,s4,1
    80004036:	0a91                	addi	s5,s5,4
    80004038:	02c9a783          	lw	a5,44(s3)
    8000403c:	f8fa49e3          	blt	s4,a5,80003fce <install_trans+0x30>
}
    80004040:	70e2                	ld	ra,56(sp)
    80004042:	7442                	ld	s0,48(sp)
    80004044:	74a2                	ld	s1,40(sp)
    80004046:	7902                	ld	s2,32(sp)
    80004048:	69e2                	ld	s3,24(sp)
    8000404a:	6a42                	ld	s4,16(sp)
    8000404c:	6aa2                	ld	s5,8(sp)
    8000404e:	6121                	addi	sp,sp,64
    80004050:	8082                	ret
    80004052:	8082                	ret

0000000080004054 <initlog>:
{
    80004054:	7179                	addi	sp,sp,-48
    80004056:	f406                	sd	ra,40(sp)
    80004058:	f022                	sd	s0,32(sp)
    8000405a:	ec26                	sd	s1,24(sp)
    8000405c:	e84a                	sd	s2,16(sp)
    8000405e:	e44e                	sd	s3,8(sp)
    80004060:	1800                	addi	s0,sp,48
    80004062:	892a                	mv	s2,a0
    80004064:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004066:	0001e497          	auipc	s1,0x1e
    8000406a:	aa248493          	addi	s1,s1,-1374 # 80021b08 <log>
    8000406e:	00004597          	auipc	a1,0x4
    80004072:	67258593          	addi	a1,a1,1650 # 800086e0 <syscalls+0x1e8>
    80004076:	8526                	mv	a0,s1
    80004078:	ffffd097          	auipc	ra,0xffffd
    8000407c:	b2c080e7          	jalr	-1236(ra) # 80000ba4 <initlock>
  log.start = sb->logstart;
    80004080:	0149a583          	lw	a1,20(s3)
    80004084:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004086:	0109a783          	lw	a5,16(s3)
    8000408a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000408c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004090:	854a                	mv	a0,s2
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	ea6080e7          	jalr	-346(ra) # 80002f38 <bread>
  log.lh.n = lh->n;
    8000409a:	4d3c                	lw	a5,88(a0)
    8000409c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000409e:	02f05563          	blez	a5,800040c8 <initlog+0x74>
    800040a2:	05c50713          	addi	a4,a0,92
    800040a6:	0001e697          	auipc	a3,0x1e
    800040aa:	a9268693          	addi	a3,a3,-1390 # 80021b38 <log+0x30>
    800040ae:	37fd                	addiw	a5,a5,-1
    800040b0:	1782                	slli	a5,a5,0x20
    800040b2:	9381                	srli	a5,a5,0x20
    800040b4:	078a                	slli	a5,a5,0x2
    800040b6:	06050613          	addi	a2,a0,96
    800040ba:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040bc:	4310                	lw	a2,0(a4)
    800040be:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040c0:	0711                	addi	a4,a4,4
    800040c2:	0691                	addi	a3,a3,4
    800040c4:	fef71ce3          	bne	a4,a5,800040bc <initlog+0x68>
  brelse(buf);
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	fa0080e7          	jalr	-96(ra) # 80003068 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	ece080e7          	jalr	-306(ra) # 80003f9e <install_trans>
  log.lh.n = 0;
    800040d8:	0001e797          	auipc	a5,0x1e
    800040dc:	a407ae23          	sw	zero,-1444(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	e44080e7          	jalr	-444(ra) # 80003f24 <write_head>
}
    800040e8:	70a2                	ld	ra,40(sp)
    800040ea:	7402                	ld	s0,32(sp)
    800040ec:	64e2                	ld	s1,24(sp)
    800040ee:	6942                	ld	s2,16(sp)
    800040f0:	69a2                	ld	s3,8(sp)
    800040f2:	6145                	addi	sp,sp,48
    800040f4:	8082                	ret

00000000800040f6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040f6:	1101                	addi	sp,sp,-32
    800040f8:	ec06                	sd	ra,24(sp)
    800040fa:	e822                	sd	s0,16(sp)
    800040fc:	e426                	sd	s1,8(sp)
    800040fe:	e04a                	sd	s2,0(sp)
    80004100:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004102:	0001e517          	auipc	a0,0x1e
    80004106:	a0650513          	addi	a0,a0,-1530 # 80021b08 <log>
    8000410a:	ffffd097          	auipc	ra,0xffffd
    8000410e:	b2a080e7          	jalr	-1238(ra) # 80000c34 <acquire>
  while(1){
    if(log.committing){
    80004112:	0001e497          	auipc	s1,0x1e
    80004116:	9f648493          	addi	s1,s1,-1546 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411a:	4979                	li	s2,30
    8000411c:	a039                	j	8000412a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000411e:	85a6                	mv	a1,s1
    80004120:	8526                	mv	a0,s1
    80004122:	ffffe097          	auipc	ra,0xffffe
    80004126:	0f4080e7          	jalr	244(ra) # 80002216 <sleep>
    if(log.committing){
    8000412a:	50dc                	lw	a5,36(s1)
    8000412c:	fbed                	bnez	a5,8000411e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000412e:	509c                	lw	a5,32(s1)
    80004130:	0017871b          	addiw	a4,a5,1
    80004134:	0007069b          	sext.w	a3,a4
    80004138:	0027179b          	slliw	a5,a4,0x2
    8000413c:	9fb9                	addw	a5,a5,a4
    8000413e:	0017979b          	slliw	a5,a5,0x1
    80004142:	54d8                	lw	a4,44(s1)
    80004144:	9fb9                	addw	a5,a5,a4
    80004146:	00f95963          	bge	s2,a5,80004158 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414a:	85a6                	mv	a1,s1
    8000414c:	8526                	mv	a0,s1
    8000414e:	ffffe097          	auipc	ra,0xffffe
    80004152:	0c8080e7          	jalr	200(ra) # 80002216 <sleep>
    80004156:	bfd1                	j	8000412a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004158:	0001e517          	auipc	a0,0x1e
    8000415c:	9b050513          	addi	a0,a0,-1616 # 80021b08 <log>
    80004160:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004162:	ffffd097          	auipc	ra,0xffffd
    80004166:	b86080e7          	jalr	-1146(ra) # 80000ce8 <release>
      break;
    }
  }
}
    8000416a:	60e2                	ld	ra,24(sp)
    8000416c:	6442                	ld	s0,16(sp)
    8000416e:	64a2                	ld	s1,8(sp)
    80004170:	6902                	ld	s2,0(sp)
    80004172:	6105                	addi	sp,sp,32
    80004174:	8082                	ret

0000000080004176 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004176:	7139                	addi	sp,sp,-64
    80004178:	fc06                	sd	ra,56(sp)
    8000417a:	f822                	sd	s0,48(sp)
    8000417c:	f426                	sd	s1,40(sp)
    8000417e:	f04a                	sd	s2,32(sp)
    80004180:	ec4e                	sd	s3,24(sp)
    80004182:	e852                	sd	s4,16(sp)
    80004184:	e456                	sd	s5,8(sp)
    80004186:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004188:	0001e497          	auipc	s1,0x1e
    8000418c:	98048493          	addi	s1,s1,-1664 # 80021b08 <log>
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	aa2080e7          	jalr	-1374(ra) # 80000c34 <acquire>
  log.outstanding -= 1;
    8000419a:	509c                	lw	a5,32(s1)
    8000419c:	37fd                	addiw	a5,a5,-1
    8000419e:	0007891b          	sext.w	s2,a5
    800041a2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a4:	50dc                	lw	a5,36(s1)
    800041a6:	efb9                	bnez	a5,80004204 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041a8:	06091663          	bnez	s2,80004214 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041ac:	0001e497          	auipc	s1,0x1e
    800041b0:	95c48493          	addi	s1,s1,-1700 # 80021b08 <log>
    800041b4:	4785                	li	a5,1
    800041b6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041b8:	8526                	mv	a0,s1
    800041ba:	ffffd097          	auipc	ra,0xffffd
    800041be:	b2e080e7          	jalr	-1234(ra) # 80000ce8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c2:	54dc                	lw	a5,44(s1)
    800041c4:	06f04763          	bgtz	a5,80004232 <end_op+0xbc>
    acquire(&log.lock);
    800041c8:	0001e497          	auipc	s1,0x1e
    800041cc:	94048493          	addi	s1,s1,-1728 # 80021b08 <log>
    800041d0:	8526                	mv	a0,s1
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	a62080e7          	jalr	-1438(ra) # 80000c34 <acquire>
    log.committing = 0;
    800041da:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	1bc080e7          	jalr	444(ra) # 8000239c <wakeup>
    release(&log.lock);
    800041e8:	8526                	mv	a0,s1
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	afe080e7          	jalr	-1282(ra) # 80000ce8 <release>
}
    800041f2:	70e2                	ld	ra,56(sp)
    800041f4:	7442                	ld	s0,48(sp)
    800041f6:	74a2                	ld	s1,40(sp)
    800041f8:	7902                	ld	s2,32(sp)
    800041fa:	69e2                	ld	s3,24(sp)
    800041fc:	6a42                	ld	s4,16(sp)
    800041fe:	6aa2                	ld	s5,8(sp)
    80004200:	6121                	addi	sp,sp,64
    80004202:	8082                	ret
    panic("log.committing");
    80004204:	00004517          	auipc	a0,0x4
    80004208:	4e450513          	addi	a0,a0,1252 # 800086e8 <syscalls+0x1f0>
    8000420c:	ffffc097          	auipc	ra,0xffffc
    80004210:	33c080e7          	jalr	828(ra) # 80000548 <panic>
    wakeup(&log);
    80004214:	0001e497          	auipc	s1,0x1e
    80004218:	8f448493          	addi	s1,s1,-1804 # 80021b08 <log>
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffe097          	auipc	ra,0xffffe
    80004222:	17e080e7          	jalr	382(ra) # 8000239c <wakeup>
  release(&log.lock);
    80004226:	8526                	mv	a0,s1
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	ac0080e7          	jalr	-1344(ra) # 80000ce8 <release>
  if(do_commit){
    80004230:	b7c9                	j	800041f2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004232:	0001ea97          	auipc	s5,0x1e
    80004236:	906a8a93          	addi	s5,s5,-1786 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423a:	0001ea17          	auipc	s4,0x1e
    8000423e:	8cea0a13          	addi	s4,s4,-1842 # 80021b08 <log>
    80004242:	018a2583          	lw	a1,24(s4)
    80004246:	012585bb          	addw	a1,a1,s2
    8000424a:	2585                	addiw	a1,a1,1
    8000424c:	028a2503          	lw	a0,40(s4)
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	ce8080e7          	jalr	-792(ra) # 80002f38 <bread>
    80004258:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425a:	000aa583          	lw	a1,0(s5)
    8000425e:	028a2503          	lw	a0,40(s4)
    80004262:	fffff097          	auipc	ra,0xfffff
    80004266:	cd6080e7          	jalr	-810(ra) # 80002f38 <bread>
    8000426a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000426c:	40000613          	li	a2,1024
    80004270:	05850593          	addi	a1,a0,88
    80004274:	05848513          	addi	a0,s1,88
    80004278:	ffffd097          	auipc	ra,0xffffd
    8000427c:	b18080e7          	jalr	-1256(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    80004280:	8526                	mv	a0,s1
    80004282:	fffff097          	auipc	ra,0xfffff
    80004286:	da8080e7          	jalr	-600(ra) # 8000302a <bwrite>
    brelse(from);
    8000428a:	854e                	mv	a0,s3
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	ddc080e7          	jalr	-548(ra) # 80003068 <brelse>
    brelse(to);
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	dd2080e7          	jalr	-558(ra) # 80003068 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429e:	2905                	addiw	s2,s2,1
    800042a0:	0a91                	addi	s5,s5,4
    800042a2:	02ca2783          	lw	a5,44(s4)
    800042a6:	f8f94ee3          	blt	s2,a5,80004242 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	c7a080e7          	jalr	-902(ra) # 80003f24 <write_head>
    install_trans(); // Now install writes to home locations
    800042b2:	00000097          	auipc	ra,0x0
    800042b6:	cec080e7          	jalr	-788(ra) # 80003f9e <install_trans>
    log.lh.n = 0;
    800042ba:	0001e797          	auipc	a5,0x1e
    800042be:	8607ad23          	sw	zero,-1926(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c2:	00000097          	auipc	ra,0x0
    800042c6:	c62080e7          	jalr	-926(ra) # 80003f24 <write_head>
    800042ca:	bdfd                	j	800041c8 <end_op+0x52>

00000000800042cc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042cc:	1101                	addi	sp,sp,-32
    800042ce:	ec06                	sd	ra,24(sp)
    800042d0:	e822                	sd	s0,16(sp)
    800042d2:	e426                	sd	s1,8(sp)
    800042d4:	e04a                	sd	s2,0(sp)
    800042d6:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042d8:	0001e717          	auipc	a4,0x1e
    800042dc:	85c72703          	lw	a4,-1956(a4) # 80021b34 <log+0x2c>
    800042e0:	47f5                	li	a5,29
    800042e2:	08e7c063          	blt	a5,a4,80004362 <log_write+0x96>
    800042e6:	84aa                	mv	s1,a0
    800042e8:	0001e797          	auipc	a5,0x1e
    800042ec:	83c7a783          	lw	a5,-1988(a5) # 80021b24 <log+0x1c>
    800042f0:	37fd                	addiw	a5,a5,-1
    800042f2:	06f75863          	bge	a4,a5,80004362 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042f6:	0001e797          	auipc	a5,0x1e
    800042fa:	8327a783          	lw	a5,-1998(a5) # 80021b28 <log+0x20>
    800042fe:	06f05a63          	blez	a5,80004372 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004302:	0001e917          	auipc	s2,0x1e
    80004306:	80690913          	addi	s2,s2,-2042 # 80021b08 <log>
    8000430a:	854a                	mv	a0,s2
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	928080e7          	jalr	-1752(ra) # 80000c34 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004314:	02c92603          	lw	a2,44(s2)
    80004318:	06c05563          	blez	a2,80004382 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000431c:	44cc                	lw	a1,12(s1)
    8000431e:	0001e717          	auipc	a4,0x1e
    80004322:	81a70713          	addi	a4,a4,-2022 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004326:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004328:	4314                	lw	a3,0(a4)
    8000432a:	04b68d63          	beq	a3,a1,80004384 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	2785                	addiw	a5,a5,1
    80004330:	0711                	addi	a4,a4,4
    80004332:	fec79be3          	bne	a5,a2,80004328 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004336:	0621                	addi	a2,a2,8
    80004338:	060a                	slli	a2,a2,0x2
    8000433a:	0001d797          	auipc	a5,0x1d
    8000433e:	7ce78793          	addi	a5,a5,1998 # 80021b08 <log>
    80004342:	963e                	add	a2,a2,a5
    80004344:	44dc                	lw	a5,12(s1)
    80004346:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004348:	8526                	mv	a0,s1
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	dbc080e7          	jalr	-580(ra) # 80003106 <bpin>
    log.lh.n++;
    80004352:	0001d717          	auipc	a4,0x1d
    80004356:	7b670713          	addi	a4,a4,1974 # 80021b08 <log>
    8000435a:	575c                	lw	a5,44(a4)
    8000435c:	2785                	addiw	a5,a5,1
    8000435e:	d75c                	sw	a5,44(a4)
    80004360:	a83d                	j	8000439e <log_write+0xd2>
    panic("too big a transaction");
    80004362:	00004517          	auipc	a0,0x4
    80004366:	39650513          	addi	a0,a0,918 # 800086f8 <syscalls+0x200>
    8000436a:	ffffc097          	auipc	ra,0xffffc
    8000436e:	1de080e7          	jalr	478(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004372:	00004517          	auipc	a0,0x4
    80004376:	39e50513          	addi	a0,a0,926 # 80008710 <syscalls+0x218>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1ce080e7          	jalr	462(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004382:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004384:	00878713          	addi	a4,a5,8
    80004388:	00271693          	slli	a3,a4,0x2
    8000438c:	0001d717          	auipc	a4,0x1d
    80004390:	77c70713          	addi	a4,a4,1916 # 80021b08 <log>
    80004394:	9736                	add	a4,a4,a3
    80004396:	44d4                	lw	a3,12(s1)
    80004398:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000439a:	faf607e3          	beq	a2,a5,80004348 <log_write+0x7c>
  }
  release(&log.lock);
    8000439e:	0001d517          	auipc	a0,0x1d
    800043a2:	76a50513          	addi	a0,a0,1898 # 80021b08 <log>
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	942080e7          	jalr	-1726(ra) # 80000ce8 <release>
}
    800043ae:	60e2                	ld	ra,24(sp)
    800043b0:	6442                	ld	s0,16(sp)
    800043b2:	64a2                	ld	s1,8(sp)
    800043b4:	6902                	ld	s2,0(sp)
    800043b6:	6105                	addi	sp,sp,32
    800043b8:	8082                	ret

00000000800043ba <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043ba:	1101                	addi	sp,sp,-32
    800043bc:	ec06                	sd	ra,24(sp)
    800043be:	e822                	sd	s0,16(sp)
    800043c0:	e426                	sd	s1,8(sp)
    800043c2:	e04a                	sd	s2,0(sp)
    800043c4:	1000                	addi	s0,sp,32
    800043c6:	84aa                	mv	s1,a0
    800043c8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043ca:	00004597          	auipc	a1,0x4
    800043ce:	36658593          	addi	a1,a1,870 # 80008730 <syscalls+0x238>
    800043d2:	0521                	addi	a0,a0,8
    800043d4:	ffffc097          	auipc	ra,0xffffc
    800043d8:	7d0080e7          	jalr	2000(ra) # 80000ba4 <initlock>
  lk->name = name;
    800043dc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e4:	0204a423          	sw	zero,40(s1)
}
    800043e8:	60e2                	ld	ra,24(sp)
    800043ea:	6442                	ld	s0,16(sp)
    800043ec:	64a2                	ld	s1,8(sp)
    800043ee:	6902                	ld	s2,0(sp)
    800043f0:	6105                	addi	sp,sp,32
    800043f2:	8082                	ret

00000000800043f4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f4:	1101                	addi	sp,sp,-32
    800043f6:	ec06                	sd	ra,24(sp)
    800043f8:	e822                	sd	s0,16(sp)
    800043fa:	e426                	sd	s1,8(sp)
    800043fc:	e04a                	sd	s2,0(sp)
    800043fe:	1000                	addi	s0,sp,32
    80004400:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004402:	00850913          	addi	s2,a0,8
    80004406:	854a                	mv	a0,s2
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	82c080e7          	jalr	-2004(ra) # 80000c34 <acquire>
  while (lk->locked) {
    80004410:	409c                	lw	a5,0(s1)
    80004412:	cb89                	beqz	a5,80004424 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004414:	85ca                	mv	a1,s2
    80004416:	8526                	mv	a0,s1
    80004418:	ffffe097          	auipc	ra,0xffffe
    8000441c:	dfe080e7          	jalr	-514(ra) # 80002216 <sleep>
  while (lk->locked) {
    80004420:	409c                	lw	a5,0(s1)
    80004422:	fbed                	bnez	a5,80004414 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004424:	4785                	li	a5,1
    80004426:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004428:	ffffd097          	auipc	ra,0xffffd
    8000442c:	5da080e7          	jalr	1498(ra) # 80001a02 <myproc>
    80004430:	5d1c                	lw	a5,56(a0)
    80004432:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004434:	854a                	mv	a0,s2
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	8b2080e7          	jalr	-1870(ra) # 80000ce8 <release>
}
    8000443e:	60e2                	ld	ra,24(sp)
    80004440:	6442                	ld	s0,16(sp)
    80004442:	64a2                	ld	s1,8(sp)
    80004444:	6902                	ld	s2,0(sp)
    80004446:	6105                	addi	sp,sp,32
    80004448:	8082                	ret

000000008000444a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000444a:	1101                	addi	sp,sp,-32
    8000444c:	ec06                	sd	ra,24(sp)
    8000444e:	e822                	sd	s0,16(sp)
    80004450:	e426                	sd	s1,8(sp)
    80004452:	e04a                	sd	s2,0(sp)
    80004454:	1000                	addi	s0,sp,32
    80004456:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004458:	00850913          	addi	s2,a0,8
    8000445c:	854a                	mv	a0,s2
    8000445e:	ffffc097          	auipc	ra,0xffffc
    80004462:	7d6080e7          	jalr	2006(ra) # 80000c34 <acquire>
  lk->locked = 0;
    80004466:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000446e:	8526                	mv	a0,s1
    80004470:	ffffe097          	auipc	ra,0xffffe
    80004474:	f2c080e7          	jalr	-212(ra) # 8000239c <wakeup>
  release(&lk->lk);
    80004478:	854a                	mv	a0,s2
    8000447a:	ffffd097          	auipc	ra,0xffffd
    8000447e:	86e080e7          	jalr	-1938(ra) # 80000ce8 <release>
}
    80004482:	60e2                	ld	ra,24(sp)
    80004484:	6442                	ld	s0,16(sp)
    80004486:	64a2                	ld	s1,8(sp)
    80004488:	6902                	ld	s2,0(sp)
    8000448a:	6105                	addi	sp,sp,32
    8000448c:	8082                	ret

000000008000448e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000448e:	7179                	addi	sp,sp,-48
    80004490:	f406                	sd	ra,40(sp)
    80004492:	f022                	sd	s0,32(sp)
    80004494:	ec26                	sd	s1,24(sp)
    80004496:	e84a                	sd	s2,16(sp)
    80004498:	e44e                	sd	s3,8(sp)
    8000449a:	1800                	addi	s0,sp,48
    8000449c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000449e:	00850913          	addi	s2,a0,8
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffc097          	auipc	ra,0xffffc
    800044a8:	790080e7          	jalr	1936(ra) # 80000c34 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ac:	409c                	lw	a5,0(s1)
    800044ae:	ef99                	bnez	a5,800044cc <holdingsleep+0x3e>
    800044b0:	4481                	li	s1,0
  release(&lk->lk);
    800044b2:	854a                	mv	a0,s2
    800044b4:	ffffd097          	auipc	ra,0xffffd
    800044b8:	834080e7          	jalr	-1996(ra) # 80000ce8 <release>
  return r;
}
    800044bc:	8526                	mv	a0,s1
    800044be:	70a2                	ld	ra,40(sp)
    800044c0:	7402                	ld	s0,32(sp)
    800044c2:	64e2                	ld	s1,24(sp)
    800044c4:	6942                	ld	s2,16(sp)
    800044c6:	69a2                	ld	s3,8(sp)
    800044c8:	6145                	addi	sp,sp,48
    800044ca:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044cc:	0284a983          	lw	s3,40(s1)
    800044d0:	ffffd097          	auipc	ra,0xffffd
    800044d4:	532080e7          	jalr	1330(ra) # 80001a02 <myproc>
    800044d8:	5d04                	lw	s1,56(a0)
    800044da:	413484b3          	sub	s1,s1,s3
    800044de:	0014b493          	seqz	s1,s1
    800044e2:	bfc1                	j	800044b2 <holdingsleep+0x24>

00000000800044e4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e4:	1141                	addi	sp,sp,-16
    800044e6:	e406                	sd	ra,8(sp)
    800044e8:	e022                	sd	s0,0(sp)
    800044ea:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044ec:	00004597          	auipc	a1,0x4
    800044f0:	25458593          	addi	a1,a1,596 # 80008740 <syscalls+0x248>
    800044f4:	0001d517          	auipc	a0,0x1d
    800044f8:	75c50513          	addi	a0,a0,1884 # 80021c50 <ftable>
    800044fc:	ffffc097          	auipc	ra,0xffffc
    80004500:	6a8080e7          	jalr	1704(ra) # 80000ba4 <initlock>
}
    80004504:	60a2                	ld	ra,8(sp)
    80004506:	6402                	ld	s0,0(sp)
    80004508:	0141                	addi	sp,sp,16
    8000450a:	8082                	ret

000000008000450c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000450c:	1101                	addi	sp,sp,-32
    8000450e:	ec06                	sd	ra,24(sp)
    80004510:	e822                	sd	s0,16(sp)
    80004512:	e426                	sd	s1,8(sp)
    80004514:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004516:	0001d517          	auipc	a0,0x1d
    8000451a:	73a50513          	addi	a0,a0,1850 # 80021c50 <ftable>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	716080e7          	jalr	1814(ra) # 80000c34 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004526:	0001d497          	auipc	s1,0x1d
    8000452a:	74248493          	addi	s1,s1,1858 # 80021c68 <ftable+0x18>
    8000452e:	0001e717          	auipc	a4,0x1e
    80004532:	6da70713          	addi	a4,a4,1754 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    80004536:	40dc                	lw	a5,4(s1)
    80004538:	cf99                	beqz	a5,80004556 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453a:	02848493          	addi	s1,s1,40
    8000453e:	fee49ce3          	bne	s1,a4,80004536 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004542:	0001d517          	auipc	a0,0x1d
    80004546:	70e50513          	addi	a0,a0,1806 # 80021c50 <ftable>
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	79e080e7          	jalr	1950(ra) # 80000ce8 <release>
  return 0;
    80004552:	4481                	li	s1,0
    80004554:	a819                	j	8000456a <filealloc+0x5e>
      f->ref = 1;
    80004556:	4785                	li	a5,1
    80004558:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000455a:	0001d517          	auipc	a0,0x1d
    8000455e:	6f650513          	addi	a0,a0,1782 # 80021c50 <ftable>
    80004562:	ffffc097          	auipc	ra,0xffffc
    80004566:	786080e7          	jalr	1926(ra) # 80000ce8 <release>
}
    8000456a:	8526                	mv	a0,s1
    8000456c:	60e2                	ld	ra,24(sp)
    8000456e:	6442                	ld	s0,16(sp)
    80004570:	64a2                	ld	s1,8(sp)
    80004572:	6105                	addi	sp,sp,32
    80004574:	8082                	ret

0000000080004576 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004576:	1101                	addi	sp,sp,-32
    80004578:	ec06                	sd	ra,24(sp)
    8000457a:	e822                	sd	s0,16(sp)
    8000457c:	e426                	sd	s1,8(sp)
    8000457e:	1000                	addi	s0,sp,32
    80004580:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004582:	0001d517          	auipc	a0,0x1d
    80004586:	6ce50513          	addi	a0,a0,1742 # 80021c50 <ftable>
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	6aa080e7          	jalr	1706(ra) # 80000c34 <acquire>
  if(f->ref < 1)
    80004592:	40dc                	lw	a5,4(s1)
    80004594:	02f05263          	blez	a5,800045b8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004598:	2785                	addiw	a5,a5,1
    8000459a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000459c:	0001d517          	auipc	a0,0x1d
    800045a0:	6b450513          	addi	a0,a0,1716 # 80021c50 <ftable>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	744080e7          	jalr	1860(ra) # 80000ce8 <release>
  return f;
}
    800045ac:	8526                	mv	a0,s1
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6105                	addi	sp,sp,32
    800045b6:	8082                	ret
    panic("filedup");
    800045b8:	00004517          	auipc	a0,0x4
    800045bc:	19050513          	addi	a0,a0,400 # 80008748 <syscalls+0x250>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	f88080e7          	jalr	-120(ra) # 80000548 <panic>

00000000800045c8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045c8:	7139                	addi	sp,sp,-64
    800045ca:	fc06                	sd	ra,56(sp)
    800045cc:	f822                	sd	s0,48(sp)
    800045ce:	f426                	sd	s1,40(sp)
    800045d0:	f04a                	sd	s2,32(sp)
    800045d2:	ec4e                	sd	s3,24(sp)
    800045d4:	e852                	sd	s4,16(sp)
    800045d6:	e456                	sd	s5,8(sp)
    800045d8:	0080                	addi	s0,sp,64
    800045da:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045dc:	0001d517          	auipc	a0,0x1d
    800045e0:	67450513          	addi	a0,a0,1652 # 80021c50 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	650080e7          	jalr	1616(ra) # 80000c34 <acquire>
  if(f->ref < 1)
    800045ec:	40dc                	lw	a5,4(s1)
    800045ee:	06f05163          	blez	a5,80004650 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045f2:	37fd                	addiw	a5,a5,-1
    800045f4:	0007871b          	sext.w	a4,a5
    800045f8:	c0dc                	sw	a5,4(s1)
    800045fa:	06e04363          	bgtz	a4,80004660 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045fe:	0004a903          	lw	s2,0(s1)
    80004602:	0094ca83          	lbu	s5,9(s1)
    80004606:	0104ba03          	ld	s4,16(s1)
    8000460a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000460e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004612:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004616:	0001d517          	auipc	a0,0x1d
    8000461a:	63a50513          	addi	a0,a0,1594 # 80021c50 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	6ca080e7          	jalr	1738(ra) # 80000ce8 <release>

  if(ff.type == FD_PIPE){
    80004626:	4785                	li	a5,1
    80004628:	04f90d63          	beq	s2,a5,80004682 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000462c:	3979                	addiw	s2,s2,-2
    8000462e:	4785                	li	a5,1
    80004630:	0527e063          	bltu	a5,s2,80004670 <fileclose+0xa8>
    begin_op();
    80004634:	00000097          	auipc	ra,0x0
    80004638:	ac2080e7          	jalr	-1342(ra) # 800040f6 <begin_op>
    iput(ff.ip);
    8000463c:	854e                	mv	a0,s3
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	2b6080e7          	jalr	694(ra) # 800038f4 <iput>
    end_op();
    80004646:	00000097          	auipc	ra,0x0
    8000464a:	b30080e7          	jalr	-1232(ra) # 80004176 <end_op>
    8000464e:	a00d                	j	80004670 <fileclose+0xa8>
    panic("fileclose");
    80004650:	00004517          	auipc	a0,0x4
    80004654:	10050513          	addi	a0,a0,256 # 80008750 <syscalls+0x258>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	ef0080e7          	jalr	-272(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004660:	0001d517          	auipc	a0,0x1d
    80004664:	5f050513          	addi	a0,a0,1520 # 80021c50 <ftable>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	680080e7          	jalr	1664(ra) # 80000ce8 <release>
  }
}
    80004670:	70e2                	ld	ra,56(sp)
    80004672:	7442                	ld	s0,48(sp)
    80004674:	74a2                	ld	s1,40(sp)
    80004676:	7902                	ld	s2,32(sp)
    80004678:	69e2                	ld	s3,24(sp)
    8000467a:	6a42                	ld	s4,16(sp)
    8000467c:	6aa2                	ld	s5,8(sp)
    8000467e:	6121                	addi	sp,sp,64
    80004680:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004682:	85d6                	mv	a1,s5
    80004684:	8552                	mv	a0,s4
    80004686:	00000097          	auipc	ra,0x0
    8000468a:	372080e7          	jalr	882(ra) # 800049f8 <pipeclose>
    8000468e:	b7cd                	j	80004670 <fileclose+0xa8>

0000000080004690 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004690:	715d                	addi	sp,sp,-80
    80004692:	e486                	sd	ra,72(sp)
    80004694:	e0a2                	sd	s0,64(sp)
    80004696:	fc26                	sd	s1,56(sp)
    80004698:	f84a                	sd	s2,48(sp)
    8000469a:	f44e                	sd	s3,40(sp)
    8000469c:	0880                	addi	s0,sp,80
    8000469e:	84aa                	mv	s1,a0
    800046a0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046a2:	ffffd097          	auipc	ra,0xffffd
    800046a6:	360080e7          	jalr	864(ra) # 80001a02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046aa:	409c                	lw	a5,0(s1)
    800046ac:	37f9                	addiw	a5,a5,-2
    800046ae:	4705                	li	a4,1
    800046b0:	04f76763          	bltu	a4,a5,800046fe <filestat+0x6e>
    800046b4:	892a                	mv	s2,a0
    ilock(f->ip);
    800046b6:	6c88                	ld	a0,24(s1)
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	082080e7          	jalr	130(ra) # 8000373a <ilock>
    stati(f->ip, &st);
    800046c0:	fb840593          	addi	a1,s0,-72
    800046c4:	6c88                	ld	a0,24(s1)
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	2fe080e7          	jalr	766(ra) # 800039c4 <stati>
    iunlock(f->ip);
    800046ce:	6c88                	ld	a0,24(s1)
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	12c080e7          	jalr	300(ra) # 800037fc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046d8:	46e1                	li	a3,24
    800046da:	fb840613          	addi	a2,s0,-72
    800046de:	85ce                	mv	a1,s3
    800046e0:	05093503          	ld	a0,80(s2)
    800046e4:	ffffd097          	auipc	ra,0xffffd
    800046e8:	012080e7          	jalr	18(ra) # 800016f6 <copyout>
    800046ec:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046f0:	60a6                	ld	ra,72(sp)
    800046f2:	6406                	ld	s0,64(sp)
    800046f4:	74e2                	ld	s1,56(sp)
    800046f6:	7942                	ld	s2,48(sp)
    800046f8:	79a2                	ld	s3,40(sp)
    800046fa:	6161                	addi	sp,sp,80
    800046fc:	8082                	ret
  return -1;
    800046fe:	557d                	li	a0,-1
    80004700:	bfc5                	j	800046f0 <filestat+0x60>

0000000080004702 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004702:	7179                	addi	sp,sp,-48
    80004704:	f406                	sd	ra,40(sp)
    80004706:	f022                	sd	s0,32(sp)
    80004708:	ec26                	sd	s1,24(sp)
    8000470a:	e84a                	sd	s2,16(sp)
    8000470c:	e44e                	sd	s3,8(sp)
    8000470e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004710:	00854783          	lbu	a5,8(a0)
    80004714:	c3d5                	beqz	a5,800047b8 <fileread+0xb6>
    80004716:	84aa                	mv	s1,a0
    80004718:	89ae                	mv	s3,a1
    8000471a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000471c:	411c                	lw	a5,0(a0)
    8000471e:	4705                	li	a4,1
    80004720:	04e78963          	beq	a5,a4,80004772 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004724:	470d                	li	a4,3
    80004726:	04e78d63          	beq	a5,a4,80004780 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000472a:	4709                	li	a4,2
    8000472c:	06e79e63          	bne	a5,a4,800047a8 <fileread+0xa6>
    ilock(f->ip);
    80004730:	6d08                	ld	a0,24(a0)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	008080e7          	jalr	8(ra) # 8000373a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000473a:	874a                	mv	a4,s2
    8000473c:	5094                	lw	a3,32(s1)
    8000473e:	864e                	mv	a2,s3
    80004740:	4585                	li	a1,1
    80004742:	6c88                	ld	a0,24(s1)
    80004744:	fffff097          	auipc	ra,0xfffff
    80004748:	2aa080e7          	jalr	682(ra) # 800039ee <readi>
    8000474c:	892a                	mv	s2,a0
    8000474e:	00a05563          	blez	a0,80004758 <fileread+0x56>
      f->off += r;
    80004752:	509c                	lw	a5,32(s1)
    80004754:	9fa9                	addw	a5,a5,a0
    80004756:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	0a2080e7          	jalr	162(ra) # 800037fc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004762:	854a                	mv	a0,s2
    80004764:	70a2                	ld	ra,40(sp)
    80004766:	7402                	ld	s0,32(sp)
    80004768:	64e2                	ld	s1,24(sp)
    8000476a:	6942                	ld	s2,16(sp)
    8000476c:	69a2                	ld	s3,8(sp)
    8000476e:	6145                	addi	sp,sp,48
    80004770:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004772:	6908                	ld	a0,16(a0)
    80004774:	00000097          	auipc	ra,0x0
    80004778:	418080e7          	jalr	1048(ra) # 80004b8c <piperead>
    8000477c:	892a                	mv	s2,a0
    8000477e:	b7d5                	j	80004762 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004780:	02451783          	lh	a5,36(a0)
    80004784:	03079693          	slli	a3,a5,0x30
    80004788:	92c1                	srli	a3,a3,0x30
    8000478a:	4725                	li	a4,9
    8000478c:	02d76863          	bltu	a4,a3,800047bc <fileread+0xba>
    80004790:	0792                	slli	a5,a5,0x4
    80004792:	0001d717          	auipc	a4,0x1d
    80004796:	41e70713          	addi	a4,a4,1054 # 80021bb0 <devsw>
    8000479a:	97ba                	add	a5,a5,a4
    8000479c:	639c                	ld	a5,0(a5)
    8000479e:	c38d                	beqz	a5,800047c0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047a0:	4505                	li	a0,1
    800047a2:	9782                	jalr	a5
    800047a4:	892a                	mv	s2,a0
    800047a6:	bf75                	j	80004762 <fileread+0x60>
    panic("fileread");
    800047a8:	00004517          	auipc	a0,0x4
    800047ac:	fb850513          	addi	a0,a0,-72 # 80008760 <syscalls+0x268>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	d98080e7          	jalr	-616(ra) # 80000548 <panic>
    return -1;
    800047b8:	597d                	li	s2,-1
    800047ba:	b765                	j	80004762 <fileread+0x60>
      return -1;
    800047bc:	597d                	li	s2,-1
    800047be:	b755                	j	80004762 <fileread+0x60>
    800047c0:	597d                	li	s2,-1
    800047c2:	b745                	j	80004762 <fileread+0x60>

00000000800047c4 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047c4:	00954783          	lbu	a5,9(a0)
    800047c8:	14078563          	beqz	a5,80004912 <filewrite+0x14e>
{
    800047cc:	715d                	addi	sp,sp,-80
    800047ce:	e486                	sd	ra,72(sp)
    800047d0:	e0a2                	sd	s0,64(sp)
    800047d2:	fc26                	sd	s1,56(sp)
    800047d4:	f84a                	sd	s2,48(sp)
    800047d6:	f44e                	sd	s3,40(sp)
    800047d8:	f052                	sd	s4,32(sp)
    800047da:	ec56                	sd	s5,24(sp)
    800047dc:	e85a                	sd	s6,16(sp)
    800047de:	e45e                	sd	s7,8(sp)
    800047e0:	e062                	sd	s8,0(sp)
    800047e2:	0880                	addi	s0,sp,80
    800047e4:	892a                	mv	s2,a0
    800047e6:	8aae                	mv	s5,a1
    800047e8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ea:	411c                	lw	a5,0(a0)
    800047ec:	4705                	li	a4,1
    800047ee:	02e78263          	beq	a5,a4,80004812 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047f2:	470d                	li	a4,3
    800047f4:	02e78563          	beq	a5,a4,8000481e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047f8:	4709                	li	a4,2
    800047fa:	10e79463          	bne	a5,a4,80004902 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047fe:	0ec05e63          	blez	a2,800048fa <filewrite+0x136>
    int i = 0;
    80004802:	4981                	li	s3,0
    80004804:	6b05                	lui	s6,0x1
    80004806:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000480a:	6b85                	lui	s7,0x1
    8000480c:	c00b8b9b          	addiw	s7,s7,-1024
    80004810:	a851                	j	800048a4 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004812:	6908                	ld	a0,16(a0)
    80004814:	00000097          	auipc	ra,0x0
    80004818:	254080e7          	jalr	596(ra) # 80004a68 <pipewrite>
    8000481c:	a85d                	j	800048d2 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000481e:	02451783          	lh	a5,36(a0)
    80004822:	03079693          	slli	a3,a5,0x30
    80004826:	92c1                	srli	a3,a3,0x30
    80004828:	4725                	li	a4,9
    8000482a:	0ed76663          	bltu	a4,a3,80004916 <filewrite+0x152>
    8000482e:	0792                	slli	a5,a5,0x4
    80004830:	0001d717          	auipc	a4,0x1d
    80004834:	38070713          	addi	a4,a4,896 # 80021bb0 <devsw>
    80004838:	97ba                	add	a5,a5,a4
    8000483a:	679c                	ld	a5,8(a5)
    8000483c:	cff9                	beqz	a5,8000491a <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000483e:	4505                	li	a0,1
    80004840:	9782                	jalr	a5
    80004842:	a841                	j	800048d2 <filewrite+0x10e>
    80004844:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8ae080e7          	jalr	-1874(ra) # 800040f6 <begin_op>
      ilock(f->ip);
    80004850:	01893503          	ld	a0,24(s2)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	ee6080e7          	jalr	-282(ra) # 8000373a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000485c:	8762                	mv	a4,s8
    8000485e:	02092683          	lw	a3,32(s2)
    80004862:	01598633          	add	a2,s3,s5
    80004866:	4585                	li	a1,1
    80004868:	01893503          	ld	a0,24(s2)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	278080e7          	jalr	632(ra) # 80003ae4 <writei>
    80004874:	84aa                	mv	s1,a0
    80004876:	02a05f63          	blez	a0,800048b4 <filewrite+0xf0>
        f->off += r;
    8000487a:	02092783          	lw	a5,32(s2)
    8000487e:	9fa9                	addw	a5,a5,a0
    80004880:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004884:	01893503          	ld	a0,24(s2)
    80004888:	fffff097          	auipc	ra,0xfffff
    8000488c:	f74080e7          	jalr	-140(ra) # 800037fc <iunlock>
      end_op();
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8e6080e7          	jalr	-1818(ra) # 80004176 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004898:	049c1963          	bne	s8,s1,800048ea <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000489c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a0:	0349d663          	bge	s3,s4,800048cc <filewrite+0x108>
      int n1 = n - i;
    800048a4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048a8:	84be                	mv	s1,a5
    800048aa:	2781                	sext.w	a5,a5
    800048ac:	f8fb5ce3          	bge	s6,a5,80004844 <filewrite+0x80>
    800048b0:	84de                	mv	s1,s7
    800048b2:	bf49                	j	80004844 <filewrite+0x80>
      iunlock(f->ip);
    800048b4:	01893503          	ld	a0,24(s2)
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	f44080e7          	jalr	-188(ra) # 800037fc <iunlock>
      end_op();
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	8b6080e7          	jalr	-1866(ra) # 80004176 <end_op>
      if(r < 0)
    800048c8:	fc04d8e3          	bgez	s1,80004898 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048cc:	8552                	mv	a0,s4
    800048ce:	033a1863          	bne	s4,s3,800048fe <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048d2:	60a6                	ld	ra,72(sp)
    800048d4:	6406                	ld	s0,64(sp)
    800048d6:	74e2                	ld	s1,56(sp)
    800048d8:	7942                	ld	s2,48(sp)
    800048da:	79a2                	ld	s3,40(sp)
    800048dc:	7a02                	ld	s4,32(sp)
    800048de:	6ae2                	ld	s5,24(sp)
    800048e0:	6b42                	ld	s6,16(sp)
    800048e2:	6ba2                	ld	s7,8(sp)
    800048e4:	6c02                	ld	s8,0(sp)
    800048e6:	6161                	addi	sp,sp,80
    800048e8:	8082                	ret
        panic("short filewrite");
    800048ea:	00004517          	auipc	a0,0x4
    800048ee:	e8650513          	addi	a0,a0,-378 # 80008770 <syscalls+0x278>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	c56080e7          	jalr	-938(ra) # 80000548 <panic>
    int i = 0;
    800048fa:	4981                	li	s3,0
    800048fc:	bfc1                	j	800048cc <filewrite+0x108>
    ret = (i == n ? n : -1);
    800048fe:	557d                	li	a0,-1
    80004900:	bfc9                	j	800048d2 <filewrite+0x10e>
    panic("filewrite");
    80004902:	00004517          	auipc	a0,0x4
    80004906:	e7e50513          	addi	a0,a0,-386 # 80008780 <syscalls+0x288>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	c3e080e7          	jalr	-962(ra) # 80000548 <panic>
    return -1;
    80004912:	557d                	li	a0,-1
}
    80004914:	8082                	ret
      return -1;
    80004916:	557d                	li	a0,-1
    80004918:	bf6d                	j	800048d2 <filewrite+0x10e>
    8000491a:	557d                	li	a0,-1
    8000491c:	bf5d                	j	800048d2 <filewrite+0x10e>

000000008000491e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000491e:	7179                	addi	sp,sp,-48
    80004920:	f406                	sd	ra,40(sp)
    80004922:	f022                	sd	s0,32(sp)
    80004924:	ec26                	sd	s1,24(sp)
    80004926:	e84a                	sd	s2,16(sp)
    80004928:	e44e                	sd	s3,8(sp)
    8000492a:	e052                	sd	s4,0(sp)
    8000492c:	1800                	addi	s0,sp,48
    8000492e:	84aa                	mv	s1,a0
    80004930:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004932:	0005b023          	sd	zero,0(a1)
    80004936:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000493a:	00000097          	auipc	ra,0x0
    8000493e:	bd2080e7          	jalr	-1070(ra) # 8000450c <filealloc>
    80004942:	e088                	sd	a0,0(s1)
    80004944:	c551                	beqz	a0,800049d0 <pipealloc+0xb2>
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	bc6080e7          	jalr	-1082(ra) # 8000450c <filealloc>
    8000494e:	00aa3023          	sd	a0,0(s4)
    80004952:	c92d                	beqz	a0,800049c4 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004954:	ffffc097          	auipc	ra,0xffffc
    80004958:	1cc080e7          	jalr	460(ra) # 80000b20 <kalloc>
    8000495c:	892a                	mv	s2,a0
    8000495e:	c125                	beqz	a0,800049be <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004960:	4985                	li	s3,1
    80004962:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004966:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000496a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000496e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004972:	00004597          	auipc	a1,0x4
    80004976:	ace58593          	addi	a1,a1,-1330 # 80008440 <states.1707+0x198>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	22a080e7          	jalr	554(ra) # 80000ba4 <initlock>
  (*f0)->type = FD_PIPE;
    80004982:	609c                	ld	a5,0(s1)
    80004984:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004988:	609c                	ld	a5,0(s1)
    8000498a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000498e:	609c                	ld	a5,0(s1)
    80004990:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004994:	609c                	ld	a5,0(s1)
    80004996:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000499a:	000a3783          	ld	a5,0(s4)
    8000499e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049a2:	000a3783          	ld	a5,0(s4)
    800049a6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049aa:	000a3783          	ld	a5,0(s4)
    800049ae:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049b2:	000a3783          	ld	a5,0(s4)
    800049b6:	0127b823          	sd	s2,16(a5)
  return 0;
    800049ba:	4501                	li	a0,0
    800049bc:	a025                	j	800049e4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049be:	6088                	ld	a0,0(s1)
    800049c0:	e501                	bnez	a0,800049c8 <pipealloc+0xaa>
    800049c2:	a039                	j	800049d0 <pipealloc+0xb2>
    800049c4:	6088                	ld	a0,0(s1)
    800049c6:	c51d                	beqz	a0,800049f4 <pipealloc+0xd6>
    fileclose(*f0);
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	c00080e7          	jalr	-1024(ra) # 800045c8 <fileclose>
  if(*f1)
    800049d0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049d4:	557d                	li	a0,-1
  if(*f1)
    800049d6:	c799                	beqz	a5,800049e4 <pipealloc+0xc6>
    fileclose(*f1);
    800049d8:	853e                	mv	a0,a5
    800049da:	00000097          	auipc	ra,0x0
    800049de:	bee080e7          	jalr	-1042(ra) # 800045c8 <fileclose>
  return -1;
    800049e2:	557d                	li	a0,-1
}
    800049e4:	70a2                	ld	ra,40(sp)
    800049e6:	7402                	ld	s0,32(sp)
    800049e8:	64e2                	ld	s1,24(sp)
    800049ea:	6942                	ld	s2,16(sp)
    800049ec:	69a2                	ld	s3,8(sp)
    800049ee:	6a02                	ld	s4,0(sp)
    800049f0:	6145                	addi	sp,sp,48
    800049f2:	8082                	ret
  return -1;
    800049f4:	557d                	li	a0,-1
    800049f6:	b7fd                	j	800049e4 <pipealloc+0xc6>

00000000800049f8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049f8:	1101                	addi	sp,sp,-32
    800049fa:	ec06                	sd	ra,24(sp)
    800049fc:	e822                	sd	s0,16(sp)
    800049fe:	e426                	sd	s1,8(sp)
    80004a00:	e04a                	sd	s2,0(sp)
    80004a02:	1000                	addi	s0,sp,32
    80004a04:	84aa                	mv	s1,a0
    80004a06:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	22c080e7          	jalr	556(ra) # 80000c34 <acquire>
  if(writable){
    80004a10:	02090d63          	beqz	s2,80004a4a <pipeclose+0x52>
    pi->writeopen = 0;
    80004a14:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a18:	21848513          	addi	a0,s1,536
    80004a1c:	ffffe097          	auipc	ra,0xffffe
    80004a20:	980080e7          	jalr	-1664(ra) # 8000239c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a24:	2204b783          	ld	a5,544(s1)
    80004a28:	eb95                	bnez	a5,80004a5c <pipeclose+0x64>
    release(&pi->lock);
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	2bc080e7          	jalr	700(ra) # 80000ce8 <release>
    kfree((char*)pi);
    80004a34:	8526                	mv	a0,s1
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	fee080e7          	jalr	-18(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a3e:	60e2                	ld	ra,24(sp)
    80004a40:	6442                	ld	s0,16(sp)
    80004a42:	64a2                	ld	s1,8(sp)
    80004a44:	6902                	ld	s2,0(sp)
    80004a46:	6105                	addi	sp,sp,32
    80004a48:	8082                	ret
    pi->readopen = 0;
    80004a4a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a4e:	21c48513          	addi	a0,s1,540
    80004a52:	ffffe097          	auipc	ra,0xffffe
    80004a56:	94a080e7          	jalr	-1718(ra) # 8000239c <wakeup>
    80004a5a:	b7e9                	j	80004a24 <pipeclose+0x2c>
    release(&pi->lock);
    80004a5c:	8526                	mv	a0,s1
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	28a080e7          	jalr	650(ra) # 80000ce8 <release>
}
    80004a66:	bfe1                	j	80004a3e <pipeclose+0x46>

0000000080004a68 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a68:	7119                	addi	sp,sp,-128
    80004a6a:	fc86                	sd	ra,120(sp)
    80004a6c:	f8a2                	sd	s0,112(sp)
    80004a6e:	f4a6                	sd	s1,104(sp)
    80004a70:	f0ca                	sd	s2,96(sp)
    80004a72:	ecce                	sd	s3,88(sp)
    80004a74:	e8d2                	sd	s4,80(sp)
    80004a76:	e4d6                	sd	s5,72(sp)
    80004a78:	e0da                	sd	s6,64(sp)
    80004a7a:	fc5e                	sd	s7,56(sp)
    80004a7c:	f862                	sd	s8,48(sp)
    80004a7e:	f466                	sd	s9,40(sp)
    80004a80:	f06a                	sd	s10,32(sp)
    80004a82:	ec6e                	sd	s11,24(sp)
    80004a84:	0100                	addi	s0,sp,128
    80004a86:	84aa                	mv	s1,a0
    80004a88:	8cae                	mv	s9,a1
    80004a8a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	f76080e7          	jalr	-138(ra) # 80001a02 <myproc>
    80004a94:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	19c080e7          	jalr	412(ra) # 80000c34 <acquire>
  for(i = 0; i < n; i++){
    80004aa0:	0d605963          	blez	s6,80004b72 <pipewrite+0x10a>
    80004aa4:	89a6                	mv	s3,s1
    80004aa6:	3b7d                	addiw	s6,s6,-1
    80004aa8:	1b02                	slli	s6,s6,0x20
    80004aaa:	020b5b13          	srli	s6,s6,0x20
    80004aae:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ab0:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ab4:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ab8:	5dfd                	li	s11,-1
    80004aba:	000b8d1b          	sext.w	s10,s7
    80004abe:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ac0:	2184a783          	lw	a5,536(s1)
    80004ac4:	21c4a703          	lw	a4,540(s1)
    80004ac8:	2007879b          	addiw	a5,a5,512
    80004acc:	02f71b63          	bne	a4,a5,80004b02 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ad0:	2204a783          	lw	a5,544(s1)
    80004ad4:	cbad                	beqz	a5,80004b46 <pipewrite+0xde>
    80004ad6:	03092783          	lw	a5,48(s2)
    80004ada:	e7b5                	bnez	a5,80004b46 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004adc:	8556                	mv	a0,s5
    80004ade:	ffffe097          	auipc	ra,0xffffe
    80004ae2:	8be080e7          	jalr	-1858(ra) # 8000239c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ae6:	85ce                	mv	a1,s3
    80004ae8:	8552                	mv	a0,s4
    80004aea:	ffffd097          	auipc	ra,0xffffd
    80004aee:	72c080e7          	jalr	1836(ra) # 80002216 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004af2:	2184a783          	lw	a5,536(s1)
    80004af6:	21c4a703          	lw	a4,540(s1)
    80004afa:	2007879b          	addiw	a5,a5,512
    80004afe:	fcf709e3          	beq	a4,a5,80004ad0 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b02:	4685                	li	a3,1
    80004b04:	019b8633          	add	a2,s7,s9
    80004b08:	f8f40593          	addi	a1,s0,-113
    80004b0c:	05093503          	ld	a0,80(s2)
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	c72080e7          	jalr	-910(ra) # 80001782 <copyin>
    80004b18:	05b50e63          	beq	a0,s11,80004b74 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b1c:	21c4a783          	lw	a5,540(s1)
    80004b20:	0017871b          	addiw	a4,a5,1
    80004b24:	20e4ae23          	sw	a4,540(s1)
    80004b28:	1ff7f793          	andi	a5,a5,511
    80004b2c:	97a6                	add	a5,a5,s1
    80004b2e:	f8f44703          	lbu	a4,-113(s0)
    80004b32:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b36:	001d0c1b          	addiw	s8,s10,1
    80004b3a:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b3e:	036b8b63          	beq	s7,s6,80004b74 <pipewrite+0x10c>
    80004b42:	8bbe                	mv	s7,a5
    80004b44:	bf9d                	j	80004aba <pipewrite+0x52>
        release(&pi->lock);
    80004b46:	8526                	mv	a0,s1
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	1a0080e7          	jalr	416(ra) # 80000ce8 <release>
        return -1;
    80004b50:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b52:	8562                	mv	a0,s8
    80004b54:	70e6                	ld	ra,120(sp)
    80004b56:	7446                	ld	s0,112(sp)
    80004b58:	74a6                	ld	s1,104(sp)
    80004b5a:	7906                	ld	s2,96(sp)
    80004b5c:	69e6                	ld	s3,88(sp)
    80004b5e:	6a46                	ld	s4,80(sp)
    80004b60:	6aa6                	ld	s5,72(sp)
    80004b62:	6b06                	ld	s6,64(sp)
    80004b64:	7be2                	ld	s7,56(sp)
    80004b66:	7c42                	ld	s8,48(sp)
    80004b68:	7ca2                	ld	s9,40(sp)
    80004b6a:	7d02                	ld	s10,32(sp)
    80004b6c:	6de2                	ld	s11,24(sp)
    80004b6e:	6109                	addi	sp,sp,128
    80004b70:	8082                	ret
  for(i = 0; i < n; i++){
    80004b72:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b74:	21848513          	addi	a0,s1,536
    80004b78:	ffffe097          	auipc	ra,0xffffe
    80004b7c:	824080e7          	jalr	-2012(ra) # 8000239c <wakeup>
  release(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	166080e7          	jalr	358(ra) # 80000ce8 <release>
  return i;
    80004b8a:	b7e1                	j	80004b52 <pipewrite+0xea>

0000000080004b8c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b8c:	715d                	addi	sp,sp,-80
    80004b8e:	e486                	sd	ra,72(sp)
    80004b90:	e0a2                	sd	s0,64(sp)
    80004b92:	fc26                	sd	s1,56(sp)
    80004b94:	f84a                	sd	s2,48(sp)
    80004b96:	f44e                	sd	s3,40(sp)
    80004b98:	f052                	sd	s4,32(sp)
    80004b9a:	ec56                	sd	s5,24(sp)
    80004b9c:	e85a                	sd	s6,16(sp)
    80004b9e:	0880                	addi	s0,sp,80
    80004ba0:	84aa                	mv	s1,a0
    80004ba2:	892e                	mv	s2,a1
    80004ba4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	e5c080e7          	jalr	-420(ra) # 80001a02 <myproc>
    80004bae:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bb0:	8b26                	mv	s6,s1
    80004bb2:	8526                	mv	a0,s1
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	080080e7          	jalr	128(ra) # 80000c34 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bbc:	2184a703          	lw	a4,536(s1)
    80004bc0:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc8:	02f71463          	bne	a4,a5,80004bf0 <piperead+0x64>
    80004bcc:	2244a783          	lw	a5,548(s1)
    80004bd0:	c385                	beqz	a5,80004bf0 <piperead+0x64>
    if(pr->killed){
    80004bd2:	030a2783          	lw	a5,48(s4)
    80004bd6:	ebc1                	bnez	a5,80004c66 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bd8:	85da                	mv	a1,s6
    80004bda:	854e                	mv	a0,s3
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	63a080e7          	jalr	1594(ra) # 80002216 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be4:	2184a703          	lw	a4,536(s1)
    80004be8:	21c4a783          	lw	a5,540(s1)
    80004bec:	fef700e3          	beq	a4,a5,80004bcc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf0:	09505263          	blez	s5,80004c74 <piperead+0xe8>
    80004bf4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf6:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bf8:	2184a783          	lw	a5,536(s1)
    80004bfc:	21c4a703          	lw	a4,540(s1)
    80004c00:	02f70d63          	beq	a4,a5,80004c3a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c04:	0017871b          	addiw	a4,a5,1
    80004c08:	20e4ac23          	sw	a4,536(s1)
    80004c0c:	1ff7f793          	andi	a5,a5,511
    80004c10:	97a6                	add	a5,a5,s1
    80004c12:	0187c783          	lbu	a5,24(a5)
    80004c16:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1a:	4685                	li	a3,1
    80004c1c:	fbf40613          	addi	a2,s0,-65
    80004c20:	85ca                	mv	a1,s2
    80004c22:	050a3503          	ld	a0,80(s4)
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	ad0080e7          	jalr	-1328(ra) # 800016f6 <copyout>
    80004c2e:	01650663          	beq	a0,s6,80004c3a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c32:	2985                	addiw	s3,s3,1
    80004c34:	0905                	addi	s2,s2,1
    80004c36:	fd3a91e3          	bne	s5,s3,80004bf8 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c3a:	21c48513          	addi	a0,s1,540
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	75e080e7          	jalr	1886(ra) # 8000239c <wakeup>
  release(&pi->lock);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	0a0080e7          	jalr	160(ra) # 80000ce8 <release>
  return i;
}
    80004c50:	854e                	mv	a0,s3
    80004c52:	60a6                	ld	ra,72(sp)
    80004c54:	6406                	ld	s0,64(sp)
    80004c56:	74e2                	ld	s1,56(sp)
    80004c58:	7942                	ld	s2,48(sp)
    80004c5a:	79a2                	ld	s3,40(sp)
    80004c5c:	7a02                	ld	s4,32(sp)
    80004c5e:	6ae2                	ld	s5,24(sp)
    80004c60:	6b42                	ld	s6,16(sp)
    80004c62:	6161                	addi	sp,sp,80
    80004c64:	8082                	ret
      release(&pi->lock);
    80004c66:	8526                	mv	a0,s1
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	080080e7          	jalr	128(ra) # 80000ce8 <release>
      return -1;
    80004c70:	59fd                	li	s3,-1
    80004c72:	bff9                	j	80004c50 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c74:	4981                	li	s3,0
    80004c76:	b7d1                	j	80004c3a <piperead+0xae>

0000000080004c78 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c78:	df010113          	addi	sp,sp,-528
    80004c7c:	20113423          	sd	ra,520(sp)
    80004c80:	20813023          	sd	s0,512(sp)
    80004c84:	ffa6                	sd	s1,504(sp)
    80004c86:	fbca                	sd	s2,496(sp)
    80004c88:	f7ce                	sd	s3,488(sp)
    80004c8a:	f3d2                	sd	s4,480(sp)
    80004c8c:	efd6                	sd	s5,472(sp)
    80004c8e:	ebda                	sd	s6,464(sp)
    80004c90:	e7de                	sd	s7,456(sp)
    80004c92:	e3e2                	sd	s8,448(sp)
    80004c94:	ff66                	sd	s9,440(sp)
    80004c96:	fb6a                	sd	s10,432(sp)
    80004c98:	f76e                	sd	s11,424(sp)
    80004c9a:	0c00                	addi	s0,sp,528
    80004c9c:	84aa                	mv	s1,a0
    80004c9e:	dea43c23          	sd	a0,-520(s0)
    80004ca2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	d5c080e7          	jalr	-676(ra) # 80001a02 <myproc>
    80004cae:	892a                	mv	s2,a0

  begin_op();
    80004cb0:	fffff097          	auipc	ra,0xfffff
    80004cb4:	446080e7          	jalr	1094(ra) # 800040f6 <begin_op>

  if((ip = namei(path)) == 0){
    80004cb8:	8526                	mv	a0,s1
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	230080e7          	jalr	560(ra) # 80003eea <namei>
    80004cc2:	c92d                	beqz	a0,80004d34 <exec+0xbc>
    80004cc4:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cc6:	fffff097          	auipc	ra,0xfffff
    80004cca:	a74080e7          	jalr	-1420(ra) # 8000373a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cce:	04000713          	li	a4,64
    80004cd2:	4681                	li	a3,0
    80004cd4:	e4840613          	addi	a2,s0,-440
    80004cd8:	4581                	li	a1,0
    80004cda:	8526                	mv	a0,s1
    80004cdc:	fffff097          	auipc	ra,0xfffff
    80004ce0:	d12080e7          	jalr	-750(ra) # 800039ee <readi>
    80004ce4:	04000793          	li	a5,64
    80004ce8:	00f51a63          	bne	a0,a5,80004cfc <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cec:	e4842703          	lw	a4,-440(s0)
    80004cf0:	464c47b7          	lui	a5,0x464c4
    80004cf4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cf8:	04f70463          	beq	a4,a5,80004d40 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	c9e080e7          	jalr	-866(ra) # 8000399c <iunlockput>
    end_op();
    80004d06:	fffff097          	auipc	ra,0xfffff
    80004d0a:	470080e7          	jalr	1136(ra) # 80004176 <end_op>
  }
  return -1;
    80004d0e:	557d                	li	a0,-1
}
    80004d10:	20813083          	ld	ra,520(sp)
    80004d14:	20013403          	ld	s0,512(sp)
    80004d18:	74fe                	ld	s1,504(sp)
    80004d1a:	795e                	ld	s2,496(sp)
    80004d1c:	79be                	ld	s3,488(sp)
    80004d1e:	7a1e                	ld	s4,480(sp)
    80004d20:	6afe                	ld	s5,472(sp)
    80004d22:	6b5e                	ld	s6,464(sp)
    80004d24:	6bbe                	ld	s7,456(sp)
    80004d26:	6c1e                	ld	s8,448(sp)
    80004d28:	7cfa                	ld	s9,440(sp)
    80004d2a:	7d5a                	ld	s10,432(sp)
    80004d2c:	7dba                	ld	s11,424(sp)
    80004d2e:	21010113          	addi	sp,sp,528
    80004d32:	8082                	ret
    end_op();
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	442080e7          	jalr	1090(ra) # 80004176 <end_op>
    return -1;
    80004d3c:	557d                	li	a0,-1
    80004d3e:	bfc9                	j	80004d10 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d40:	854a                	mv	a0,s2
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	d84080e7          	jalr	-636(ra) # 80001ac6 <proc_pagetable>
    80004d4a:	8baa                	mv	s7,a0
    80004d4c:	d945                	beqz	a0,80004cfc <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d4e:	e6842983          	lw	s3,-408(s0)
    80004d52:	e8045783          	lhu	a5,-384(s0)
    80004d56:	c7ad                	beqz	a5,80004dc0 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d58:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d5a:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d5c:	6c85                	lui	s9,0x1
    80004d5e:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d62:	def43823          	sd	a5,-528(s0)
    80004d66:	a42d                	j	80004f90 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d68:	00004517          	auipc	a0,0x4
    80004d6c:	a2850513          	addi	a0,a0,-1496 # 80008790 <syscalls+0x298>
    80004d70:	ffffb097          	auipc	ra,0xffffb
    80004d74:	7d8080e7          	jalr	2008(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d78:	8756                	mv	a4,s5
    80004d7a:	012d86bb          	addw	a3,s11,s2
    80004d7e:	4581                	li	a1,0
    80004d80:	8526                	mv	a0,s1
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	c6c080e7          	jalr	-916(ra) # 800039ee <readi>
    80004d8a:	2501                	sext.w	a0,a0
    80004d8c:	1aaa9963          	bne	s5,a0,80004f3e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d90:	6785                	lui	a5,0x1
    80004d92:	0127893b          	addw	s2,a5,s2
    80004d96:	77fd                	lui	a5,0xfffff
    80004d98:	01478a3b          	addw	s4,a5,s4
    80004d9c:	1f897163          	bgeu	s2,s8,80004f7e <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004da0:	02091593          	slli	a1,s2,0x20
    80004da4:	9181                	srli	a1,a1,0x20
    80004da6:	95ea                	add	a1,a1,s10
    80004da8:	855e                	mv	a0,s7
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	318080e7          	jalr	792(ra) # 800010c2 <walkaddr>
    80004db2:	862a                	mv	a2,a0
    if(pa == 0)
    80004db4:	d955                	beqz	a0,80004d68 <exec+0xf0>
      n = PGSIZE;
    80004db6:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004db8:	fd9a70e3          	bgeu	s4,s9,80004d78 <exec+0x100>
      n = sz - i;
    80004dbc:	8ad2                	mv	s5,s4
    80004dbe:	bf6d                	j	80004d78 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dc0:	4901                	li	s2,0
  iunlockput(ip);
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	bd8080e7          	jalr	-1064(ra) # 8000399c <iunlockput>
  end_op();
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	3aa080e7          	jalr	938(ra) # 80004176 <end_op>
  p = myproc();
    80004dd4:	ffffd097          	auipc	ra,0xffffd
    80004dd8:	c2e080e7          	jalr	-978(ra) # 80001a02 <myproc>
    80004ddc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dde:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004de2:	6785                	lui	a5,0x1
    80004de4:	17fd                	addi	a5,a5,-1
    80004de6:	993e                	add	s2,s2,a5
    80004de8:	757d                	lui	a0,0xfffff
    80004dea:	00a977b3          	and	a5,s2,a0
    80004dee:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df2:	6609                	lui	a2,0x2
    80004df4:	963e                	add	a2,a2,a5
    80004df6:	85be                	mv	a1,a5
    80004df8:	855e                	mv	a0,s7
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	6ac080e7          	jalr	1708(ra) # 800014a6 <uvmalloc>
    80004e02:	8b2a                	mv	s6,a0
  ip = 0;
    80004e04:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e06:	12050c63          	beqz	a0,80004f3e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e0a:	75f9                	lui	a1,0xffffe
    80004e0c:	95aa                	add	a1,a1,a0
    80004e0e:	855e                	mv	a0,s7
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	8b4080e7          	jalr	-1868(ra) # 800016c4 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e18:	7c7d                	lui	s8,0xfffff
    80004e1a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e1c:	e0043783          	ld	a5,-512(s0)
    80004e20:	6388                	ld	a0,0(a5)
    80004e22:	c535                	beqz	a0,80004e8e <exec+0x216>
    80004e24:	e8840993          	addi	s3,s0,-376
    80004e28:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e2c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e2e:	ffffc097          	auipc	ra,0xffffc
    80004e32:	08a080e7          	jalr	138(ra) # 80000eb8 <strlen>
    80004e36:	2505                	addiw	a0,a0,1
    80004e38:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e3c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e40:	13896363          	bltu	s2,s8,80004f66 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e44:	e0043d83          	ld	s11,-512(s0)
    80004e48:	000dba03          	ld	s4,0(s11)
    80004e4c:	8552                	mv	a0,s4
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	06a080e7          	jalr	106(ra) # 80000eb8 <strlen>
    80004e56:	0015069b          	addiw	a3,a0,1
    80004e5a:	8652                	mv	a2,s4
    80004e5c:	85ca                	mv	a1,s2
    80004e5e:	855e                	mv	a0,s7
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	896080e7          	jalr	-1898(ra) # 800016f6 <copyout>
    80004e68:	10054363          	bltz	a0,80004f6e <exec+0x2f6>
    ustack[argc] = sp;
    80004e6c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e70:	0485                	addi	s1,s1,1
    80004e72:	008d8793          	addi	a5,s11,8
    80004e76:	e0f43023          	sd	a5,-512(s0)
    80004e7a:	008db503          	ld	a0,8(s11)
    80004e7e:	c911                	beqz	a0,80004e92 <exec+0x21a>
    if(argc >= MAXARG)
    80004e80:	09a1                	addi	s3,s3,8
    80004e82:	fb3c96e3          	bne	s9,s3,80004e2e <exec+0x1b6>
  sz = sz1;
    80004e86:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e8a:	4481                	li	s1,0
    80004e8c:	a84d                	j	80004f3e <exec+0x2c6>
  sp = sz;
    80004e8e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e90:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e92:	00349793          	slli	a5,s1,0x3
    80004e96:	f9040713          	addi	a4,s0,-112
    80004e9a:	97ba                	add	a5,a5,a4
    80004e9c:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ea0:	00148693          	addi	a3,s1,1
    80004ea4:	068e                	slli	a3,a3,0x3
    80004ea6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eaa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eae:	01897663          	bgeu	s2,s8,80004eba <exec+0x242>
  sz = sz1;
    80004eb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eb6:	4481                	li	s1,0
    80004eb8:	a059                	j	80004f3e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004eba:	e8840613          	addi	a2,s0,-376
    80004ebe:	85ca                	mv	a1,s2
    80004ec0:	855e                	mv	a0,s7
    80004ec2:	ffffd097          	auipc	ra,0xffffd
    80004ec6:	834080e7          	jalr	-1996(ra) # 800016f6 <copyout>
    80004eca:	0a054663          	bltz	a0,80004f76 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ece:	058ab783          	ld	a5,88(s5)
    80004ed2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ed6:	df843783          	ld	a5,-520(s0)
    80004eda:	0007c703          	lbu	a4,0(a5)
    80004ede:	cf11                	beqz	a4,80004efa <exec+0x282>
    80004ee0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ee2:	02f00693          	li	a3,47
    80004ee6:	a029                	j	80004ef0 <exec+0x278>
  for(last=s=path; *s; s++)
    80004ee8:	0785                	addi	a5,a5,1
    80004eea:	fff7c703          	lbu	a4,-1(a5)
    80004eee:	c711                	beqz	a4,80004efa <exec+0x282>
    if(*s == '/')
    80004ef0:	fed71ce3          	bne	a4,a3,80004ee8 <exec+0x270>
      last = s+1;
    80004ef4:	def43c23          	sd	a5,-520(s0)
    80004ef8:	bfc5                	j	80004ee8 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004efa:	4641                	li	a2,16
    80004efc:	df843583          	ld	a1,-520(s0)
    80004f00:	158a8513          	addi	a0,s5,344
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	f82080e7          	jalr	-126(ra) # 80000e86 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f0c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f10:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f14:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f18:	058ab783          	ld	a5,88(s5)
    80004f1c:	e6043703          	ld	a4,-416(s0)
    80004f20:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f22:	058ab783          	ld	a5,88(s5)
    80004f26:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f2a:	85ea                	mv	a1,s10
    80004f2c:	ffffd097          	auipc	ra,0xffffd
    80004f30:	c36080e7          	jalr	-970(ra) # 80001b62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f34:	0004851b          	sext.w	a0,s1
    80004f38:	bbe1                	j	80004d10 <exec+0x98>
    80004f3a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f3e:	e0843583          	ld	a1,-504(s0)
    80004f42:	855e                	mv	a0,s7
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	c1e080e7          	jalr	-994(ra) # 80001b62 <proc_freepagetable>
  if(ip){
    80004f4c:	da0498e3          	bnez	s1,80004cfc <exec+0x84>
  return -1;
    80004f50:	557d                	li	a0,-1
    80004f52:	bb7d                	j	80004d10 <exec+0x98>
    80004f54:	e1243423          	sd	s2,-504(s0)
    80004f58:	b7dd                	j	80004f3e <exec+0x2c6>
    80004f5a:	e1243423          	sd	s2,-504(s0)
    80004f5e:	b7c5                	j	80004f3e <exec+0x2c6>
    80004f60:	e1243423          	sd	s2,-504(s0)
    80004f64:	bfe9                	j	80004f3e <exec+0x2c6>
  sz = sz1;
    80004f66:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f6a:	4481                	li	s1,0
    80004f6c:	bfc9                	j	80004f3e <exec+0x2c6>
  sz = sz1;
    80004f6e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f72:	4481                	li	s1,0
    80004f74:	b7e9                	j	80004f3e <exec+0x2c6>
  sz = sz1;
    80004f76:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f7a:	4481                	li	s1,0
    80004f7c:	b7c9                	j	80004f3e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f7e:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f82:	2b05                	addiw	s6,s6,1
    80004f84:	0389899b          	addiw	s3,s3,56
    80004f88:	e8045783          	lhu	a5,-384(s0)
    80004f8c:	e2fb5be3          	bge	s6,a5,80004dc2 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f90:	2981                	sext.w	s3,s3
    80004f92:	03800713          	li	a4,56
    80004f96:	86ce                	mv	a3,s3
    80004f98:	e1040613          	addi	a2,s0,-496
    80004f9c:	4581                	li	a1,0
    80004f9e:	8526                	mv	a0,s1
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	a4e080e7          	jalr	-1458(ra) # 800039ee <readi>
    80004fa8:	03800793          	li	a5,56
    80004fac:	f8f517e3          	bne	a0,a5,80004f3a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fb0:	e1042783          	lw	a5,-496(s0)
    80004fb4:	4705                	li	a4,1
    80004fb6:	fce796e3          	bne	a5,a4,80004f82 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fba:	e3843603          	ld	a2,-456(s0)
    80004fbe:	e3043783          	ld	a5,-464(s0)
    80004fc2:	f8f669e3          	bltu	a2,a5,80004f54 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fc6:	e2043783          	ld	a5,-480(s0)
    80004fca:	963e                	add	a2,a2,a5
    80004fcc:	f8f667e3          	bltu	a2,a5,80004f5a <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd0:	85ca                	mv	a1,s2
    80004fd2:	855e                	mv	a0,s7
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	4d2080e7          	jalr	1234(ra) # 800014a6 <uvmalloc>
    80004fdc:	e0a43423          	sd	a0,-504(s0)
    80004fe0:	d141                	beqz	a0,80004f60 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004fe2:	e2043d03          	ld	s10,-480(s0)
    80004fe6:	df043783          	ld	a5,-528(s0)
    80004fea:	00fd77b3          	and	a5,s10,a5
    80004fee:	fba1                	bnez	a5,80004f3e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ff0:	e1842d83          	lw	s11,-488(s0)
    80004ff4:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ff8:	f80c03e3          	beqz	s8,80004f7e <exec+0x306>
    80004ffc:	8a62                	mv	s4,s8
    80004ffe:	4901                	li	s2,0
    80005000:	b345                	j	80004da0 <exec+0x128>

0000000080005002 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005002:	7179                	addi	sp,sp,-48
    80005004:	f406                	sd	ra,40(sp)
    80005006:	f022                	sd	s0,32(sp)
    80005008:	ec26                	sd	s1,24(sp)
    8000500a:	e84a                	sd	s2,16(sp)
    8000500c:	1800                	addi	s0,sp,48
    8000500e:	892e                	mv	s2,a1
    80005010:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005012:	fdc40593          	addi	a1,s0,-36
    80005016:	ffffe097          	auipc	ra,0xffffe
    8000501a:	ade080e7          	jalr	-1314(ra) # 80002af4 <argint>
    8000501e:	04054063          	bltz	a0,8000505e <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005022:	fdc42703          	lw	a4,-36(s0)
    80005026:	47bd                	li	a5,15
    80005028:	02e7ed63          	bltu	a5,a4,80005062 <argfd+0x60>
    8000502c:	ffffd097          	auipc	ra,0xffffd
    80005030:	9d6080e7          	jalr	-1578(ra) # 80001a02 <myproc>
    80005034:	fdc42703          	lw	a4,-36(s0)
    80005038:	01a70793          	addi	a5,a4,26
    8000503c:	078e                	slli	a5,a5,0x3
    8000503e:	953e                	add	a0,a0,a5
    80005040:	611c                	ld	a5,0(a0)
    80005042:	c395                	beqz	a5,80005066 <argfd+0x64>
    return -1;
  if(pfd)
    80005044:	00090463          	beqz	s2,8000504c <argfd+0x4a>
    *pfd = fd;
    80005048:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000504c:	4501                	li	a0,0
  if(pf)
    8000504e:	c091                	beqz	s1,80005052 <argfd+0x50>
    *pf = f;
    80005050:	e09c                	sd	a5,0(s1)
}
    80005052:	70a2                	ld	ra,40(sp)
    80005054:	7402                	ld	s0,32(sp)
    80005056:	64e2                	ld	s1,24(sp)
    80005058:	6942                	ld	s2,16(sp)
    8000505a:	6145                	addi	sp,sp,48
    8000505c:	8082                	ret
    return -1;
    8000505e:	557d                	li	a0,-1
    80005060:	bfcd                	j	80005052 <argfd+0x50>
    return -1;
    80005062:	557d                	li	a0,-1
    80005064:	b7fd                	j	80005052 <argfd+0x50>
    80005066:	557d                	li	a0,-1
    80005068:	b7ed                	j	80005052 <argfd+0x50>

000000008000506a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000506a:	1101                	addi	sp,sp,-32
    8000506c:	ec06                	sd	ra,24(sp)
    8000506e:	e822                	sd	s0,16(sp)
    80005070:	e426                	sd	s1,8(sp)
    80005072:	1000                	addi	s0,sp,32
    80005074:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	98c080e7          	jalr	-1652(ra) # 80001a02 <myproc>
    8000507e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005080:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005084:	4501                	li	a0,0
    80005086:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005088:	6398                	ld	a4,0(a5)
    8000508a:	cb19                	beqz	a4,800050a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000508c:	2505                	addiw	a0,a0,1
    8000508e:	07a1                	addi	a5,a5,8
    80005090:	fed51ce3          	bne	a0,a3,80005088 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005094:	557d                	li	a0,-1
}
    80005096:	60e2                	ld	ra,24(sp)
    80005098:	6442                	ld	s0,16(sp)
    8000509a:	64a2                	ld	s1,8(sp)
    8000509c:	6105                	addi	sp,sp,32
    8000509e:	8082                	ret
      p->ofile[fd] = f;
    800050a0:	01a50793          	addi	a5,a0,26
    800050a4:	078e                	slli	a5,a5,0x3
    800050a6:	963e                	add	a2,a2,a5
    800050a8:	e204                	sd	s1,0(a2)
      return fd;
    800050aa:	b7f5                	j	80005096 <fdalloc+0x2c>

00000000800050ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ac:	715d                	addi	sp,sp,-80
    800050ae:	e486                	sd	ra,72(sp)
    800050b0:	e0a2                	sd	s0,64(sp)
    800050b2:	fc26                	sd	s1,56(sp)
    800050b4:	f84a                	sd	s2,48(sp)
    800050b6:	f44e                	sd	s3,40(sp)
    800050b8:	f052                	sd	s4,32(sp)
    800050ba:	ec56                	sd	s5,24(sp)
    800050bc:	0880                	addi	s0,sp,80
    800050be:	89ae                	mv	s3,a1
    800050c0:	8ab2                	mv	s5,a2
    800050c2:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050c4:	fb040593          	addi	a1,s0,-80
    800050c8:	fffff097          	auipc	ra,0xfffff
    800050cc:	e40080e7          	jalr	-448(ra) # 80003f08 <nameiparent>
    800050d0:	892a                	mv	s2,a0
    800050d2:	12050f63          	beqz	a0,80005210 <create+0x164>
    return 0;

  ilock(dp);
    800050d6:	ffffe097          	auipc	ra,0xffffe
    800050da:	664080e7          	jalr	1636(ra) # 8000373a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050de:	4601                	li	a2,0
    800050e0:	fb040593          	addi	a1,s0,-80
    800050e4:	854a                	mv	a0,s2
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	b32080e7          	jalr	-1230(ra) # 80003c18 <dirlookup>
    800050ee:	84aa                	mv	s1,a0
    800050f0:	c921                	beqz	a0,80005140 <create+0x94>
    iunlockput(dp);
    800050f2:	854a                	mv	a0,s2
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	8a8080e7          	jalr	-1880(ra) # 8000399c <iunlockput>
    ilock(ip);
    800050fc:	8526                	mv	a0,s1
    800050fe:	ffffe097          	auipc	ra,0xffffe
    80005102:	63c080e7          	jalr	1596(ra) # 8000373a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005106:	2981                	sext.w	s3,s3
    80005108:	4789                	li	a5,2
    8000510a:	02f99463          	bne	s3,a5,80005132 <create+0x86>
    8000510e:	0444d783          	lhu	a5,68(s1)
    80005112:	37f9                	addiw	a5,a5,-2
    80005114:	17c2                	slli	a5,a5,0x30
    80005116:	93c1                	srli	a5,a5,0x30
    80005118:	4705                	li	a4,1
    8000511a:	00f76c63          	bltu	a4,a5,80005132 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000511e:	8526                	mv	a0,s1
    80005120:	60a6                	ld	ra,72(sp)
    80005122:	6406                	ld	s0,64(sp)
    80005124:	74e2                	ld	s1,56(sp)
    80005126:	7942                	ld	s2,48(sp)
    80005128:	79a2                	ld	s3,40(sp)
    8000512a:	7a02                	ld	s4,32(sp)
    8000512c:	6ae2                	ld	s5,24(sp)
    8000512e:	6161                	addi	sp,sp,80
    80005130:	8082                	ret
    iunlockput(ip);
    80005132:	8526                	mv	a0,s1
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	868080e7          	jalr	-1944(ra) # 8000399c <iunlockput>
    return 0;
    8000513c:	4481                	li	s1,0
    8000513e:	b7c5                	j	8000511e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005140:	85ce                	mv	a1,s3
    80005142:	00092503          	lw	a0,0(s2)
    80005146:	ffffe097          	auipc	ra,0xffffe
    8000514a:	45c080e7          	jalr	1116(ra) # 800035a2 <ialloc>
    8000514e:	84aa                	mv	s1,a0
    80005150:	c529                	beqz	a0,8000519a <create+0xee>
  ilock(ip);
    80005152:	ffffe097          	auipc	ra,0xffffe
    80005156:	5e8080e7          	jalr	1512(ra) # 8000373a <ilock>
  ip->major = major;
    8000515a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000515e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005162:	4785                	li	a5,1
    80005164:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005168:	8526                	mv	a0,s1
    8000516a:	ffffe097          	auipc	ra,0xffffe
    8000516e:	506080e7          	jalr	1286(ra) # 80003670 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005172:	2981                	sext.w	s3,s3
    80005174:	4785                	li	a5,1
    80005176:	02f98a63          	beq	s3,a5,800051aa <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000517a:	40d0                	lw	a2,4(s1)
    8000517c:	fb040593          	addi	a1,s0,-80
    80005180:	854a                	mv	a0,s2
    80005182:	fffff097          	auipc	ra,0xfffff
    80005186:	ca6080e7          	jalr	-858(ra) # 80003e28 <dirlink>
    8000518a:	06054b63          	bltz	a0,80005200 <create+0x154>
  iunlockput(dp);
    8000518e:	854a                	mv	a0,s2
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	80c080e7          	jalr	-2036(ra) # 8000399c <iunlockput>
  return ip;
    80005198:	b759                	j	8000511e <create+0x72>
    panic("create: ialloc");
    8000519a:	00003517          	auipc	a0,0x3
    8000519e:	61650513          	addi	a0,a0,1558 # 800087b0 <syscalls+0x2b8>
    800051a2:	ffffb097          	auipc	ra,0xffffb
    800051a6:	3a6080e7          	jalr	934(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051aa:	04a95783          	lhu	a5,74(s2)
    800051ae:	2785                	addiw	a5,a5,1
    800051b0:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051b4:	854a                	mv	a0,s2
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	4ba080e7          	jalr	1210(ra) # 80003670 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051be:	40d0                	lw	a2,4(s1)
    800051c0:	00003597          	auipc	a1,0x3
    800051c4:	60058593          	addi	a1,a1,1536 # 800087c0 <syscalls+0x2c8>
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	c5e080e7          	jalr	-930(ra) # 80003e28 <dirlink>
    800051d2:	00054f63          	bltz	a0,800051f0 <create+0x144>
    800051d6:	00492603          	lw	a2,4(s2)
    800051da:	00003597          	auipc	a1,0x3
    800051de:	5ee58593          	addi	a1,a1,1518 # 800087c8 <syscalls+0x2d0>
    800051e2:	8526                	mv	a0,s1
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	c44080e7          	jalr	-956(ra) # 80003e28 <dirlink>
    800051ec:	f80557e3          	bgez	a0,8000517a <create+0xce>
      panic("create dots");
    800051f0:	00003517          	auipc	a0,0x3
    800051f4:	5e050513          	addi	a0,a0,1504 # 800087d0 <syscalls+0x2d8>
    800051f8:	ffffb097          	auipc	ra,0xffffb
    800051fc:	350080e7          	jalr	848(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005200:	00003517          	auipc	a0,0x3
    80005204:	5e050513          	addi	a0,a0,1504 # 800087e0 <syscalls+0x2e8>
    80005208:	ffffb097          	auipc	ra,0xffffb
    8000520c:	340080e7          	jalr	832(ra) # 80000548 <panic>
    return 0;
    80005210:	84aa                	mv	s1,a0
    80005212:	b731                	j	8000511e <create+0x72>

0000000080005214 <sys_dup>:
{
    80005214:	7179                	addi	sp,sp,-48
    80005216:	f406                	sd	ra,40(sp)
    80005218:	f022                	sd	s0,32(sp)
    8000521a:	ec26                	sd	s1,24(sp)
    8000521c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000521e:	fd840613          	addi	a2,s0,-40
    80005222:	4581                	li	a1,0
    80005224:	4501                	li	a0,0
    80005226:	00000097          	auipc	ra,0x0
    8000522a:	ddc080e7          	jalr	-548(ra) # 80005002 <argfd>
    return -1;
    8000522e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005230:	02054363          	bltz	a0,80005256 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005234:	fd843503          	ld	a0,-40(s0)
    80005238:	00000097          	auipc	ra,0x0
    8000523c:	e32080e7          	jalr	-462(ra) # 8000506a <fdalloc>
    80005240:	84aa                	mv	s1,a0
    return -1;
    80005242:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005244:	00054963          	bltz	a0,80005256 <sys_dup+0x42>
  filedup(f);
    80005248:	fd843503          	ld	a0,-40(s0)
    8000524c:	fffff097          	auipc	ra,0xfffff
    80005250:	32a080e7          	jalr	810(ra) # 80004576 <filedup>
  return fd;
    80005254:	87a6                	mv	a5,s1
}
    80005256:	853e                	mv	a0,a5
    80005258:	70a2                	ld	ra,40(sp)
    8000525a:	7402                	ld	s0,32(sp)
    8000525c:	64e2                	ld	s1,24(sp)
    8000525e:	6145                	addi	sp,sp,48
    80005260:	8082                	ret

0000000080005262 <sys_read>:
{
    80005262:	7179                	addi	sp,sp,-48
    80005264:	f406                	sd	ra,40(sp)
    80005266:	f022                	sd	s0,32(sp)
    80005268:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526a:	fe840613          	addi	a2,s0,-24
    8000526e:	4581                	li	a1,0
    80005270:	4501                	li	a0,0
    80005272:	00000097          	auipc	ra,0x0
    80005276:	d90080e7          	jalr	-624(ra) # 80005002 <argfd>
    return -1;
    8000527a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527c:	04054163          	bltz	a0,800052be <sys_read+0x5c>
    80005280:	fe440593          	addi	a1,s0,-28
    80005284:	4509                	li	a0,2
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	86e080e7          	jalr	-1938(ra) # 80002af4 <argint>
    return -1;
    8000528e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005290:	02054763          	bltz	a0,800052be <sys_read+0x5c>
    80005294:	fd840593          	addi	a1,s0,-40
    80005298:	4505                	li	a0,1
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	87c080e7          	jalr	-1924(ra) # 80002b16 <argaddr>
    return -1;
    800052a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a4:	00054d63          	bltz	a0,800052be <sys_read+0x5c>
  return fileread(f, p, n);
    800052a8:	fe442603          	lw	a2,-28(s0)
    800052ac:	fd843583          	ld	a1,-40(s0)
    800052b0:	fe843503          	ld	a0,-24(s0)
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	44e080e7          	jalr	1102(ra) # 80004702 <fileread>
    800052bc:	87aa                	mv	a5,a0
}
    800052be:	853e                	mv	a0,a5
    800052c0:	70a2                	ld	ra,40(sp)
    800052c2:	7402                	ld	s0,32(sp)
    800052c4:	6145                	addi	sp,sp,48
    800052c6:	8082                	ret

00000000800052c8 <sys_write>:
{
    800052c8:	7179                	addi	sp,sp,-48
    800052ca:	f406                	sd	ra,40(sp)
    800052cc:	f022                	sd	s0,32(sp)
    800052ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d0:	fe840613          	addi	a2,s0,-24
    800052d4:	4581                	li	a1,0
    800052d6:	4501                	li	a0,0
    800052d8:	00000097          	auipc	ra,0x0
    800052dc:	d2a080e7          	jalr	-726(ra) # 80005002 <argfd>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e2:	04054163          	bltz	a0,80005324 <sys_write+0x5c>
    800052e6:	fe440593          	addi	a1,s0,-28
    800052ea:	4509                	li	a0,2
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	808080e7          	jalr	-2040(ra) # 80002af4 <argint>
    return -1;
    800052f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f6:	02054763          	bltz	a0,80005324 <sys_write+0x5c>
    800052fa:	fd840593          	addi	a1,s0,-40
    800052fe:	4505                	li	a0,1
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	816080e7          	jalr	-2026(ra) # 80002b16 <argaddr>
    return -1;
    80005308:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530a:	00054d63          	bltz	a0,80005324 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000530e:	fe442603          	lw	a2,-28(s0)
    80005312:	fd843583          	ld	a1,-40(s0)
    80005316:	fe843503          	ld	a0,-24(s0)
    8000531a:	fffff097          	auipc	ra,0xfffff
    8000531e:	4aa080e7          	jalr	1194(ra) # 800047c4 <filewrite>
    80005322:	87aa                	mv	a5,a0
}
    80005324:	853e                	mv	a0,a5
    80005326:	70a2                	ld	ra,40(sp)
    80005328:	7402                	ld	s0,32(sp)
    8000532a:	6145                	addi	sp,sp,48
    8000532c:	8082                	ret

000000008000532e <sys_close>:
{
    8000532e:	1101                	addi	sp,sp,-32
    80005330:	ec06                	sd	ra,24(sp)
    80005332:	e822                	sd	s0,16(sp)
    80005334:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005336:	fe040613          	addi	a2,s0,-32
    8000533a:	fec40593          	addi	a1,s0,-20
    8000533e:	4501                	li	a0,0
    80005340:	00000097          	auipc	ra,0x0
    80005344:	cc2080e7          	jalr	-830(ra) # 80005002 <argfd>
    return -1;
    80005348:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000534a:	02054463          	bltz	a0,80005372 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000534e:	ffffc097          	auipc	ra,0xffffc
    80005352:	6b4080e7          	jalr	1716(ra) # 80001a02 <myproc>
    80005356:	fec42783          	lw	a5,-20(s0)
    8000535a:	07e9                	addi	a5,a5,26
    8000535c:	078e                	slli	a5,a5,0x3
    8000535e:	97aa                	add	a5,a5,a0
    80005360:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005364:	fe043503          	ld	a0,-32(s0)
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	260080e7          	jalr	608(ra) # 800045c8 <fileclose>
  return 0;
    80005370:	4781                	li	a5,0
}
    80005372:	853e                	mv	a0,a5
    80005374:	60e2                	ld	ra,24(sp)
    80005376:	6442                	ld	s0,16(sp)
    80005378:	6105                	addi	sp,sp,32
    8000537a:	8082                	ret

000000008000537c <sys_fstat>:
{
    8000537c:	1101                	addi	sp,sp,-32
    8000537e:	ec06                	sd	ra,24(sp)
    80005380:	e822                	sd	s0,16(sp)
    80005382:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005384:	fe840613          	addi	a2,s0,-24
    80005388:	4581                	li	a1,0
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	c76080e7          	jalr	-906(ra) # 80005002 <argfd>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005396:	02054563          	bltz	a0,800053c0 <sys_fstat+0x44>
    8000539a:	fe040593          	addi	a1,s0,-32
    8000539e:	4505                	li	a0,1
    800053a0:	ffffd097          	auipc	ra,0xffffd
    800053a4:	776080e7          	jalr	1910(ra) # 80002b16 <argaddr>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053aa:	00054b63          	bltz	a0,800053c0 <sys_fstat+0x44>
  return filestat(f, st);
    800053ae:	fe043583          	ld	a1,-32(s0)
    800053b2:	fe843503          	ld	a0,-24(s0)
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	2da080e7          	jalr	730(ra) # 80004690 <filestat>
    800053be:	87aa                	mv	a5,a0
}
    800053c0:	853e                	mv	a0,a5
    800053c2:	60e2                	ld	ra,24(sp)
    800053c4:	6442                	ld	s0,16(sp)
    800053c6:	6105                	addi	sp,sp,32
    800053c8:	8082                	ret

00000000800053ca <sys_link>:
{
    800053ca:	7169                	addi	sp,sp,-304
    800053cc:	f606                	sd	ra,296(sp)
    800053ce:	f222                	sd	s0,288(sp)
    800053d0:	ee26                	sd	s1,280(sp)
    800053d2:	ea4a                	sd	s2,272(sp)
    800053d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d6:	08000613          	li	a2,128
    800053da:	ed040593          	addi	a1,s0,-304
    800053de:	4501                	li	a0,0
    800053e0:	ffffd097          	auipc	ra,0xffffd
    800053e4:	758080e7          	jalr	1880(ra) # 80002b38 <argstr>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ea:	10054e63          	bltz	a0,80005506 <sys_link+0x13c>
    800053ee:	08000613          	li	a2,128
    800053f2:	f5040593          	addi	a1,s0,-176
    800053f6:	4505                	li	a0,1
    800053f8:	ffffd097          	auipc	ra,0xffffd
    800053fc:	740080e7          	jalr	1856(ra) # 80002b38 <argstr>
    return -1;
    80005400:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005402:	10054263          	bltz	a0,80005506 <sys_link+0x13c>
  begin_op();
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	cf0080e7          	jalr	-784(ra) # 800040f6 <begin_op>
  if((ip = namei(old)) == 0){
    8000540e:	ed040513          	addi	a0,s0,-304
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	ad8080e7          	jalr	-1320(ra) # 80003eea <namei>
    8000541a:	84aa                	mv	s1,a0
    8000541c:	c551                	beqz	a0,800054a8 <sys_link+0xde>
  ilock(ip);
    8000541e:	ffffe097          	auipc	ra,0xffffe
    80005422:	31c080e7          	jalr	796(ra) # 8000373a <ilock>
  if(ip->type == T_DIR){
    80005426:	04449703          	lh	a4,68(s1)
    8000542a:	4785                	li	a5,1
    8000542c:	08f70463          	beq	a4,a5,800054b4 <sys_link+0xea>
  ip->nlink++;
    80005430:	04a4d783          	lhu	a5,74(s1)
    80005434:	2785                	addiw	a5,a5,1
    80005436:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543a:	8526                	mv	a0,s1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	234080e7          	jalr	564(ra) # 80003670 <iupdate>
  iunlock(ip);
    80005444:	8526                	mv	a0,s1
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	3b6080e7          	jalr	950(ra) # 800037fc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000544e:	fd040593          	addi	a1,s0,-48
    80005452:	f5040513          	addi	a0,s0,-176
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	ab2080e7          	jalr	-1358(ra) # 80003f08 <nameiparent>
    8000545e:	892a                	mv	s2,a0
    80005460:	c935                	beqz	a0,800054d4 <sys_link+0x10a>
  ilock(dp);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	2d8080e7          	jalr	728(ra) # 8000373a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000546a:	00092703          	lw	a4,0(s2)
    8000546e:	409c                	lw	a5,0(s1)
    80005470:	04f71d63          	bne	a4,a5,800054ca <sys_link+0x100>
    80005474:	40d0                	lw	a2,4(s1)
    80005476:	fd040593          	addi	a1,s0,-48
    8000547a:	854a                	mv	a0,s2
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	9ac080e7          	jalr	-1620(ra) # 80003e28 <dirlink>
    80005484:	04054363          	bltz	a0,800054ca <sys_link+0x100>
  iunlockput(dp);
    80005488:	854a                	mv	a0,s2
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	512080e7          	jalr	1298(ra) # 8000399c <iunlockput>
  iput(ip);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	460080e7          	jalr	1120(ra) # 800038f4 <iput>
  end_op();
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	cda080e7          	jalr	-806(ra) # 80004176 <end_op>
  return 0;
    800054a4:	4781                	li	a5,0
    800054a6:	a085                	j	80005506 <sys_link+0x13c>
    end_op();
    800054a8:	fffff097          	auipc	ra,0xfffff
    800054ac:	cce080e7          	jalr	-818(ra) # 80004176 <end_op>
    return -1;
    800054b0:	57fd                	li	a5,-1
    800054b2:	a891                	j	80005506 <sys_link+0x13c>
    iunlockput(ip);
    800054b4:	8526                	mv	a0,s1
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	4e6080e7          	jalr	1254(ra) # 8000399c <iunlockput>
    end_op();
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	cb8080e7          	jalr	-840(ra) # 80004176 <end_op>
    return -1;
    800054c6:	57fd                	li	a5,-1
    800054c8:	a83d                	j	80005506 <sys_link+0x13c>
    iunlockput(dp);
    800054ca:	854a                	mv	a0,s2
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	4d0080e7          	jalr	1232(ra) # 8000399c <iunlockput>
  ilock(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	264080e7          	jalr	612(ra) # 8000373a <ilock>
  ip->nlink--;
    800054de:	04a4d783          	lhu	a5,74(s1)
    800054e2:	37fd                	addiw	a5,a5,-1
    800054e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	186080e7          	jalr	390(ra) # 80003670 <iupdate>
  iunlockput(ip);
    800054f2:	8526                	mv	a0,s1
    800054f4:	ffffe097          	auipc	ra,0xffffe
    800054f8:	4a8080e7          	jalr	1192(ra) # 8000399c <iunlockput>
  end_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	c7a080e7          	jalr	-902(ra) # 80004176 <end_op>
  return -1;
    80005504:	57fd                	li	a5,-1
}
    80005506:	853e                	mv	a0,a5
    80005508:	70b2                	ld	ra,296(sp)
    8000550a:	7412                	ld	s0,288(sp)
    8000550c:	64f2                	ld	s1,280(sp)
    8000550e:	6952                	ld	s2,272(sp)
    80005510:	6155                	addi	sp,sp,304
    80005512:	8082                	ret

0000000080005514 <sys_unlink>:
{
    80005514:	7151                	addi	sp,sp,-240
    80005516:	f586                	sd	ra,232(sp)
    80005518:	f1a2                	sd	s0,224(sp)
    8000551a:	eda6                	sd	s1,216(sp)
    8000551c:	e9ca                	sd	s2,208(sp)
    8000551e:	e5ce                	sd	s3,200(sp)
    80005520:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005522:	08000613          	li	a2,128
    80005526:	f3040593          	addi	a1,s0,-208
    8000552a:	4501                	li	a0,0
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	60c080e7          	jalr	1548(ra) # 80002b38 <argstr>
    80005534:	18054163          	bltz	a0,800056b6 <sys_unlink+0x1a2>
  begin_op();
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	bbe080e7          	jalr	-1090(ra) # 800040f6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005540:	fb040593          	addi	a1,s0,-80
    80005544:	f3040513          	addi	a0,s0,-208
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	9c0080e7          	jalr	-1600(ra) # 80003f08 <nameiparent>
    80005550:	84aa                	mv	s1,a0
    80005552:	c979                	beqz	a0,80005628 <sys_unlink+0x114>
  ilock(dp);
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	1e6080e7          	jalr	486(ra) # 8000373a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000555c:	00003597          	auipc	a1,0x3
    80005560:	26458593          	addi	a1,a1,612 # 800087c0 <syscalls+0x2c8>
    80005564:	fb040513          	addi	a0,s0,-80
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	696080e7          	jalr	1686(ra) # 80003bfe <namecmp>
    80005570:	14050a63          	beqz	a0,800056c4 <sys_unlink+0x1b0>
    80005574:	00003597          	auipc	a1,0x3
    80005578:	25458593          	addi	a1,a1,596 # 800087c8 <syscalls+0x2d0>
    8000557c:	fb040513          	addi	a0,s0,-80
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	67e080e7          	jalr	1662(ra) # 80003bfe <namecmp>
    80005588:	12050e63          	beqz	a0,800056c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000558c:	f2c40613          	addi	a2,s0,-212
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	682080e7          	jalr	1666(ra) # 80003c18 <dirlookup>
    8000559e:	892a                	mv	s2,a0
    800055a0:	12050263          	beqz	a0,800056c4 <sys_unlink+0x1b0>
  ilock(ip);
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	196080e7          	jalr	406(ra) # 8000373a <ilock>
  if(ip->nlink < 1)
    800055ac:	04a91783          	lh	a5,74(s2)
    800055b0:	08f05263          	blez	a5,80005634 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055b4:	04491703          	lh	a4,68(s2)
    800055b8:	4785                	li	a5,1
    800055ba:	08f70563          	beq	a4,a5,80005644 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055be:	4641                	li	a2,16
    800055c0:	4581                	li	a1,0
    800055c2:	fc040513          	addi	a0,s0,-64
    800055c6:	ffffb097          	auipc	ra,0xffffb
    800055ca:	76a080e7          	jalr	1898(ra) # 80000d30 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ce:	4741                	li	a4,16
    800055d0:	f2c42683          	lw	a3,-212(s0)
    800055d4:	fc040613          	addi	a2,s0,-64
    800055d8:	4581                	li	a1,0
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	508080e7          	jalr	1288(ra) # 80003ae4 <writei>
    800055e4:	47c1                	li	a5,16
    800055e6:	0af51563          	bne	a0,a5,80005690 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ea:	04491703          	lh	a4,68(s2)
    800055ee:	4785                	li	a5,1
    800055f0:	0af70863          	beq	a4,a5,800056a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800055f4:	8526                	mv	a0,s1
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	3a6080e7          	jalr	934(ra) # 8000399c <iunlockput>
  ip->nlink--;
    800055fe:	04a95783          	lhu	a5,74(s2)
    80005602:	37fd                	addiw	a5,a5,-1
    80005604:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005608:	854a                	mv	a0,s2
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	066080e7          	jalr	102(ra) # 80003670 <iupdate>
  iunlockput(ip);
    80005612:	854a                	mv	a0,s2
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	388080e7          	jalr	904(ra) # 8000399c <iunlockput>
  end_op();
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	b5a080e7          	jalr	-1190(ra) # 80004176 <end_op>
  return 0;
    80005624:	4501                	li	a0,0
    80005626:	a84d                	j	800056d8 <sys_unlink+0x1c4>
    end_op();
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	b4e080e7          	jalr	-1202(ra) # 80004176 <end_op>
    return -1;
    80005630:	557d                	li	a0,-1
    80005632:	a05d                	j	800056d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005634:	00003517          	auipc	a0,0x3
    80005638:	1bc50513          	addi	a0,a0,444 # 800087f0 <syscalls+0x2f8>
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	f0c080e7          	jalr	-244(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005644:	04c92703          	lw	a4,76(s2)
    80005648:	02000793          	li	a5,32
    8000564c:	f6e7f9e3          	bgeu	a5,a4,800055be <sys_unlink+0xaa>
    80005650:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005654:	4741                	li	a4,16
    80005656:	86ce                	mv	a3,s3
    80005658:	f1840613          	addi	a2,s0,-232
    8000565c:	4581                	li	a1,0
    8000565e:	854a                	mv	a0,s2
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	38e080e7          	jalr	910(ra) # 800039ee <readi>
    80005668:	47c1                	li	a5,16
    8000566a:	00f51b63          	bne	a0,a5,80005680 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000566e:	f1845783          	lhu	a5,-232(s0)
    80005672:	e7a1                	bnez	a5,800056ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005674:	29c1                	addiw	s3,s3,16
    80005676:	04c92783          	lw	a5,76(s2)
    8000567a:	fcf9ede3          	bltu	s3,a5,80005654 <sys_unlink+0x140>
    8000567e:	b781                	j	800055be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005680:	00003517          	auipc	a0,0x3
    80005684:	18850513          	addi	a0,a0,392 # 80008808 <syscalls+0x310>
    80005688:	ffffb097          	auipc	ra,0xffffb
    8000568c:	ec0080e7          	jalr	-320(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005690:	00003517          	auipc	a0,0x3
    80005694:	19050513          	addi	a0,a0,400 # 80008820 <syscalls+0x328>
    80005698:	ffffb097          	auipc	ra,0xffffb
    8000569c:	eb0080e7          	jalr	-336(ra) # 80000548 <panic>
    dp->nlink--;
    800056a0:	04a4d783          	lhu	a5,74(s1)
    800056a4:	37fd                	addiw	a5,a5,-1
    800056a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	fc4080e7          	jalr	-60(ra) # 80003670 <iupdate>
    800056b4:	b781                	j	800055f4 <sys_unlink+0xe0>
    return -1;
    800056b6:	557d                	li	a0,-1
    800056b8:	a005                	j	800056d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056ba:	854a                	mv	a0,s2
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	2e0080e7          	jalr	736(ra) # 8000399c <iunlockput>
  iunlockput(dp);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	2d6080e7          	jalr	726(ra) # 8000399c <iunlockput>
  end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	aa8080e7          	jalr	-1368(ra) # 80004176 <end_op>
  return -1;
    800056d6:	557d                	li	a0,-1
}
    800056d8:	70ae                	ld	ra,232(sp)
    800056da:	740e                	ld	s0,224(sp)
    800056dc:	64ee                	ld	s1,216(sp)
    800056de:	694e                	ld	s2,208(sp)
    800056e0:	69ae                	ld	s3,200(sp)
    800056e2:	616d                	addi	sp,sp,240
    800056e4:	8082                	ret

00000000800056e6 <sys_open>:

uint64
sys_open(void)
{
    800056e6:	7131                	addi	sp,sp,-192
    800056e8:	fd06                	sd	ra,184(sp)
    800056ea:	f922                	sd	s0,176(sp)
    800056ec:	f526                	sd	s1,168(sp)
    800056ee:	f14a                	sd	s2,160(sp)
    800056f0:	ed4e                	sd	s3,152(sp)
    800056f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f4:	08000613          	li	a2,128
    800056f8:	f5040593          	addi	a1,s0,-176
    800056fc:	4501                	li	a0,0
    800056fe:	ffffd097          	auipc	ra,0xffffd
    80005702:	43a080e7          	jalr	1082(ra) # 80002b38 <argstr>
    return -1;
    80005706:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005708:	0c054163          	bltz	a0,800057ca <sys_open+0xe4>
    8000570c:	f4c40593          	addi	a1,s0,-180
    80005710:	4505                	li	a0,1
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	3e2080e7          	jalr	994(ra) # 80002af4 <argint>
    8000571a:	0a054863          	bltz	a0,800057ca <sys_open+0xe4>

  begin_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	9d8080e7          	jalr	-1576(ra) # 800040f6 <begin_op>

  if(omode & O_CREATE){
    80005726:	f4c42783          	lw	a5,-180(s0)
    8000572a:	2007f793          	andi	a5,a5,512
    8000572e:	cbdd                	beqz	a5,800057e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005730:	4681                	li	a3,0
    80005732:	4601                	li	a2,0
    80005734:	4589                	li	a1,2
    80005736:	f5040513          	addi	a0,s0,-176
    8000573a:	00000097          	auipc	ra,0x0
    8000573e:	972080e7          	jalr	-1678(ra) # 800050ac <create>
    80005742:	892a                	mv	s2,a0
    if(ip == 0){
    80005744:	c959                	beqz	a0,800057da <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005746:	04491703          	lh	a4,68(s2)
    8000574a:	478d                	li	a5,3
    8000574c:	00f71763          	bne	a4,a5,8000575a <sys_open+0x74>
    80005750:	04695703          	lhu	a4,70(s2)
    80005754:	47a5                	li	a5,9
    80005756:	0ce7ec63          	bltu	a5,a4,8000582e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	db2080e7          	jalr	-590(ra) # 8000450c <filealloc>
    80005762:	89aa                	mv	s3,a0
    80005764:	10050263          	beqz	a0,80005868 <sys_open+0x182>
    80005768:	00000097          	auipc	ra,0x0
    8000576c:	902080e7          	jalr	-1790(ra) # 8000506a <fdalloc>
    80005770:	84aa                	mv	s1,a0
    80005772:	0e054663          	bltz	a0,8000585e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005776:	04491703          	lh	a4,68(s2)
    8000577a:	478d                	li	a5,3
    8000577c:	0cf70463          	beq	a4,a5,80005844 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005780:	4789                	li	a5,2
    80005782:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005786:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000578a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000578e:	f4c42783          	lw	a5,-180(s0)
    80005792:	0017c713          	xori	a4,a5,1
    80005796:	8b05                	andi	a4,a4,1
    80005798:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000579c:	0037f713          	andi	a4,a5,3
    800057a0:	00e03733          	snez	a4,a4
    800057a4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057a8:	4007f793          	andi	a5,a5,1024
    800057ac:	c791                	beqz	a5,800057b8 <sys_open+0xd2>
    800057ae:	04491703          	lh	a4,68(s2)
    800057b2:	4789                	li	a5,2
    800057b4:	08f70f63          	beq	a4,a5,80005852 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057b8:	854a                	mv	a0,s2
    800057ba:	ffffe097          	auipc	ra,0xffffe
    800057be:	042080e7          	jalr	66(ra) # 800037fc <iunlock>
  end_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	9b4080e7          	jalr	-1612(ra) # 80004176 <end_op>

  return fd;
}
    800057ca:	8526                	mv	a0,s1
    800057cc:	70ea                	ld	ra,184(sp)
    800057ce:	744a                	ld	s0,176(sp)
    800057d0:	74aa                	ld	s1,168(sp)
    800057d2:	790a                	ld	s2,160(sp)
    800057d4:	69ea                	ld	s3,152(sp)
    800057d6:	6129                	addi	sp,sp,192
    800057d8:	8082                	ret
      end_op();
    800057da:	fffff097          	auipc	ra,0xfffff
    800057de:	99c080e7          	jalr	-1636(ra) # 80004176 <end_op>
      return -1;
    800057e2:	b7e5                	j	800057ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057e4:	f5040513          	addi	a0,s0,-176
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	702080e7          	jalr	1794(ra) # 80003eea <namei>
    800057f0:	892a                	mv	s2,a0
    800057f2:	c905                	beqz	a0,80005822 <sys_open+0x13c>
    ilock(ip);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	f46080e7          	jalr	-186(ra) # 8000373a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057fc:	04491703          	lh	a4,68(s2)
    80005800:	4785                	li	a5,1
    80005802:	f4f712e3          	bne	a4,a5,80005746 <sys_open+0x60>
    80005806:	f4c42783          	lw	a5,-180(s0)
    8000580a:	dba1                	beqz	a5,8000575a <sys_open+0x74>
      iunlockput(ip);
    8000580c:	854a                	mv	a0,s2
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	18e080e7          	jalr	398(ra) # 8000399c <iunlockput>
      end_op();
    80005816:	fffff097          	auipc	ra,0xfffff
    8000581a:	960080e7          	jalr	-1696(ra) # 80004176 <end_op>
      return -1;
    8000581e:	54fd                	li	s1,-1
    80005820:	b76d                	j	800057ca <sys_open+0xe4>
      end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	954080e7          	jalr	-1708(ra) # 80004176 <end_op>
      return -1;
    8000582a:	54fd                	li	s1,-1
    8000582c:	bf79                	j	800057ca <sys_open+0xe4>
    iunlockput(ip);
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	16c080e7          	jalr	364(ra) # 8000399c <iunlockput>
    end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	93e080e7          	jalr	-1730(ra) # 80004176 <end_op>
    return -1;
    80005840:	54fd                	li	s1,-1
    80005842:	b761                	j	800057ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005844:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005848:	04691783          	lh	a5,70(s2)
    8000584c:	02f99223          	sh	a5,36(s3)
    80005850:	bf2d                	j	8000578a <sys_open+0xa4>
    itrunc(ip);
    80005852:	854a                	mv	a0,s2
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	ff4080e7          	jalr	-12(ra) # 80003848 <itrunc>
    8000585c:	bfb1                	j	800057b8 <sys_open+0xd2>
      fileclose(f);
    8000585e:	854e                	mv	a0,s3
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	d68080e7          	jalr	-664(ra) # 800045c8 <fileclose>
    iunlockput(ip);
    80005868:	854a                	mv	a0,s2
    8000586a:	ffffe097          	auipc	ra,0xffffe
    8000586e:	132080e7          	jalr	306(ra) # 8000399c <iunlockput>
    end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	904080e7          	jalr	-1788(ra) # 80004176 <end_op>
    return -1;
    8000587a:	54fd                	li	s1,-1
    8000587c:	b7b9                	j	800057ca <sys_open+0xe4>

000000008000587e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000587e:	7175                	addi	sp,sp,-144
    80005880:	e506                	sd	ra,136(sp)
    80005882:	e122                	sd	s0,128(sp)
    80005884:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	870080e7          	jalr	-1936(ra) # 800040f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000588e:	08000613          	li	a2,128
    80005892:	f7040593          	addi	a1,s0,-144
    80005896:	4501                	li	a0,0
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	2a0080e7          	jalr	672(ra) # 80002b38 <argstr>
    800058a0:	02054963          	bltz	a0,800058d2 <sys_mkdir+0x54>
    800058a4:	4681                	li	a3,0
    800058a6:	4601                	li	a2,0
    800058a8:	4585                	li	a1,1
    800058aa:	f7040513          	addi	a0,s0,-144
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	7fe080e7          	jalr	2046(ra) # 800050ac <create>
    800058b6:	cd11                	beqz	a0,800058d2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	0e4080e7          	jalr	228(ra) # 8000399c <iunlockput>
  end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	8b6080e7          	jalr	-1866(ra) # 80004176 <end_op>
  return 0;
    800058c8:	4501                	li	a0,0
}
    800058ca:	60aa                	ld	ra,136(sp)
    800058cc:	640a                	ld	s0,128(sp)
    800058ce:	6149                	addi	sp,sp,144
    800058d0:	8082                	ret
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	8a4080e7          	jalr	-1884(ra) # 80004176 <end_op>
    return -1;
    800058da:	557d                	li	a0,-1
    800058dc:	b7fd                	j	800058ca <sys_mkdir+0x4c>

00000000800058de <sys_mknod>:

uint64
sys_mknod(void)
{
    800058de:	7135                	addi	sp,sp,-160
    800058e0:	ed06                	sd	ra,152(sp)
    800058e2:	e922                	sd	s0,144(sp)
    800058e4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	810080e7          	jalr	-2032(ra) # 800040f6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ee:	08000613          	li	a2,128
    800058f2:	f7040593          	addi	a1,s0,-144
    800058f6:	4501                	li	a0,0
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	240080e7          	jalr	576(ra) # 80002b38 <argstr>
    80005900:	04054a63          	bltz	a0,80005954 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005904:	f6c40593          	addi	a1,s0,-148
    80005908:	4505                	li	a0,1
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	1ea080e7          	jalr	490(ra) # 80002af4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005912:	04054163          	bltz	a0,80005954 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005916:	f6840593          	addi	a1,s0,-152
    8000591a:	4509                	li	a0,2
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	1d8080e7          	jalr	472(ra) # 80002af4 <argint>
     argint(1, &major) < 0 ||
    80005924:	02054863          	bltz	a0,80005954 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005928:	f6841683          	lh	a3,-152(s0)
    8000592c:	f6c41603          	lh	a2,-148(s0)
    80005930:	458d                	li	a1,3
    80005932:	f7040513          	addi	a0,s0,-144
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	776080e7          	jalr	1910(ra) # 800050ac <create>
     argint(2, &minor) < 0 ||
    8000593e:	c919                	beqz	a0,80005954 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	05c080e7          	jalr	92(ra) # 8000399c <iunlockput>
  end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	82e080e7          	jalr	-2002(ra) # 80004176 <end_op>
  return 0;
    80005950:	4501                	li	a0,0
    80005952:	a031                	j	8000595e <sys_mknod+0x80>
    end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	822080e7          	jalr	-2014(ra) # 80004176 <end_op>
    return -1;
    8000595c:	557d                	li	a0,-1
}
    8000595e:	60ea                	ld	ra,152(sp)
    80005960:	644a                	ld	s0,144(sp)
    80005962:	610d                	addi	sp,sp,160
    80005964:	8082                	ret

0000000080005966 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005966:	7135                	addi	sp,sp,-160
    80005968:	ed06                	sd	ra,152(sp)
    8000596a:	e922                	sd	s0,144(sp)
    8000596c:	e526                	sd	s1,136(sp)
    8000596e:	e14a                	sd	s2,128(sp)
    80005970:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005972:	ffffc097          	auipc	ra,0xffffc
    80005976:	090080e7          	jalr	144(ra) # 80001a02 <myproc>
    8000597a:	892a                	mv	s2,a0
  
  begin_op();
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	77a080e7          	jalr	1914(ra) # 800040f6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005984:	08000613          	li	a2,128
    80005988:	f6040593          	addi	a1,s0,-160
    8000598c:	4501                	li	a0,0
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	1aa080e7          	jalr	426(ra) # 80002b38 <argstr>
    80005996:	04054b63          	bltz	a0,800059ec <sys_chdir+0x86>
    8000599a:	f6040513          	addi	a0,s0,-160
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	54c080e7          	jalr	1356(ra) # 80003eea <namei>
    800059a6:	84aa                	mv	s1,a0
    800059a8:	c131                	beqz	a0,800059ec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	d90080e7          	jalr	-624(ra) # 8000373a <ilock>
  if(ip->type != T_DIR){
    800059b2:	04449703          	lh	a4,68(s1)
    800059b6:	4785                	li	a5,1
    800059b8:	04f71063          	bne	a4,a5,800059f8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059bc:	8526                	mv	a0,s1
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	e3e080e7          	jalr	-450(ra) # 800037fc <iunlock>
  iput(p->cwd);
    800059c6:	15093503          	ld	a0,336(s2)
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	f2a080e7          	jalr	-214(ra) # 800038f4 <iput>
  end_op();
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	7a4080e7          	jalr	1956(ra) # 80004176 <end_op>
  p->cwd = ip;
    800059da:	14993823          	sd	s1,336(s2)
  return 0;
    800059de:	4501                	li	a0,0
}
    800059e0:	60ea                	ld	ra,152(sp)
    800059e2:	644a                	ld	s0,144(sp)
    800059e4:	64aa                	ld	s1,136(sp)
    800059e6:	690a                	ld	s2,128(sp)
    800059e8:	610d                	addi	sp,sp,160
    800059ea:	8082                	ret
    end_op();
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	78a080e7          	jalr	1930(ra) # 80004176 <end_op>
    return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	b7ed                	j	800059e0 <sys_chdir+0x7a>
    iunlockput(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	fa2080e7          	jalr	-94(ra) # 8000399c <iunlockput>
    end_op();
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	774080e7          	jalr	1908(ra) # 80004176 <end_op>
    return -1;
    80005a0a:	557d                	li	a0,-1
    80005a0c:	bfd1                	j	800059e0 <sys_chdir+0x7a>

0000000080005a0e <sys_exec>:

uint64
sys_exec(void)
{
    80005a0e:	7145                	addi	sp,sp,-464
    80005a10:	e786                	sd	ra,456(sp)
    80005a12:	e3a2                	sd	s0,448(sp)
    80005a14:	ff26                	sd	s1,440(sp)
    80005a16:	fb4a                	sd	s2,432(sp)
    80005a18:	f74e                	sd	s3,424(sp)
    80005a1a:	f352                	sd	s4,416(sp)
    80005a1c:	ef56                	sd	s5,408(sp)
    80005a1e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a20:	08000613          	li	a2,128
    80005a24:	f4040593          	addi	a1,s0,-192
    80005a28:	4501                	li	a0,0
    80005a2a:	ffffd097          	auipc	ra,0xffffd
    80005a2e:	10e080e7          	jalr	270(ra) # 80002b38 <argstr>
    return -1;
    80005a32:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a34:	0c054a63          	bltz	a0,80005b08 <sys_exec+0xfa>
    80005a38:	e3840593          	addi	a1,s0,-456
    80005a3c:	4505                	li	a0,1
    80005a3e:	ffffd097          	auipc	ra,0xffffd
    80005a42:	0d8080e7          	jalr	216(ra) # 80002b16 <argaddr>
    80005a46:	0c054163          	bltz	a0,80005b08 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a4a:	10000613          	li	a2,256
    80005a4e:	4581                	li	a1,0
    80005a50:	e4040513          	addi	a0,s0,-448
    80005a54:	ffffb097          	auipc	ra,0xffffb
    80005a58:	2dc080e7          	jalr	732(ra) # 80000d30 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a5c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a60:	89a6                	mv	s3,s1
    80005a62:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a64:	02000a13          	li	s4,32
    80005a68:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a6c:	00391513          	slli	a0,s2,0x3
    80005a70:	e3040593          	addi	a1,s0,-464
    80005a74:	e3843783          	ld	a5,-456(s0)
    80005a78:	953e                	add	a0,a0,a5
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	fe0080e7          	jalr	-32(ra) # 80002a5a <fetchaddr>
    80005a82:	02054a63          	bltz	a0,80005ab6 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a86:	e3043783          	ld	a5,-464(s0)
    80005a8a:	c3b9                	beqz	a5,80005ad0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a8c:	ffffb097          	auipc	ra,0xffffb
    80005a90:	094080e7          	jalr	148(ra) # 80000b20 <kalloc>
    80005a94:	85aa                	mv	a1,a0
    80005a96:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a9a:	cd11                	beqz	a0,80005ab6 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a9c:	6605                	lui	a2,0x1
    80005a9e:	e3043503          	ld	a0,-464(s0)
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	00a080e7          	jalr	10(ra) # 80002aac <fetchstr>
    80005aaa:	00054663          	bltz	a0,80005ab6 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005aae:	0905                	addi	s2,s2,1
    80005ab0:	09a1                	addi	s3,s3,8
    80005ab2:	fb491be3          	bne	s2,s4,80005a68 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab6:	10048913          	addi	s2,s1,256
    80005aba:	6088                	ld	a0,0(s1)
    80005abc:	c529                	beqz	a0,80005b06 <sys_exec+0xf8>
    kfree(argv[i]);
    80005abe:	ffffb097          	auipc	ra,0xffffb
    80005ac2:	f66080e7          	jalr	-154(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac6:	04a1                	addi	s1,s1,8
    80005ac8:	ff2499e3          	bne	s1,s2,80005aba <sys_exec+0xac>
  return -1;
    80005acc:	597d                	li	s2,-1
    80005ace:	a82d                	j	80005b08 <sys_exec+0xfa>
      argv[i] = 0;
    80005ad0:	0a8e                	slli	s5,s5,0x3
    80005ad2:	fc040793          	addi	a5,s0,-64
    80005ad6:	9abe                	add	s5,s5,a5
    80005ad8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005adc:	e4040593          	addi	a1,s0,-448
    80005ae0:	f4040513          	addi	a0,s0,-192
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	194080e7          	jalr	404(ra) # 80004c78 <exec>
    80005aec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aee:	10048993          	addi	s3,s1,256
    80005af2:	6088                	ld	a0,0(s1)
    80005af4:	c911                	beqz	a0,80005b08 <sys_exec+0xfa>
    kfree(argv[i]);
    80005af6:	ffffb097          	auipc	ra,0xffffb
    80005afa:	f2e080e7          	jalr	-210(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afe:	04a1                	addi	s1,s1,8
    80005b00:	ff3499e3          	bne	s1,s3,80005af2 <sys_exec+0xe4>
    80005b04:	a011                	j	80005b08 <sys_exec+0xfa>
  return -1;
    80005b06:	597d                	li	s2,-1
}
    80005b08:	854a                	mv	a0,s2
    80005b0a:	60be                	ld	ra,456(sp)
    80005b0c:	641e                	ld	s0,448(sp)
    80005b0e:	74fa                	ld	s1,440(sp)
    80005b10:	795a                	ld	s2,432(sp)
    80005b12:	79ba                	ld	s3,424(sp)
    80005b14:	7a1a                	ld	s4,416(sp)
    80005b16:	6afa                	ld	s5,408(sp)
    80005b18:	6179                	addi	sp,sp,464
    80005b1a:	8082                	ret

0000000080005b1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b1c:	7139                	addi	sp,sp,-64
    80005b1e:	fc06                	sd	ra,56(sp)
    80005b20:	f822                	sd	s0,48(sp)
    80005b22:	f426                	sd	s1,40(sp)
    80005b24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b26:	ffffc097          	auipc	ra,0xffffc
    80005b2a:	edc080e7          	jalr	-292(ra) # 80001a02 <myproc>
    80005b2e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b30:	fd840593          	addi	a1,s0,-40
    80005b34:	4501                	li	a0,0
    80005b36:	ffffd097          	auipc	ra,0xffffd
    80005b3a:	fe0080e7          	jalr	-32(ra) # 80002b16 <argaddr>
    return -1;
    80005b3e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b40:	0e054063          	bltz	a0,80005c20 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b44:	fc840593          	addi	a1,s0,-56
    80005b48:	fd040513          	addi	a0,s0,-48
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	dd2080e7          	jalr	-558(ra) # 8000491e <pipealloc>
    return -1;
    80005b54:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b56:	0c054563          	bltz	a0,80005c20 <sys_pipe+0x104>
  fd0 = -1;
    80005b5a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b5e:	fd043503          	ld	a0,-48(s0)
    80005b62:	fffff097          	auipc	ra,0xfffff
    80005b66:	508080e7          	jalr	1288(ra) # 8000506a <fdalloc>
    80005b6a:	fca42223          	sw	a0,-60(s0)
    80005b6e:	08054c63          	bltz	a0,80005c06 <sys_pipe+0xea>
    80005b72:	fc843503          	ld	a0,-56(s0)
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	4f4080e7          	jalr	1268(ra) # 8000506a <fdalloc>
    80005b7e:	fca42023          	sw	a0,-64(s0)
    80005b82:	06054863          	bltz	a0,80005bf2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b86:	4691                	li	a3,4
    80005b88:	fc440613          	addi	a2,s0,-60
    80005b8c:	fd843583          	ld	a1,-40(s0)
    80005b90:	68a8                	ld	a0,80(s1)
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	b64080e7          	jalr	-1180(ra) # 800016f6 <copyout>
    80005b9a:	02054063          	bltz	a0,80005bba <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b9e:	4691                	li	a3,4
    80005ba0:	fc040613          	addi	a2,s0,-64
    80005ba4:	fd843583          	ld	a1,-40(s0)
    80005ba8:	0591                	addi	a1,a1,4
    80005baa:	68a8                	ld	a0,80(s1)
    80005bac:	ffffc097          	auipc	ra,0xffffc
    80005bb0:	b4a080e7          	jalr	-1206(ra) # 800016f6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb6:	06055563          	bgez	a0,80005c20 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bba:	fc442783          	lw	a5,-60(s0)
    80005bbe:	07e9                	addi	a5,a5,26
    80005bc0:	078e                	slli	a5,a5,0x3
    80005bc2:	97a6                	add	a5,a5,s1
    80005bc4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bc8:	fc042503          	lw	a0,-64(s0)
    80005bcc:	0569                	addi	a0,a0,26
    80005bce:	050e                	slli	a0,a0,0x3
    80005bd0:	9526                	add	a0,a0,s1
    80005bd2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bd6:	fd043503          	ld	a0,-48(s0)
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	9ee080e7          	jalr	-1554(ra) # 800045c8 <fileclose>
    fileclose(wf);
    80005be2:	fc843503          	ld	a0,-56(s0)
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	9e2080e7          	jalr	-1566(ra) # 800045c8 <fileclose>
    return -1;
    80005bee:	57fd                	li	a5,-1
    80005bf0:	a805                	j	80005c20 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bf2:	fc442783          	lw	a5,-60(s0)
    80005bf6:	0007c863          	bltz	a5,80005c06 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bfa:	01a78513          	addi	a0,a5,26
    80005bfe:	050e                	slli	a0,a0,0x3
    80005c00:	9526                	add	a0,a0,s1
    80005c02:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c06:	fd043503          	ld	a0,-48(s0)
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	9be080e7          	jalr	-1602(ra) # 800045c8 <fileclose>
    fileclose(wf);
    80005c12:	fc843503          	ld	a0,-56(s0)
    80005c16:	fffff097          	auipc	ra,0xfffff
    80005c1a:	9b2080e7          	jalr	-1614(ra) # 800045c8 <fileclose>
    return -1;
    80005c1e:	57fd                	li	a5,-1
}
    80005c20:	853e                	mv	a0,a5
    80005c22:	70e2                	ld	ra,56(sp)
    80005c24:	7442                	ld	s0,48(sp)
    80005c26:	74a2                	ld	s1,40(sp)
    80005c28:	6121                	addi	sp,sp,64
    80005c2a:	8082                	ret
    80005c2c:	0000                	unimp
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	cb7fc0ef          	jal	ra,80002926 <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	710c                	ld	a1,32(a0)
    80005ccc:	7510                	ld	a2,40(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	cce080e7          	jalr	-818(ra) # 800019d6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	00052023          	sw	zero,0(a0)
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	c96080e7          	jalr	-874(ra) # 800019d6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5179b          	slliw	a5,a0,0xd
    80005d4c:	0c201537          	lui	a0,0xc201
    80005d50:	953e                	add	a0,a0,a5
  return irq;
}
    80005d52:	4148                	lw	a0,4(a0)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c6e080e7          	jalr	-914(ra) # 800019d6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	04a7cc63          	blt	a5,a0,80005de8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	26c78793          	addi	a5,a5,620 # 80023000 <disk>
    80005d9c:	00a78733          	add	a4,a5,a0
    80005da0:	6789                	lui	a5,0x2
    80005da2:	97ba                	add	a5,a5,a4
    80005da4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005da8:	eba1                	bnez	a5,80005df8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005daa:	00451713          	slli	a4,a0,0x4
    80005dae:	0001f797          	auipc	a5,0x1f
    80005db2:	2527b783          	ld	a5,594(a5) # 80025000 <disk+0x2000>
    80005db6:	97ba                	add	a5,a5,a4
    80005db8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dbc:	0001d797          	auipc	a5,0x1d
    80005dc0:	24478793          	addi	a5,a5,580 # 80023000 <disk>
    80005dc4:	97aa                	add	a5,a5,a0
    80005dc6:	6509                	lui	a0,0x2
    80005dc8:	953e                	add	a0,a0,a5
    80005dca:	4785                	li	a5,1
    80005dcc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dd0:	0001f517          	auipc	a0,0x1f
    80005dd4:	24850513          	addi	a0,a0,584 # 80025018 <disk+0x2018>
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	5c4080e7          	jalr	1476(ra) # 8000239c <wakeup>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	a4850513          	addi	a0,a0,-1464 # 80008830 <syscalls+0x338>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	758080e7          	jalr	1880(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005df8:	00003517          	auipc	a0,0x3
    80005dfc:	a5050513          	addi	a0,a0,-1456 # 80008848 <syscalls+0x350>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	748080e7          	jalr	1864(ra) # 80000548 <panic>

0000000080005e08 <virtio_disk_init>:
{
    80005e08:	1101                	addi	sp,sp,-32
    80005e0a:	ec06                	sd	ra,24(sp)
    80005e0c:	e822                	sd	s0,16(sp)
    80005e0e:	e426                	sd	s1,8(sp)
    80005e10:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e12:	00003597          	auipc	a1,0x3
    80005e16:	a4e58593          	addi	a1,a1,-1458 # 80008860 <syscalls+0x368>
    80005e1a:	0001f517          	auipc	a0,0x1f
    80005e1e:	28e50513          	addi	a0,a0,654 # 800250a8 <disk+0x20a8>
    80005e22:	ffffb097          	auipc	ra,0xffffb
    80005e26:	d82080e7          	jalr	-638(ra) # 80000ba4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e2a:	100017b7          	lui	a5,0x10001
    80005e2e:	4398                	lw	a4,0(a5)
    80005e30:	2701                	sext.w	a4,a4
    80005e32:	747277b7          	lui	a5,0x74727
    80005e36:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e3a:	0ef71163          	bne	a4,a5,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	43dc                	lw	a5,4(a5)
    80005e44:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e46:	4705                	li	a4,1
    80005e48:	0ce79a63          	bne	a5,a4,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4c:	100017b7          	lui	a5,0x10001
    80005e50:	479c                	lw	a5,8(a5)
    80005e52:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e54:	4709                	li	a4,2
    80005e56:	0ce79363          	bne	a5,a4,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	47d8                	lw	a4,12(a5)
    80005e60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e62:	554d47b7          	lui	a5,0x554d4
    80005e66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e6a:	0af71963          	bne	a4,a5,80005f1c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	4705                	li	a4,1
    80005e74:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e76:	470d                	li	a4,3
    80005e78:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e7a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e7c:	c7ffe737          	lui	a4,0xc7ffe
    80005e80:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e84:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e86:	2701                	sext.w	a4,a4
    80005e88:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8a:	472d                	li	a4,11
    80005e8c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	473d                	li	a4,15
    80005e90:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e92:	6705                	lui	a4,0x1
    80005e94:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e96:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e9a:	5bdc                	lw	a5,52(a5)
    80005e9c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e9e:	c7d9                	beqz	a5,80005f2c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ea0:	471d                	li	a4,7
    80005ea2:	08f77d63          	bgeu	a4,a5,80005f3c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ea6:	100014b7          	lui	s1,0x10001
    80005eaa:	47a1                	li	a5,8
    80005eac:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eae:	6609                	lui	a2,0x2
    80005eb0:	4581                	li	a1,0
    80005eb2:	0001d517          	auipc	a0,0x1d
    80005eb6:	14e50513          	addi	a0,a0,334 # 80023000 <disk>
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	e76080e7          	jalr	-394(ra) # 80000d30 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ec2:	0001d717          	auipc	a4,0x1d
    80005ec6:	13e70713          	addi	a4,a4,318 # 80023000 <disk>
    80005eca:	00c75793          	srli	a5,a4,0xc
    80005ece:	2781                	sext.w	a5,a5
    80005ed0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ed2:	0001f797          	auipc	a5,0x1f
    80005ed6:	12e78793          	addi	a5,a5,302 # 80025000 <disk+0x2000>
    80005eda:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005edc:	0001d717          	auipc	a4,0x1d
    80005ee0:	1a470713          	addi	a4,a4,420 # 80023080 <disk+0x80>
    80005ee4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ee6:	0001e717          	auipc	a4,0x1e
    80005eea:	11a70713          	addi	a4,a4,282 # 80024000 <disk+0x1000>
    80005eee:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ef0:	4705                	li	a4,1
    80005ef2:	00e78c23          	sb	a4,24(a5)
    80005ef6:	00e78ca3          	sb	a4,25(a5)
    80005efa:	00e78d23          	sb	a4,26(a5)
    80005efe:	00e78da3          	sb	a4,27(a5)
    80005f02:	00e78e23          	sb	a4,28(a5)
    80005f06:	00e78ea3          	sb	a4,29(a5)
    80005f0a:	00e78f23          	sb	a4,30(a5)
    80005f0e:	00e78fa3          	sb	a4,31(a5)
}
    80005f12:	60e2                	ld	ra,24(sp)
    80005f14:	6442                	ld	s0,16(sp)
    80005f16:	64a2                	ld	s1,8(sp)
    80005f18:	6105                	addi	sp,sp,32
    80005f1a:	8082                	ret
    panic("could not find virtio disk");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	95450513          	addi	a0,a0,-1708 # 80008870 <syscalls+0x378>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f2c:	00003517          	auipc	a0,0x3
    80005f30:	96450513          	addi	a0,a0,-1692 # 80008890 <syscalls+0x398>
    80005f34:	ffffa097          	auipc	ra,0xffffa
    80005f38:	614080e7          	jalr	1556(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	97450513          	addi	a0,a0,-1676 # 800088b0 <syscalls+0x3b8>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>

0000000080005f4c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f4c:	7119                	addi	sp,sp,-128
    80005f4e:	fc86                	sd	ra,120(sp)
    80005f50:	f8a2                	sd	s0,112(sp)
    80005f52:	f4a6                	sd	s1,104(sp)
    80005f54:	f0ca                	sd	s2,96(sp)
    80005f56:	ecce                	sd	s3,88(sp)
    80005f58:	e8d2                	sd	s4,80(sp)
    80005f5a:	e4d6                	sd	s5,72(sp)
    80005f5c:	e0da                	sd	s6,64(sp)
    80005f5e:	fc5e                	sd	s7,56(sp)
    80005f60:	f862                	sd	s8,48(sp)
    80005f62:	f466                	sd	s9,40(sp)
    80005f64:	f06a                	sd	s10,32(sp)
    80005f66:	0100                	addi	s0,sp,128
    80005f68:	892a                	mv	s2,a0
    80005f6a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f6c:	00c52c83          	lw	s9,12(a0)
    80005f70:	001c9c9b          	slliw	s9,s9,0x1
    80005f74:	1c82                	slli	s9,s9,0x20
    80005f76:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f7a:	0001f517          	auipc	a0,0x1f
    80005f7e:	12e50513          	addi	a0,a0,302 # 800250a8 <disk+0x20a8>
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	cb2080e7          	jalr	-846(ra) # 80000c34 <acquire>
  for(int i = 0; i < 3; i++){
    80005f8a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f8c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f8e:	0001db97          	auipc	s7,0x1d
    80005f92:	072b8b93          	addi	s7,s7,114 # 80023000 <disk>
    80005f96:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f98:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f9a:	8a4e                	mv	s4,s3
    80005f9c:	a051                	j	80006020 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f9e:	00fb86b3          	add	a3,s7,a5
    80005fa2:	96da                	add	a3,a3,s6
    80005fa4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fa8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005faa:	0207c563          	bltz	a5,80005fd4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fae:	2485                	addiw	s1,s1,1
    80005fb0:	0711                	addi	a4,a4,4
    80005fb2:	23548d63          	beq	s1,s5,800061ec <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fb6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fb8:	0001f697          	auipc	a3,0x1f
    80005fbc:	06068693          	addi	a3,a3,96 # 80025018 <disk+0x2018>
    80005fc0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fc2:	0006c583          	lbu	a1,0(a3)
    80005fc6:	fde1                	bnez	a1,80005f9e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fc8:	2785                	addiw	a5,a5,1
    80005fca:	0685                	addi	a3,a3,1
    80005fcc:	ff879be3          	bne	a5,s8,80005fc2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fd0:	57fd                	li	a5,-1
    80005fd2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fd4:	02905a63          	blez	s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd8:	f9042503          	lw	a0,-112(s0)
    80005fdc:	00000097          	auipc	ra,0x0
    80005fe0:	daa080e7          	jalr	-598(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe4:	4785                	li	a5,1
    80005fe6:	0297d163          	bge	a5,s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fea:	f9442503          	lw	a0,-108(s0)
    80005fee:	00000097          	auipc	ra,0x0
    80005ff2:	d98080e7          	jalr	-616(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff6:	4789                	li	a5,2
    80005ff8:	0097d863          	bge	a5,s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ffc:	f9842503          	lw	a0,-104(s0)
    80006000:	00000097          	auipc	ra,0x0
    80006004:	d86080e7          	jalr	-634(ra) # 80005d86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	0001f597          	auipc	a1,0x1f
    8000600c:	0a058593          	addi	a1,a1,160 # 800250a8 <disk+0x20a8>
    80006010:	0001f517          	auipc	a0,0x1f
    80006014:	00850513          	addi	a0,a0,8 # 80025018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	1fe080e7          	jalr	510(ra) # 80002216 <sleep>
  for(int i = 0; i < 3; i++){
    80006020:	f9040713          	addi	a4,s0,-112
    80006024:	84ce                	mv	s1,s3
    80006026:	bf41                	j	80005fb6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006028:	4785                	li	a5,1
    8000602a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000602e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006032:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006036:	f9042983          	lw	s3,-112(s0)
    8000603a:	00499493          	slli	s1,s3,0x4
    8000603e:	0001fa17          	auipc	s4,0x1f
    80006042:	fc2a0a13          	addi	s4,s4,-62 # 80025000 <disk+0x2000>
    80006046:	000a3a83          	ld	s5,0(s4)
    8000604a:	9aa6                	add	s5,s5,s1
    8000604c:	f8040513          	addi	a0,s0,-128
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	0b4080e7          	jalr	180(ra) # 80001104 <kvmpa>
    80006058:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000605c:	000a3783          	ld	a5,0(s4)
    80006060:	97a6                	add	a5,a5,s1
    80006062:	4741                	li	a4,16
    80006064:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006066:	000a3783          	ld	a5,0(s4)
    8000606a:	97a6                	add	a5,a5,s1
    8000606c:	4705                	li	a4,1
    8000606e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006072:	f9442703          	lw	a4,-108(s0)
    80006076:	000a3783          	ld	a5,0(s4)
    8000607a:	97a6                	add	a5,a5,s1
    8000607c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006080:	0712                	slli	a4,a4,0x4
    80006082:	000a3783          	ld	a5,0(s4)
    80006086:	97ba                	add	a5,a5,a4
    80006088:	05890693          	addi	a3,s2,88
    8000608c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000608e:	000a3783          	ld	a5,0(s4)
    80006092:	97ba                	add	a5,a5,a4
    80006094:	40000693          	li	a3,1024
    80006098:	c794                	sw	a3,8(a5)
  if(write)
    8000609a:	100d0a63          	beqz	s10,800061ae <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000609e:	0001f797          	auipc	a5,0x1f
    800060a2:	f627b783          	ld	a5,-158(a5) # 80025000 <disk+0x2000>
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	f5450513          	addi	a0,a0,-172 # 80023000 <disk>
    800060b4:	0001f797          	auipc	a5,0x1f
    800060b8:	f4c78793          	addi	a5,a5,-180 # 80025000 <disk+0x2000>
    800060bc:	6394                	ld	a3,0(a5)
    800060be:	96ba                	add	a3,a3,a4
    800060c0:	00c6d603          	lhu	a2,12(a3)
    800060c4:	00166613          	ori	a2,a2,1
    800060c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060cc:	f9842683          	lw	a3,-104(s0)
    800060d0:	6390                	ld	a2,0(a5)
    800060d2:	9732                	add	a4,a4,a2
    800060d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060d8:	20098613          	addi	a2,s3,512
    800060dc:	0612                	slli	a2,a2,0x4
    800060de:	962a                	add	a2,a2,a0
    800060e0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060e4:	00469713          	slli	a4,a3,0x4
    800060e8:	6394                	ld	a3,0(a5)
    800060ea:	96ba                	add	a3,a3,a4
    800060ec:	6589                	lui	a1,0x2
    800060ee:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060f2:	94ae                	add	s1,s1,a1
    800060f4:	94aa                	add	s1,s1,a0
    800060f6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060f8:	6394                	ld	a3,0(a5)
    800060fa:	96ba                	add	a3,a3,a4
    800060fc:	4585                	li	a1,1
    800060fe:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006100:	6394                	ld	a3,0(a5)
    80006102:	96ba                	add	a3,a3,a4
    80006104:	4509                	li	a0,2
    80006106:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000610a:	6394                	ld	a3,0(a5)
    8000610c:	9736                	add	a4,a4,a3
    8000610e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006112:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006116:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000611a:	6794                	ld	a3,8(a5)
    8000611c:	0026d703          	lhu	a4,2(a3)
    80006120:	8b1d                	andi	a4,a4,7
    80006122:	2709                	addiw	a4,a4,2
    80006124:	0706                	slli	a4,a4,0x1
    80006126:	9736                	add	a4,a4,a3
    80006128:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000612c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006130:	6798                	ld	a4,8(a5)
    80006132:	00275783          	lhu	a5,2(a4)
    80006136:	2785                	addiw	a5,a5,1
    80006138:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006144:	00492703          	lw	a4,4(s2)
    80006148:	4785                	li	a5,1
    8000614a:	02f71163          	bne	a4,a5,8000616c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000614e:	0001f997          	auipc	s3,0x1f
    80006152:	f5a98993          	addi	s3,s3,-166 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006156:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006158:	85ce                	mv	a1,s3
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffc097          	auipc	ra,0xffffc
    80006160:	0ba080e7          	jalr	186(ra) # 80002216 <sleep>
  while(b->disk == 1) {
    80006164:	00492783          	lw	a5,4(s2)
    80006168:	fe9788e3          	beq	a5,s1,80006158 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000616c:	f9042483          	lw	s1,-112(s0)
    80006170:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006174:	00479713          	slli	a4,a5,0x4
    80006178:	0001d797          	auipc	a5,0x1d
    8000617c:	e8878793          	addi	a5,a5,-376 # 80023000 <disk>
    80006180:	97ba                	add	a5,a5,a4
    80006182:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006186:	0001f917          	auipc	s2,0x1f
    8000618a:	e7a90913          	addi	s2,s2,-390 # 80025000 <disk+0x2000>
    free_desc(i);
    8000618e:	8526                	mv	a0,s1
    80006190:	00000097          	auipc	ra,0x0
    80006194:	bf6080e7          	jalr	-1034(ra) # 80005d86 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006198:	0492                	slli	s1,s1,0x4
    8000619a:	00093783          	ld	a5,0(s2)
    8000619e:	94be                	add	s1,s1,a5
    800061a0:	00c4d783          	lhu	a5,12(s1)
    800061a4:	8b85                	andi	a5,a5,1
    800061a6:	cf89                	beqz	a5,800061c0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061a8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ac:	b7cd                	j	8000618e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ae:	0001f797          	auipc	a5,0x1f
    800061b2:	e527b783          	ld	a5,-430(a5) # 80025000 <disk+0x2000>
    800061b6:	97ba                	add	a5,a5,a4
    800061b8:	4689                	li	a3,2
    800061ba:	00d79623          	sh	a3,12(a5)
    800061be:	b5fd                	j	800060ac <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061c0:	0001f517          	auipc	a0,0x1f
    800061c4:	ee850513          	addi	a0,a0,-280 # 800250a8 <disk+0x20a8>
    800061c8:	ffffb097          	auipc	ra,0xffffb
    800061cc:	b20080e7          	jalr	-1248(ra) # 80000ce8 <release>
}
    800061d0:	70e6                	ld	ra,120(sp)
    800061d2:	7446                	ld	s0,112(sp)
    800061d4:	74a6                	ld	s1,104(sp)
    800061d6:	7906                	ld	s2,96(sp)
    800061d8:	69e6                	ld	s3,88(sp)
    800061da:	6a46                	ld	s4,80(sp)
    800061dc:	6aa6                	ld	s5,72(sp)
    800061de:	6b06                	ld	s6,64(sp)
    800061e0:	7be2                	ld	s7,56(sp)
    800061e2:	7c42                	ld	s8,48(sp)
    800061e4:	7ca2                	ld	s9,40(sp)
    800061e6:	7d02                	ld	s10,32(sp)
    800061e8:	6109                	addi	sp,sp,128
    800061ea:	8082                	ret
  if(write)
    800061ec:	e20d1ee3          	bnez	s10,80006028 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061f0:	f8042023          	sw	zero,-128(s0)
    800061f4:	bd2d                	j	8000602e <virtio_disk_rw+0xe2>

00000000800061f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061f6:	1101                	addi	sp,sp,-32
    800061f8:	ec06                	sd	ra,24(sp)
    800061fa:	e822                	sd	s0,16(sp)
    800061fc:	e426                	sd	s1,8(sp)
    800061fe:	e04a                	sd	s2,0(sp)
    80006200:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006202:	0001f517          	auipc	a0,0x1f
    80006206:	ea650513          	addi	a0,a0,-346 # 800250a8 <disk+0x20a8>
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	a2a080e7          	jalr	-1494(ra) # 80000c34 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006212:	0001f717          	auipc	a4,0x1f
    80006216:	dee70713          	addi	a4,a4,-530 # 80025000 <disk+0x2000>
    8000621a:	02075783          	lhu	a5,32(a4)
    8000621e:	6b18                	ld	a4,16(a4)
    80006220:	00275683          	lhu	a3,2(a4)
    80006224:	8ebd                	xor	a3,a3,a5
    80006226:	8a9d                	andi	a3,a3,7
    80006228:	cab9                	beqz	a3,8000627e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000622a:	0001d917          	auipc	s2,0x1d
    8000622e:	dd690913          	addi	s2,s2,-554 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006232:	0001f497          	auipc	s1,0x1f
    80006236:	dce48493          	addi	s1,s1,-562 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000623a:	078e                	slli	a5,a5,0x3
    8000623c:	97ba                	add	a5,a5,a4
    8000623e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006240:	20078713          	addi	a4,a5,512
    80006244:	0712                	slli	a4,a4,0x4
    80006246:	974a                	add	a4,a4,s2
    80006248:	03074703          	lbu	a4,48(a4)
    8000624c:	ef21                	bnez	a4,800062a4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000624e:	20078793          	addi	a5,a5,512
    80006252:	0792                	slli	a5,a5,0x4
    80006254:	97ca                	add	a5,a5,s2
    80006256:	7798                	ld	a4,40(a5)
    80006258:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000625c:	7788                	ld	a0,40(a5)
    8000625e:	ffffc097          	auipc	ra,0xffffc
    80006262:	13e080e7          	jalr	318(ra) # 8000239c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006266:	0204d783          	lhu	a5,32(s1)
    8000626a:	2785                	addiw	a5,a5,1
    8000626c:	8b9d                	andi	a5,a5,7
    8000626e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006272:	6898                	ld	a4,16(s1)
    80006274:	00275683          	lhu	a3,2(a4)
    80006278:	8a9d                	andi	a3,a3,7
    8000627a:	fcf690e3          	bne	a3,a5,8000623a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000627e:	10001737          	lui	a4,0x10001
    80006282:	533c                	lw	a5,96(a4)
    80006284:	8b8d                	andi	a5,a5,3
    80006286:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006288:	0001f517          	auipc	a0,0x1f
    8000628c:	e2050513          	addi	a0,a0,-480 # 800250a8 <disk+0x20a8>
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	a58080e7          	jalr	-1448(ra) # 80000ce8 <release>
}
    80006298:	60e2                	ld	ra,24(sp)
    8000629a:	6442                	ld	s0,16(sp)
    8000629c:	64a2                	ld	s1,8(sp)
    8000629e:	6902                	ld	s2,0(sp)
    800062a0:	6105                	addi	sp,sp,32
    800062a2:	8082                	ret
      panic("virtio_disk_intr status");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	62c50513          	addi	a0,a0,1580 # 800088d0 <syscalls+0x3d8>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	29c080e7          	jalr	668(ra) # 80000548 <panic>
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
