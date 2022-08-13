
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	f3c78793          	addi	a5,a5,-196 # 80005fa0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	3f4080e7          	jalr	1012(ra) # 80002512 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00001097          	auipc	ra,0x1
    800001ba:	7f0080e7          	jalr	2032(ra) # 800019a6 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	094080e7          	jalr	148(ra) # 8000225a <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	2ba080e7          	jalr	698(ra) # 800024bc <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	284080e7          	jalr	644(ra) # 80002568 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	fa8080e7          	jalr	-88(ra) # 800023e0 <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	0002d797          	auipc	a5,0x2d
    8000046e:	e9678793          	addi	a5,a5,-362 # 8002d300 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	b4e080e7          	jalr	-1202(ra) # 800023e0 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	93c080e7          	jalr	-1732(ra) # 8000225a <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00031797          	auipc	a5,0x31
    80000a02:	60278793          	addi	a5,a5,1538 # 80032000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00031517          	auipc	a0,0x31
    80000ad2:	53250513          	addi	a0,a0,1330 # 80032000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e1a080e7          	jalr	-486(ra) # 8000198a <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	de8080e7          	jalr	-536(ra) # 8000198a <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ddc080e7          	jalr	-548(ra) # 8000198a <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dc4080e7          	jalr	-572(ra) # 8000198a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d84080e7          	jalr	-636(ra) # 8000198a <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d58080e7          	jalr	-680(ra) # 8000198a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	aee080e7          	jalr	-1298(ra) # 8000197a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	ad2080e7          	jalr	-1326(ra) # 8000197a <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	7de080e7          	jalr	2014(ra) # 800026a8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	10e080e7          	jalr	270(ra) # 80005fe0 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	03c080e7          	jalr	60(ra) # 80001f16 <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	9a8080e7          	jalr	-1624(ra) # 800018e2 <procinit>
    trapinit();      // trap vectors
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	73e080e7          	jalr	1854(ra) # 80002680 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	75e080e7          	jalr	1886(ra) # 800026a8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	078080e7          	jalr	120(ra) # 80005fca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	086080e7          	jalr	134(ra) # 80005fe0 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	fc4080e7          	jalr	-60(ra) # 80002f26 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	654080e7          	jalr	1620(ra) # 800035be <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	606080e7          	jalr	1542(ra) # 80004578 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	188080e7          	jalr	392(ra) # 80006102 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	cee080e7          	jalr	-786(ra) # 80001c70 <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	628080e7          	jalr	1576(ra) # 8000184c <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue;
      //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6a85                	lui	s5,0x1
    80001286:	0735e163          	bltu	a1,s3,800012e8 <uvmunmap+0x8e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012d0:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    800012d2:	00c79513          	slli	a0,a5,0xc
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	714080e7          	jalr	1812(ra) # 800009ea <kfree>
    *pte = 0;
    800012de:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e2:	9956                	add	s2,s2,s5
    800012e4:	fb3973e3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012e8:	4601                	li	a2,0
    800012ea:	85ca                	mv	a1,s2
    800012ec:	8552                	mv	a0,s4
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	cd0080e7          	jalr	-816(ra) # 80000fbe <walk>
    800012f6:	84aa                	mv	s1,a0
    800012f8:	dd45                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012fa:	611c                	ld	a5,0(a0)
    800012fc:	0017f713          	andi	a4,a5,1
    80001300:	d36d                	beqz	a4,800012e2 <uvmunmap+0x88>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001302:	3ff7f713          	andi	a4,a5,1023
    80001306:	fb770de3          	beq	a4,s7,800012c0 <uvmunmap+0x66>
    if(do_free){
    8000130a:	fc0b0ae3          	beqz	s6,800012de <uvmunmap+0x84>
    8000130e:	b7c9                	j	800012d0 <uvmunmap+0x76>

0000000080001310 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001310:	1101                	addi	sp,sp,-32
    80001312:	ec06                	sd	ra,24(sp)
    80001314:	e822                	sd	s0,16(sp)
    80001316:	e426                	sd	s1,8(sp)
    80001318:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	7cc080e7          	jalr	1996(ra) # 80000ae6 <kalloc>
    80001322:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001324:	c519                	beqz	a0,80001332 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001326:	6605                	lui	a2,0x1
    80001328:	4581                	li	a1,0
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	9a8080e7          	jalr	-1624(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001332:	8526                	mv	a0,s1
    80001334:	60e2                	ld	ra,24(sp)
    80001336:	6442                	ld	s0,16(sp)
    80001338:	64a2                	ld	s1,8(sp)
    8000133a:	6105                	addi	sp,sp,32
    8000133c:	8082                	ret

000000008000133e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000133e:	7179                	addi	sp,sp,-48
    80001340:	f406                	sd	ra,40(sp)
    80001342:	f022                	sd	s0,32(sp)
    80001344:	ec26                	sd	s1,24(sp)
    80001346:	e84a                	sd	s2,16(sp)
    80001348:	e44e                	sd	s3,8(sp)
    8000134a:	e052                	sd	s4,0(sp)
    8000134c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000134e:	6785                	lui	a5,0x1
    80001350:	04f67863          	bgeu	a2,a5,800013a0 <uvminit+0x62>
    80001354:	8a2a                	mv	s4,a0
    80001356:	89ae                	mv	s3,a1
    80001358:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	78c080e7          	jalr	1932(ra) # 80000ae6 <kalloc>
    80001362:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	00000097          	auipc	ra,0x0
    8000136c:	96a080e7          	jalr	-1686(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001370:	4779                	li	a4,30
    80001372:	86ca                	mv	a3,s2
    80001374:	6605                	lui	a2,0x1
    80001376:	4581                	li	a1,0
    80001378:	8552                	mv	a0,s4
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	d2c080e7          	jalr	-724(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001382:	8626                	mv	a2,s1
    80001384:	85ce                	mv	a1,s3
    80001386:	854a                	mv	a0,s2
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	9aa080e7          	jalr	-1622(ra) # 80000d32 <memmove>
}
    80001390:	70a2                	ld	ra,40(sp)
    80001392:	7402                	ld	s0,32(sp)
    80001394:	64e2                	ld	s1,24(sp)
    80001396:	6942                	ld	s2,16(sp)
    80001398:	69a2                	ld	s3,8(sp)
    8000139a:	6a02                	ld	s4,0(sp)
    8000139c:	6145                	addi	sp,sp,48
    8000139e:	8082                	ret
    panic("inituvm: more than a page");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d8850513          	addi	a0,a0,-632 # 80008128 <digits+0xe8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	188080e7          	jalr	392(ra) # 80000530 <panic>

00000000800013b0 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ba:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013bc:	00b67d63          	bgeu	a2,a1,800013d6 <uvmdealloc+0x26>
    800013c0:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c2:	6785                	lui	a5,0x1
    800013c4:	17fd                	addi	a5,a5,-1
    800013c6:	00f60733          	add	a4,a2,a5
    800013ca:	767d                	lui	a2,0xfffff
    800013cc:	8f71                	and	a4,a4,a2
    800013ce:	97ae                	add	a5,a5,a1
    800013d0:	8ff1                	and	a5,a5,a2
    800013d2:	00f76863          	bltu	a4,a5,800013e2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e2:	8f99                	sub	a5,a5,a4
    800013e4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013e6:	4685                	li	a3,1
    800013e8:	0007861b          	sext.w	a2,a5
    800013ec:	85ba                	mv	a1,a4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	e6c080e7          	jalr	-404(ra) # 8000125a <uvmunmap>
    800013f6:	b7c5                	j	800013d6 <uvmdealloc+0x26>

00000000800013f8 <uvmalloc>:
  if(newsz < oldsz)
    800013f8:	0ab66163          	bltu	a2,a1,8000149a <uvmalloc+0xa2>
{
    800013fc:	7139                	addi	sp,sp,-64
    800013fe:	fc06                	sd	ra,56(sp)
    80001400:	f822                	sd	s0,48(sp)
    80001402:	f426                	sd	s1,40(sp)
    80001404:	f04a                	sd	s2,32(sp)
    80001406:	ec4e                	sd	s3,24(sp)
    80001408:	e852                	sd	s4,16(sp)
    8000140a:	e456                	sd	s5,8(sp)
    8000140c:	0080                	addi	s0,sp,64
    8000140e:	8aaa                	mv	s5,a0
    80001410:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001412:	6985                	lui	s3,0x1
    80001414:	19fd                	addi	s3,s3,-1
    80001416:	95ce                	add	a1,a1,s3
    80001418:	79fd                	lui	s3,0xfffff
    8000141a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000141e:	08c9f063          	bgeu	s3,a2,8000149e <uvmalloc+0xa6>
    80001422:	894e                	mv	s2,s3
    mem = kalloc();
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	6c2080e7          	jalr	1730(ra) # 80000ae6 <kalloc>
    8000142c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000142e:	c51d                	beqz	a0,8000145c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001430:	6605                	lui	a2,0x1
    80001432:	4581                	li	a1,0
    80001434:	00000097          	auipc	ra,0x0
    80001438:	89e080e7          	jalr	-1890(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000143c:	4779                	li	a4,30
    8000143e:	86a6                	mv	a3,s1
    80001440:	6605                	lui	a2,0x1
    80001442:	85ca                	mv	a1,s2
    80001444:	8556                	mv	a0,s5
    80001446:	00000097          	auipc	ra,0x0
    8000144a:	c60080e7          	jalr	-928(ra) # 800010a6 <mappages>
    8000144e:	e905                	bnez	a0,8000147e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001450:	6785                	lui	a5,0x1
    80001452:	993e                	add	s2,s2,a5
    80001454:	fd4968e3          	bltu	s2,s4,80001424 <uvmalloc+0x2c>
  return newsz;
    80001458:	8552                	mv	a0,s4
    8000145a:	a809                	j	8000146c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000145c:	864e                	mv	a2,s3
    8000145e:	85ca                	mv	a1,s2
    80001460:	8556                	mv	a0,s5
    80001462:	00000097          	auipc	ra,0x0
    80001466:	f4e080e7          	jalr	-178(ra) # 800013b0 <uvmdealloc>
      return 0;
    8000146a:	4501                	li	a0,0
}
    8000146c:	70e2                	ld	ra,56(sp)
    8000146e:	7442                	ld	s0,48(sp)
    80001470:	74a2                	ld	s1,40(sp)
    80001472:	7902                	ld	s2,32(sp)
    80001474:	69e2                	ld	s3,24(sp)
    80001476:	6a42                	ld	s4,16(sp)
    80001478:	6aa2                	ld	s5,8(sp)
    8000147a:	6121                	addi	sp,sp,64
    8000147c:	8082                	ret
      kfree(mem);
    8000147e:	8526                	mv	a0,s1
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	56a080e7          	jalr	1386(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001488:	864e                	mv	a2,s3
    8000148a:	85ca                	mv	a1,s2
    8000148c:	8556                	mv	a0,s5
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	f22080e7          	jalr	-222(ra) # 800013b0 <uvmdealloc>
      return 0;
    80001496:	4501                	li	a0,0
    80001498:	bfd1                	j	8000146c <uvmalloc+0x74>
    return oldsz;
    8000149a:	852e                	mv	a0,a1
}
    8000149c:	8082                	ret
  return newsz;
    8000149e:	8532                	mv	a0,a2
    800014a0:	b7f1                	j	8000146c <uvmalloc+0x74>

00000000800014a2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a2:	7179                	addi	sp,sp,-48
    800014a4:	f406                	sd	ra,40(sp)
    800014a6:	f022                	sd	s0,32(sp)
    800014a8:	ec26                	sd	s1,24(sp)
    800014aa:	e84a                	sd	s2,16(sp)
    800014ac:	e44e                	sd	s3,8(sp)
    800014ae:	e052                	sd	s4,0(sp)
    800014b0:	1800                	addi	s0,sp,48
    800014b2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014b4:	84aa                	mv	s1,a0
    800014b6:	6905                	lui	s2,0x1
    800014b8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014ba:	4985                	li	s3,1
    800014bc:	a821                	j	800014d4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014be:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014c0:	0532                	slli	a0,a0,0xc
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	fe0080e7          	jalr	-32(ra) # 800014a2 <freewalk>
      pagetable[i] = 0;
    800014ca:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ce:	04a1                	addi	s1,s1,8
    800014d0:	03248163          	beq	s1,s2,800014f2 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014d4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014d6:	00f57793          	andi	a5,a0,15
    800014da:	ff3782e3          	beq	a5,s3,800014be <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014de:	8905                	andi	a0,a0,1
    800014e0:	d57d                	beqz	a0,800014ce <freewalk+0x2c>
      panic("freewalk: leaf");
    800014e2:	00007517          	auipc	a0,0x7
    800014e6:	c6650513          	addi	a0,a0,-922 # 80008148 <digits+0x108>
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	046080e7          	jalr	70(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    800014f2:	8552                	mv	a0,s4
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	4f6080e7          	jalr	1270(ra) # 800009ea <kfree>
}
    800014fc:	70a2                	ld	ra,40(sp)
    800014fe:	7402                	ld	s0,32(sp)
    80001500:	64e2                	ld	s1,24(sp)
    80001502:	6942                	ld	s2,16(sp)
    80001504:	69a2                	ld	s3,8(sp)
    80001506:	6a02                	ld	s4,0(sp)
    80001508:	6145                	addi	sp,sp,48
    8000150a:	8082                	ret

000000008000150c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000150c:	1101                	addi	sp,sp,-32
    8000150e:	ec06                	sd	ra,24(sp)
    80001510:	e822                	sd	s0,16(sp)
    80001512:	e426                	sd	s1,8(sp)
    80001514:	1000                	addi	s0,sp,32
    80001516:	84aa                	mv	s1,a0
  if(sz > 0)
    80001518:	e999                	bnez	a1,8000152e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000151a:	8526                	mv	a0,s1
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	f86080e7          	jalr	-122(ra) # 800014a2 <freewalk>
}
    80001524:	60e2                	ld	ra,24(sp)
    80001526:	6442                	ld	s0,16(sp)
    80001528:	64a2                	ld	s1,8(sp)
    8000152a:	6105                	addi	sp,sp,32
    8000152c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000152e:	6605                	lui	a2,0x1
    80001530:	167d                	addi	a2,a2,-1
    80001532:	962e                	add	a2,a2,a1
    80001534:	4685                	li	a3,1
    80001536:	8231                	srli	a2,a2,0xc
    80001538:	4581                	li	a1,0
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	d20080e7          	jalr	-736(ra) # 8000125a <uvmunmap>
    80001542:	bfe1                	j	8000151a <uvmfree+0xe>

0000000080001544 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001544:	c269                	beqz	a2,80001606 <uvmcopy+0xc2>
{
    80001546:	715d                	addi	sp,sp,-80
    80001548:	e486                	sd	ra,72(sp)
    8000154a:	e0a2                	sd	s0,64(sp)
    8000154c:	fc26                	sd	s1,56(sp)
    8000154e:	f84a                	sd	s2,48(sp)
    80001550:	f44e                	sd	s3,40(sp)
    80001552:	f052                	sd	s4,32(sp)
    80001554:	ec56                	sd	s5,24(sp)
    80001556:	e85a                	sd	s6,16(sp)
    80001558:	e45e                	sd	s7,8(sp)
    8000155a:	0880                	addi	s0,sp,80
    8000155c:	8aaa                	mv	s5,a0
    8000155e:	8b2e                	mv	s6,a1
    80001560:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001562:	4481                	li	s1,0
    80001564:	a829                	j	8000157e <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    80001566:	00007517          	auipc	a0,0x7
    8000156a:	bf250513          	addi	a0,a0,-1038 # 80008158 <digits+0x118>
    8000156e:	fffff097          	auipc	ra,0xfffff
    80001572:	fc2080e7          	jalr	-62(ra) # 80000530 <panic>
  for(i = 0; i < sz; i += PGSIZE){
    80001576:	6785                	lui	a5,0x1
    80001578:	94be                	add	s1,s1,a5
    8000157a:	0944f463          	bgeu	s1,s4,80001602 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    8000157e:	4601                	li	a2,0
    80001580:	85a6                	mv	a1,s1
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	a3a080e7          	jalr	-1478(ra) # 80000fbe <walk>
    8000158c:	dd69                	beqz	a0,80001566 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    8000158e:	6118                	ld	a4,0(a0)
    80001590:	00177793          	andi	a5,a4,1
    80001594:	d3ed                	beqz	a5,80001576 <uvmcopy+0x32>
      //panic("uvmcopy: page not present");
      continue;
    pa = PTE2PA(*pte);
    80001596:	00a75593          	srli	a1,a4,0xa
    8000159a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000159e:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	544080e7          	jalr	1348(ra) # 80000ae6 <kalloc>
    800015aa:	89aa                	mv	s3,a0
    800015ac:	c515                	beqz	a0,800015d8 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	85de                	mv	a1,s7
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	780080e7          	jalr	1920(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ba:	874a                	mv	a4,s2
    800015bc:	86ce                	mv	a3,s3
    800015be:	6605                	lui	a2,0x1
    800015c0:	85a6                	mv	a1,s1
    800015c2:	855a                	mv	a0,s6
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	ae2080e7          	jalr	-1310(ra) # 800010a6 <mappages>
    800015cc:	d54d                	beqz	a0,80001576 <uvmcopy+0x32>
      kfree(mem);
    800015ce:	854e                	mv	a0,s3
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	41a080e7          	jalr	1050(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015d8:	4685                	li	a3,1
    800015da:	00c4d613          	srli	a2,s1,0xc
    800015de:	4581                	li	a1,0
    800015e0:	855a                	mv	a0,s6
    800015e2:	00000097          	auipc	ra,0x0
    800015e6:	c78080e7          	jalr	-904(ra) # 8000125a <uvmunmap>
  return -1;
    800015ea:	557d                	li	a0,-1
}
    800015ec:	60a6                	ld	ra,72(sp)
    800015ee:	6406                	ld	s0,64(sp)
    800015f0:	74e2                	ld	s1,56(sp)
    800015f2:	7942                	ld	s2,48(sp)
    800015f4:	79a2                	ld	s3,40(sp)
    800015f6:	7a02                	ld	s4,32(sp)
    800015f8:	6ae2                	ld	s5,24(sp)
    800015fa:	6b42                	ld	s6,16(sp)
    800015fc:	6ba2                	ld	s7,8(sp)
    800015fe:	6161                	addi	sp,sp,80
    80001600:	8082                	ret
  return 0;
    80001602:	4501                	li	a0,0
    80001604:	b7e5                	j	800015ec <uvmcopy+0xa8>
    80001606:	4501                	li	a0,0
}
    80001608:	8082                	ret

000000008000160a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160a:	1141                	addi	sp,sp,-16
    8000160c:	e406                	sd	ra,8(sp)
    8000160e:	e022                	sd	s0,0(sp)
    80001610:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001612:	4601                	li	a2,0
    80001614:	00000097          	auipc	ra,0x0
    80001618:	9aa080e7          	jalr	-1622(ra) # 80000fbe <walk>
  if(pte == 0)
    8000161c:	c901                	beqz	a0,8000162c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000161e:	611c                	ld	a5,0(a0)
    80001620:	9bbd                	andi	a5,a5,-17
    80001622:	e11c                	sd	a5,0(a0)
}
    80001624:	60a2                	ld	ra,8(sp)
    80001626:	6402                	ld	s0,0(sp)
    80001628:	0141                	addi	sp,sp,16
    8000162a:	8082                	ret
    panic("uvmclear");
    8000162c:	00007517          	auipc	a0,0x7
    80001630:	b4c50513          	addi	a0,a0,-1204 # 80008178 <digits+0x138>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	efc080e7          	jalr	-260(ra) # 80000530 <panic>

000000008000163c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163c:	c6bd                	beqz	a3,800016aa <copyout+0x6e>
{
    8000163e:	715d                	addi	sp,sp,-80
    80001640:	e486                	sd	ra,72(sp)
    80001642:	e0a2                	sd	s0,64(sp)
    80001644:	fc26                	sd	s1,56(sp)
    80001646:	f84a                	sd	s2,48(sp)
    80001648:	f44e                	sd	s3,40(sp)
    8000164a:	f052                	sd	s4,32(sp)
    8000164c:	ec56                	sd	s5,24(sp)
    8000164e:	e85a                	sd	s6,16(sp)
    80001650:	e45e                	sd	s7,8(sp)
    80001652:	e062                	sd	s8,0(sp)
    80001654:	0880                	addi	s0,sp,80
    80001656:	8b2a                	mv	s6,a0
    80001658:	8c2e                	mv	s8,a1
    8000165a:	8a32                	mv	s4,a2
    8000165c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000165e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001660:	6a85                	lui	s5,0x1
    80001662:	a015                	j	80001686 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001664:	9562                	add	a0,a0,s8
    80001666:	0004861b          	sext.w	a2,s1
    8000166a:	85d2                	mv	a1,s4
    8000166c:	41250533          	sub	a0,a0,s2
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	6c2080e7          	jalr	1730(ra) # 80000d32 <memmove>

    len -= n;
    80001678:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000167e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001682:	02098263          	beqz	s3,800016a6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001686:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168a:	85ca                	mv	a1,s2
    8000168c:	855a                	mv	a0,s6
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	9d6080e7          	jalr	-1578(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001696:	cd01                	beqz	a0,800016ae <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001698:	418904b3          	sub	s1,s2,s8
    8000169c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000169e:	fc99f3e3          	bgeu	s3,s1,80001664 <copyout+0x28>
    800016a2:	84ce                	mv	s1,s3
    800016a4:	b7c1                	j	80001664 <copyout+0x28>
  }
  return 0;
    800016a6:	4501                	li	a0,0
    800016a8:	a021                	j	800016b0 <copyout+0x74>
    800016aa:	4501                	li	a0,0
}
    800016ac:	8082                	ret
      return -1;
    800016ae:	557d                	li	a0,-1
}
    800016b0:	60a6                	ld	ra,72(sp)
    800016b2:	6406                	ld	s0,64(sp)
    800016b4:	74e2                	ld	s1,56(sp)
    800016b6:	7942                	ld	s2,48(sp)
    800016b8:	79a2                	ld	s3,40(sp)
    800016ba:	7a02                	ld	s4,32(sp)
    800016bc:	6ae2                	ld	s5,24(sp)
    800016be:	6b42                	ld	s6,16(sp)
    800016c0:	6ba2                	ld	s7,8(sp)
    800016c2:	6c02                	ld	s8,0(sp)
    800016c4:	6161                	addi	sp,sp,80
    800016c6:	8082                	ret

00000000800016c8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c8:	c6bd                	beqz	a3,80001736 <copyin+0x6e>
{
    800016ca:	715d                	addi	sp,sp,-80
    800016cc:	e486                	sd	ra,72(sp)
    800016ce:	e0a2                	sd	s0,64(sp)
    800016d0:	fc26                	sd	s1,56(sp)
    800016d2:	f84a                	sd	s2,48(sp)
    800016d4:	f44e                	sd	s3,40(sp)
    800016d6:	f052                	sd	s4,32(sp)
    800016d8:	ec56                	sd	s5,24(sp)
    800016da:	e85a                	sd	s6,16(sp)
    800016dc:	e45e                	sd	s7,8(sp)
    800016de:	e062                	sd	s8,0(sp)
    800016e0:	0880                	addi	s0,sp,80
    800016e2:	8b2a                	mv	s6,a0
    800016e4:	8a2e                	mv	s4,a1
    800016e6:	8c32                	mv	s8,a2
    800016e8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ea:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ec:	6a85                	lui	s5,0x1
    800016ee:	a015                	j	80001712 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f0:	9562                	add	a0,a0,s8
    800016f2:	0004861b          	sext.w	a2,s1
    800016f6:	412505b3          	sub	a1,a0,s2
    800016fa:	8552                	mv	a0,s4
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	636080e7          	jalr	1590(ra) # 80000d32 <memmove>

    len -= n;
    80001704:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001708:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000170e:	02098263          	beqz	s3,80001732 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001712:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001716:	85ca                	mv	a1,s2
    80001718:	855a                	mv	a0,s6
    8000171a:	00000097          	auipc	ra,0x0
    8000171e:	94a080e7          	jalr	-1718(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    80001722:	cd01                	beqz	a0,8000173a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001724:	418904b3          	sub	s1,s2,s8
    80001728:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172a:	fc99f3e3          	bgeu	s3,s1,800016f0 <copyin+0x28>
    8000172e:	84ce                	mv	s1,s3
    80001730:	b7c1                	j	800016f0 <copyin+0x28>
  }
  return 0;
    80001732:	4501                	li	a0,0
    80001734:	a021                	j	8000173c <copyin+0x74>
    80001736:	4501                	li	a0,0
}
    80001738:	8082                	ret
      return -1;
    8000173a:	557d                	li	a0,-1
}
    8000173c:	60a6                	ld	ra,72(sp)
    8000173e:	6406                	ld	s0,64(sp)
    80001740:	74e2                	ld	s1,56(sp)
    80001742:	7942                	ld	s2,48(sp)
    80001744:	79a2                	ld	s3,40(sp)
    80001746:	7a02                	ld	s4,32(sp)
    80001748:	6ae2                	ld	s5,24(sp)
    8000174a:	6b42                	ld	s6,16(sp)
    8000174c:	6ba2                	ld	s7,8(sp)
    8000174e:	6c02                	ld	s8,0(sp)
    80001750:	6161                	addi	sp,sp,80
    80001752:	8082                	ret

0000000080001754 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001754:	c6c5                	beqz	a3,800017fc <copyinstr+0xa8>
{
    80001756:	715d                	addi	sp,sp,-80
    80001758:	e486                	sd	ra,72(sp)
    8000175a:	e0a2                	sd	s0,64(sp)
    8000175c:	fc26                	sd	s1,56(sp)
    8000175e:	f84a                	sd	s2,48(sp)
    80001760:	f44e                	sd	s3,40(sp)
    80001762:	f052                	sd	s4,32(sp)
    80001764:	ec56                	sd	s5,24(sp)
    80001766:	e85a                	sd	s6,16(sp)
    80001768:	e45e                	sd	s7,8(sp)
    8000176a:	0880                	addi	s0,sp,80
    8000176c:	8a2a                	mv	s4,a0
    8000176e:	8b2e                	mv	s6,a1
    80001770:	8bb2                	mv	s7,a2
    80001772:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001774:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001776:	6985                	lui	s3,0x1
    80001778:	a035                	j	800017a4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000177e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001780:	0017b793          	seqz	a5,a5
    80001784:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001788:	60a6                	ld	ra,72(sp)
    8000178a:	6406                	ld	s0,64(sp)
    8000178c:	74e2                	ld	s1,56(sp)
    8000178e:	7942                	ld	s2,48(sp)
    80001790:	79a2                	ld	s3,40(sp)
    80001792:	7a02                	ld	s4,32(sp)
    80001794:	6ae2                	ld	s5,24(sp)
    80001796:	6b42                	ld	s6,16(sp)
    80001798:	6ba2                	ld	s7,8(sp)
    8000179a:	6161                	addi	sp,sp,80
    8000179c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000179e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a2:	c8a9                	beqz	s1,800017f4 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017a8:	85ca                	mv	a1,s2
    800017aa:	8552                	mv	a0,s4
    800017ac:	00000097          	auipc	ra,0x0
    800017b0:	8b8080e7          	jalr	-1864(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017b4:	c131                	beqz	a0,800017f8 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017b6:	41790833          	sub	a6,s2,s7
    800017ba:	984e                	add	a6,a6,s3
    if(n > max)
    800017bc:	0104f363          	bgeu	s1,a6,800017c2 <copyinstr+0x6e>
    800017c0:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c2:	955e                	add	a0,a0,s7
    800017c4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017c8:	fc080be3          	beqz	a6,8000179e <copyinstr+0x4a>
    800017cc:	985a                	add	a6,a6,s6
    800017ce:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d0:	41650633          	sub	a2,a0,s6
    800017d4:	14fd                	addi	s1,s1,-1
    800017d6:	9b26                	add	s6,s6,s1
    800017d8:	00f60733          	add	a4,a2,a5
    800017dc:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffcd000>
    800017e0:	df49                	beqz	a4,8000177a <copyinstr+0x26>
        *dst = *p;
    800017e2:	00e78023          	sb	a4,0(a5)
      --max;
    800017e6:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ea:	0785                	addi	a5,a5,1
    while(n > 0){
    800017ec:	ff0796e3          	bne	a5,a6,800017d8 <copyinstr+0x84>
      dst++;
    800017f0:	8b42                	mv	s6,a6
    800017f2:	b775                	j	8000179e <copyinstr+0x4a>
    800017f4:	4781                	li	a5,0
    800017f6:	b769                	j	80001780 <copyinstr+0x2c>
      return -1;
    800017f8:	557d                	li	a0,-1
    800017fa:	b779                	j	80001788 <copyinstr+0x34>
  int got_null = 0;
    800017fc:	4781                	li	a5,0
  if(got_null){
    800017fe:	0017b793          	seqz	a5,a5
    80001802:	40f00533          	neg	a0,a5
}
    80001806:	8082                	ret

0000000080001808 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001808:	1101                	addi	sp,sp,-32
    8000180a:	ec06                	sd	ra,24(sp)
    8000180c:	e822                	sd	s0,16(sp)
    8000180e:	e426                	sd	s1,8(sp)
    80001810:	1000                	addi	s0,sp,32
    80001812:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	348080e7          	jalr	840(ra) # 80000b5c <holding>
    8000181c:	c909                	beqz	a0,8000182e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000181e:	749c                	ld	a5,40(s1)
    80001820:	00978f63          	beq	a5,s1,8000183e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001824:	60e2                	ld	ra,24(sp)
    80001826:	6442                	ld	s0,16(sp)
    80001828:	64a2                	ld	s1,8(sp)
    8000182a:	6105                	addi	sp,sp,32
    8000182c:	8082                	ret
    panic("wakeup1");
    8000182e:	00007517          	auipc	a0,0x7
    80001832:	95a50513          	addi	a0,a0,-1702 # 80008188 <digits+0x148>
    80001836:	fffff097          	auipc	ra,0xfffff
    8000183a:	cfa080e7          	jalr	-774(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000183e:	4c98                	lw	a4,24(s1)
    80001840:	4785                	li	a5,1
    80001842:	fef711e3          	bne	a4,a5,80001824 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001846:	4789                	li	a5,2
    80001848:	cc9c                	sw	a5,24(s1)
}
    8000184a:	bfe9                	j	80001824 <wakeup1+0x1c>

000000008000184c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000184c:	7139                	addi	sp,sp,-64
    8000184e:	fc06                	sd	ra,56(sp)
    80001850:	f822                	sd	s0,48(sp)
    80001852:	f426                	sd	s1,40(sp)
    80001854:	f04a                	sd	s2,32(sp)
    80001856:	ec4e                	sd	s3,24(sp)
    80001858:	e852                	sd	s4,16(sp)
    8000185a:	e456                	sd	s5,8(sp)
    8000185c:	e05a                	sd	s6,0(sp)
    8000185e:	0080                	addi	s0,sp,64
    80001860:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001862:	00010497          	auipc	s1,0x10
    80001866:	e5648493          	addi	s1,s1,-426 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000186a:	8b26                	mv	s6,s1
    8000186c:	00006a97          	auipc	s5,0x6
    80001870:	794a8a93          	addi	s5,s5,1940 # 80008000 <etext>
    80001874:	04000937          	lui	s2,0x4000
    80001878:	197d                	addi	s2,s2,-1
    8000187a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187c:	00022a17          	auipc	s4,0x22
    80001880:	83ca0a13          	addi	s4,s4,-1988 # 800230b8 <tickslock>
    char *pa = kalloc();
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	262080e7          	jalr	610(ra) # 80000ae6 <kalloc>
    8000188c:	862a                	mv	a2,a0
    if(pa == 0)
    8000188e:	c131                	beqz	a0,800018d2 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001890:	416485b3          	sub	a1,s1,s6
    80001894:	858d                	srai	a1,a1,0x3
    80001896:	000ab783          	ld	a5,0(s5)
    8000189a:	02f585b3          	mul	a1,a1,a5
    8000189e:	2585                	addiw	a1,a1,1
    800018a0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a4:	4719                	li	a4,6
    800018a6:	6685                	lui	a3,0x1
    800018a8:	40b905b3          	sub	a1,s2,a1
    800018ac:	854e                	mv	a0,s3
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	886080e7          	jalr	-1914(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b6:	46848493          	addi	s1,s1,1128
    800018ba:	fd4495e3          	bne	s1,s4,80001884 <proc_mapstacks+0x38>
}
    800018be:	70e2                	ld	ra,56(sp)
    800018c0:	7442                	ld	s0,48(sp)
    800018c2:	74a2                	ld	s1,40(sp)
    800018c4:	7902                	ld	s2,32(sp)
    800018c6:	69e2                	ld	s3,24(sp)
    800018c8:	6a42                	ld	s4,16(sp)
    800018ca:	6aa2                	ld	s5,8(sp)
    800018cc:	6b02                	ld	s6,0(sp)
    800018ce:	6121                	addi	sp,sp,64
    800018d0:	8082                	ret
      panic("kalloc");
    800018d2:	00007517          	auipc	a0,0x7
    800018d6:	8be50513          	addi	a0,a0,-1858 # 80008190 <digits+0x150>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	c56080e7          	jalr	-938(ra) # 80000530 <panic>

00000000800018e2 <procinit>:
{
    800018e2:	7139                	addi	sp,sp,-64
    800018e4:	fc06                	sd	ra,56(sp)
    800018e6:	f822                	sd	s0,48(sp)
    800018e8:	f426                	sd	s1,40(sp)
    800018ea:	f04a                	sd	s2,32(sp)
    800018ec:	ec4e                	sd	s3,24(sp)
    800018ee:	e852                	sd	s4,16(sp)
    800018f0:	e456                	sd	s5,8(sp)
    800018f2:	e05a                	sd	s6,0(sp)
    800018f4:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    800018f6:	00007597          	auipc	a1,0x7
    800018fa:	8a258593          	addi	a1,a1,-1886 # 80008198 <digits+0x158>
    800018fe:	00010517          	auipc	a0,0x10
    80001902:	9a250513          	addi	a0,a0,-1630 # 800112a0 <pid_lock>
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	240080e7          	jalr	576(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190e:	00010497          	auipc	s1,0x10
    80001912:	daa48493          	addi	s1,s1,-598 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    80001916:	00007b17          	auipc	s6,0x7
    8000191a:	88ab0b13          	addi	s6,s6,-1910 # 800081a0 <digits+0x160>
      p->kstack = KSTACK((int) (p - proc));
    8000191e:	8aa6                	mv	s5,s1
    80001920:	00006a17          	auipc	s4,0x6
    80001924:	6e0a0a13          	addi	s4,s4,1760 # 80008000 <etext>
    80001928:	04000937          	lui	s2,0x4000
    8000192c:	197d                	addi	s2,s2,-1
    8000192e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001930:	00021997          	auipc	s3,0x21
    80001934:	78898993          	addi	s3,s3,1928 # 800230b8 <tickslock>
      initlock(&p->lock, "proc");
    80001938:	85da                	mv	a1,s6
    8000193a:	8526                	mv	a0,s1
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	20a080e7          	jalr	522(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001944:	415487b3          	sub	a5,s1,s5
    80001948:	878d                	srai	a5,a5,0x3
    8000194a:	000a3703          	ld	a4,0(s4)
    8000194e:	02e787b3          	mul	a5,a5,a4
    80001952:	2785                	addiw	a5,a5,1
    80001954:	00d7979b          	slliw	a5,a5,0xd
    80001958:	40f907b3          	sub	a5,s2,a5
    8000195c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195e:	46848493          	addi	s1,s1,1128
    80001962:	fd349be3          	bne	s1,s3,80001938 <procinit+0x56>
}
    80001966:	70e2                	ld	ra,56(sp)
    80001968:	7442                	ld	s0,48(sp)
    8000196a:	74a2                	ld	s1,40(sp)
    8000196c:	7902                	ld	s2,32(sp)
    8000196e:	69e2                	ld	s3,24(sp)
    80001970:	6a42                	ld	s4,16(sp)
    80001972:	6aa2                	ld	s5,8(sp)
    80001974:	6b02                	ld	s6,0(sp)
    80001976:	6121                	addi	sp,sp,64
    80001978:	8082                	ret

000000008000197a <cpuid>:
{
    8000197a:	1141                	addi	sp,sp,-16
    8000197c:	e422                	sd	s0,8(sp)
    8000197e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001980:	8512                	mv	a0,tp
}
    80001982:	2501                	sext.w	a0,a0
    80001984:	6422                	ld	s0,8(sp)
    80001986:	0141                	addi	sp,sp,16
    80001988:	8082                	ret

000000008000198a <mycpu>:
mycpu(void) {
    8000198a:	1141                	addi	sp,sp,-16
    8000198c:	e422                	sd	s0,8(sp)
    8000198e:	0800                	addi	s0,sp,16
    80001990:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001992:	2781                	sext.w	a5,a5
    80001994:	079e                	slli	a5,a5,0x7
}
    80001996:	00010517          	auipc	a0,0x10
    8000199a:	92250513          	addi	a0,a0,-1758 # 800112b8 <cpus>
    8000199e:	953e                	add	a0,a0,a5
    800019a0:	6422                	ld	s0,8(sp)
    800019a2:	0141                	addi	sp,sp,16
    800019a4:	8082                	ret

00000000800019a6 <myproc>:
myproc(void) {
    800019a6:	1101                	addi	sp,sp,-32
    800019a8:	ec06                	sd	ra,24(sp)
    800019aa:	e822                	sd	s0,16(sp)
    800019ac:	e426                	sd	s1,8(sp)
    800019ae:	1000                	addi	s0,sp,32
  push_off();
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1da080e7          	jalr	474(ra) # 80000b8a <push_off>
    800019b8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019ba:	2781                	sext.w	a5,a5
    800019bc:	079e                	slli	a5,a5,0x7
    800019be:	00010717          	auipc	a4,0x10
    800019c2:	8e270713          	addi	a4,a4,-1822 # 800112a0 <pid_lock>
    800019c6:	97ba                	add	a5,a5,a4
    800019c8:	6f84                	ld	s1,24(a5)
  pop_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	260080e7          	jalr	608(ra) # 80000c2a <pop_off>
}
    800019d2:	8526                	mv	a0,s1
    800019d4:	60e2                	ld	ra,24(sp)
    800019d6:	6442                	ld	s0,16(sp)
    800019d8:	64a2                	ld	s1,8(sp)
    800019da:	6105                	addi	sp,sp,32
    800019dc:	8082                	ret

00000000800019de <forkret>:
{
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e406                	sd	ra,8(sp)
    800019e2:	e022                	sd	s0,0(sp)
    800019e4:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	fc0080e7          	jalr	-64(ra) # 800019a6 <myproc>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	29c080e7          	jalr	668(ra) # 80000c8a <release>
  if (first) {
    800019f6:	00007797          	auipc	a5,0x7
    800019fa:	dca7a783          	lw	a5,-566(a5) # 800087c0 <first.1688>
    800019fe:	eb89                	bnez	a5,80001a10 <forkret+0x32>
  usertrapret();
    80001a00:	00001097          	auipc	ra,0x1
    80001a04:	cc0080e7          	jalr	-832(ra) # 800026c0 <usertrapret>
}
    80001a08:	60a2                	ld	ra,8(sp)
    80001a0a:	6402                	ld	s0,0(sp)
    80001a0c:	0141                	addi	sp,sp,16
    80001a0e:	8082                	ret
    first = 0;
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	da07a823          	sw	zero,-592(a5) # 800087c0 <first.1688>
    fsinit(ROOTDEV);
    80001a18:	4505                	li	a0,1
    80001a1a:	00002097          	auipc	ra,0x2
    80001a1e:	b24080e7          	jalr	-1244(ra) # 8000353e <fsinit>
    80001a22:	bff9                	j	80001a00 <forkret+0x22>

0000000080001a24 <allocpid>:
allocpid() {
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	e04a                	sd	s2,0(sp)
    80001a2e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a30:	00010917          	auipc	s2,0x10
    80001a34:	87090913          	addi	s2,s2,-1936 # 800112a0 <pid_lock>
    80001a38:	854a                	mv	a0,s2
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	19c080e7          	jalr	412(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	d8278793          	addi	a5,a5,-638 # 800087c4 <nextpid>
    80001a4a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a4c:	0014871b          	addiw	a4,s1,1
    80001a50:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	236080e7          	jalr	566(ra) # 80000c8a <release>
}
    80001a5c:	8526                	mv	a0,s1
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret

0000000080001a6a <proc_pagetable>:
{
    80001a6a:	1101                	addi	sp,sp,-32
    80001a6c:	ec06                	sd	ra,24(sp)
    80001a6e:	e822                	sd	s0,16(sp)
    80001a70:	e426                	sd	s1,8(sp)
    80001a72:	e04a                	sd	s2,0(sp)
    80001a74:	1000                	addi	s0,sp,32
    80001a76:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	898080e7          	jalr	-1896(ra) # 80001310 <uvmcreate>
    80001a80:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a82:	c121                	beqz	a0,80001ac2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a84:	4729                	li	a4,10
    80001a86:	00005697          	auipc	a3,0x5
    80001a8a:	57a68693          	addi	a3,a3,1402 # 80007000 <_trampoline>
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	040005b7          	lui	a1,0x4000
    80001a94:	15fd                	addi	a1,a1,-1
    80001a96:	05b2                	slli	a1,a1,0xc
    80001a98:	fffff097          	auipc	ra,0xfffff
    80001a9c:	60e080e7          	jalr	1550(ra) # 800010a6 <mappages>
    80001aa0:	02054863          	bltz	a0,80001ad0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aa4:	4719                	li	a4,6
    80001aa6:	05893683          	ld	a3,88(s2)
    80001aaa:	6605                	lui	a2,0x1
    80001aac:	020005b7          	lui	a1,0x2000
    80001ab0:	15fd                	addi	a1,a1,-1
    80001ab2:	05b6                	slli	a1,a1,0xd
    80001ab4:	8526                	mv	a0,s1
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	5f0080e7          	jalr	1520(ra) # 800010a6 <mappages>
    80001abe:	02054163          	bltz	a0,80001ae0 <proc_pagetable+0x76>
}
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	60e2                	ld	ra,24(sp)
    80001ac6:	6442                	ld	s0,16(sp)
    80001ac8:	64a2                	ld	s1,8(sp)
    80001aca:	6902                	ld	s2,0(sp)
    80001acc:	6105                	addi	sp,sp,32
    80001ace:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad0:	4581                	li	a1,0
    80001ad2:	8526                	mv	a0,s1
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	a38080e7          	jalr	-1480(ra) # 8000150c <uvmfree>
    return 0;
    80001adc:	4481                	li	s1,0
    80001ade:	b7d5                	j	80001ac2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae0:	4681                	li	a3,0
    80001ae2:	4605                	li	a2,1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	8526                	mv	a0,s1
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	76c080e7          	jalr	1900(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a12080e7          	jalr	-1518(ra) # 8000150c <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	bf7d                	j	80001ac2 <proc_pagetable+0x58>

0000000080001b06 <proc_freepagetable>:
{
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	e04a                	sd	s2,0(sp)
    80001b10:	1000                	addi	s0,sp,32
    80001b12:	84aa                	mv	s1,a0
    80001b14:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b16:	4681                	li	a3,0
    80001b18:	4605                	li	a2,1
    80001b1a:	040005b7          	lui	a1,0x4000
    80001b1e:	15fd                	addi	a1,a1,-1
    80001b20:	05b2                	slli	a1,a1,0xc
    80001b22:	fffff097          	auipc	ra,0xfffff
    80001b26:	738080e7          	jalr	1848(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	020005b7          	lui	a1,0x2000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b6                	slli	a1,a1,0xd
    80001b36:	8526                	mv	a0,s1
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	722080e7          	jalr	1826(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b40:	85ca                	mv	a1,s2
    80001b42:	8526                	mv	a0,s1
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	9c8080e7          	jalr	-1592(ra) # 8000150c <uvmfree>
}
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <freeproc>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b64:	6d28                	ld	a0,88(a0)
    80001b66:	c509                	beqz	a0,80001b70 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	e82080e7          	jalr	-382(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b70:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b74:	68a8                	ld	a0,80(s1)
    80001b76:	c511                	beqz	a0,80001b82 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b78:	64ac                	ld	a1,72(s1)
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	f8c080e7          	jalr	-116(ra) # 80001b06 <proc_freepagetable>
  p->pagetable = 0;
    80001b82:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b86:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b8a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001b8e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001b92:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b96:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001b9a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001b9e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001ba2:	0004ac23          	sw	zero,24(s1)
}
    80001ba6:	60e2                	ld	ra,24(sp)
    80001ba8:	6442                	ld	s0,16(sp)
    80001baa:	64a2                	ld	s1,8(sp)
    80001bac:	6105                	addi	sp,sp,32
    80001bae:	8082                	ret

0000000080001bb0 <allocproc>:
{
    80001bb0:	1101                	addi	sp,sp,-32
    80001bb2:	ec06                	sd	ra,24(sp)
    80001bb4:	e822                	sd	s0,16(sp)
    80001bb6:	e426                	sd	s1,8(sp)
    80001bb8:	e04a                	sd	s2,0(sp)
    80001bba:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bbc:	00010497          	auipc	s1,0x10
    80001bc0:	afc48493          	addi	s1,s1,-1284 # 800116b8 <proc>
    80001bc4:	00021917          	auipc	s2,0x21
    80001bc8:	4f490913          	addi	s2,s2,1268 # 800230b8 <tickslock>
    acquire(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	008080e7          	jalr	8(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bd6:	4c9c                	lw	a5,24(s1)
    80001bd8:	cf81                	beqz	a5,80001bf0 <allocproc+0x40>
      release(&p->lock);
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	0ae080e7          	jalr	174(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be4:	46848493          	addi	s1,s1,1128
    80001be8:	ff2492e3          	bne	s1,s2,80001bcc <allocproc+0x1c>
  return 0;
    80001bec:	4481                	li	s1,0
    80001bee:	a0b9                	j	80001c3c <allocproc+0x8c>
  p->pid = allocpid();
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	e34080e7          	jalr	-460(ra) # 80001a24 <allocpid>
    80001bf8:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	eec080e7          	jalr	-276(ra) # 80000ae6 <kalloc>
    80001c02:	892a                	mv	s2,a0
    80001c04:	eca8                	sd	a0,88(s1)
    80001c06:	c131                	beqz	a0,80001c4a <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c08:	8526                	mv	a0,s1
    80001c0a:	00000097          	auipc	ra,0x0
    80001c0e:	e60080e7          	jalr	-416(ra) # 80001a6a <proc_pagetable>
    80001c12:	892a                	mv	s2,a0
    80001c14:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c16:	c129                	beqz	a0,80001c58 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c18:	07000613          	li	a2,112
    80001c1c:	4581                	li	a1,0
    80001c1e:	06048513          	addi	a0,s1,96
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	0b0080e7          	jalr	176(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c2a:	00000797          	auipc	a5,0x0
    80001c2e:	db478793          	addi	a5,a5,-588 # 800019de <forkret>
    80001c32:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c34:	60bc                	ld	a5,64(s1)
    80001c36:	6705                	lui	a4,0x1
    80001c38:	97ba                	add	a5,a5,a4
    80001c3a:	f4bc                	sd	a5,104(s1)
}
    80001c3c:	8526                	mv	a0,s1
    80001c3e:	60e2                	ld	ra,24(sp)
    80001c40:	6442                	ld	s0,16(sp)
    80001c42:	64a2                	ld	s1,8(sp)
    80001c44:	6902                	ld	s2,0(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret
    release(&p->lock);
    80001c4a:	8526                	mv	a0,s1
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	03e080e7          	jalr	62(ra) # 80000c8a <release>
    return 0;
    80001c54:	84ca                	mv	s1,s2
    80001c56:	b7dd                	j	80001c3c <allocproc+0x8c>
    freeproc(p);
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	efe080e7          	jalr	-258(ra) # 80001b58 <freeproc>
    release(&p->lock);
    80001c62:	8526                	mv	a0,s1
    80001c64:	fffff097          	auipc	ra,0xfffff
    80001c68:	026080e7          	jalr	38(ra) # 80000c8a <release>
    return 0;
    80001c6c:	84ca                	mv	s1,s2
    80001c6e:	b7f9                	j	80001c3c <allocproc+0x8c>

0000000080001c70 <userinit>:
{
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c7a:	00000097          	auipc	ra,0x0
    80001c7e:	f36080e7          	jalr	-202(ra) # 80001bb0 <allocproc>
    80001c82:	84aa                	mv	s1,a0
  initproc = p;
    80001c84:	00007797          	auipc	a5,0x7
    80001c88:	3aa7b223          	sd	a0,932(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001c8c:	03400613          	li	a2,52
    80001c90:	00007597          	auipc	a1,0x7
    80001c94:	b4058593          	addi	a1,a1,-1216 # 800087d0 <initcode>
    80001c98:	6928                	ld	a0,80(a0)
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	6a4080e7          	jalr	1700(ra) # 8000133e <uvminit>
  p->sz = PGSIZE;
    80001ca2:	6785                	lui	a5,0x1
    80001ca4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ca6:	6cb8                	ld	a4,88(s1)
    80001ca8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cac:	6cb8                	ld	a4,88(s1)
    80001cae:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cb0:	4641                	li	a2,16
    80001cb2:	00006597          	auipc	a1,0x6
    80001cb6:	4f658593          	addi	a1,a1,1270 # 800081a8 <digits+0x168>
    80001cba:	15848513          	addi	a0,s1,344
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	16a080e7          	jalr	362(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001cc6:	00006517          	auipc	a0,0x6
    80001cca:	4f250513          	addi	a0,a0,1266 # 800081b8 <digits+0x178>
    80001cce:	00002097          	auipc	ra,0x2
    80001cd2:	29e080e7          	jalr	670(ra) # 80003f6c <namei>
    80001cd6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cda:	4789                	li	a5,2
    80001cdc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	faa080e7          	jalr	-86(ra) # 80000c8a <release>
}
    80001ce8:	60e2                	ld	ra,24(sp)
    80001cea:	6442                	ld	s0,16(sp)
    80001cec:	64a2                	ld	s1,8(sp)
    80001cee:	6105                	addi	sp,sp,32
    80001cf0:	8082                	ret

0000000080001cf2 <growproc>:
{
    80001cf2:	1101                	addi	sp,sp,-32
    80001cf4:	ec06                	sd	ra,24(sp)
    80001cf6:	e822                	sd	s0,16(sp)
    80001cf8:	e426                	sd	s1,8(sp)
    80001cfa:	e04a                	sd	s2,0(sp)
    80001cfc:	1000                	addi	s0,sp,32
    80001cfe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d00:	00000097          	auipc	ra,0x0
    80001d04:	ca6080e7          	jalr	-858(ra) # 800019a6 <myproc>
    80001d08:	892a                	mv	s2,a0
  sz = p->sz;
    80001d0a:	652c                	ld	a1,72(a0)
    80001d0c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d10:	00904f63          	bgtz	s1,80001d2e <growproc+0x3c>
  } else if(n < 0){
    80001d14:	0204cc63          	bltz	s1,80001d4c <growproc+0x5a>
  p->sz = sz;
    80001d18:	1602                	slli	a2,a2,0x20
    80001d1a:	9201                	srli	a2,a2,0x20
    80001d1c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d20:	4501                	li	a0,0
}
    80001d22:	60e2                	ld	ra,24(sp)
    80001d24:	6442                	ld	s0,16(sp)
    80001d26:	64a2                	ld	s1,8(sp)
    80001d28:	6902                	ld	s2,0(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d2e:	9e25                	addw	a2,a2,s1
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	1582                	slli	a1,a1,0x20
    80001d36:	9181                	srli	a1,a1,0x20
    80001d38:	6928                	ld	a0,80(a0)
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	6be080e7          	jalr	1726(ra) # 800013f8 <uvmalloc>
    80001d42:	0005061b          	sext.w	a2,a0
    80001d46:	fa69                	bnez	a2,80001d18 <growproc+0x26>
      return -1;
    80001d48:	557d                	li	a0,-1
    80001d4a:	bfe1                	j	80001d22 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d4c:	9e25                	addw	a2,a2,s1
    80001d4e:	1602                	slli	a2,a2,0x20
    80001d50:	9201                	srli	a2,a2,0x20
    80001d52:	1582                	slli	a1,a1,0x20
    80001d54:	9181                	srli	a1,a1,0x20
    80001d56:	6928                	ld	a0,80(a0)
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	658080e7          	jalr	1624(ra) # 800013b0 <uvmdealloc>
    80001d60:	0005061b          	sext.w	a2,a0
    80001d64:	bf55                	j	80001d18 <growproc+0x26>

0000000080001d66 <fork>:
{
    80001d66:	7139                	addi	sp,sp,-64
    80001d68:	fc06                	sd	ra,56(sp)
    80001d6a:	f822                	sd	s0,48(sp)
    80001d6c:	f426                	sd	s1,40(sp)
    80001d6e:	f04a                	sd	s2,32(sp)
    80001d70:	ec4e                	sd	s3,24(sp)
    80001d72:	e852                	sd	s4,16(sp)
    80001d74:	e456                	sd	s5,8(sp)
    80001d76:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	c2e080e7          	jalr	-978(ra) # 800019a6 <myproc>
    80001d80:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	e2e080e7          	jalr	-466(ra) # 80001bb0 <allocproc>
    80001d8a:	12050163          	beqz	a0,80001eac <fork+0x146>
    80001d8e:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d90:	04893603          	ld	a2,72(s2)
    80001d94:	692c                	ld	a1,80(a0)
    80001d96:	05093503          	ld	a0,80(s2)
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	7aa080e7          	jalr	1962(ra) # 80001544 <uvmcopy>
    80001da2:	04054863          	bltz	a0,80001df2 <fork+0x8c>
  np->sz = p->sz;
    80001da6:	04893783          	ld	a5,72(s2)
    80001daa:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001dae:	032a3023          	sd	s2,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001db2:	05893683          	ld	a3,88(s2)
    80001db6:	87b6                	mv	a5,a3
    80001db8:	058a3703          	ld	a4,88(s4)
    80001dbc:	12068693          	addi	a3,a3,288
    80001dc0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc4:	6788                	ld	a0,8(a5)
    80001dc6:	6b8c                	ld	a1,16(a5)
    80001dc8:	6f90                	ld	a2,24(a5)
    80001dca:	01073023          	sd	a6,0(a4)
    80001dce:	e708                	sd	a0,8(a4)
    80001dd0:	eb0c                	sd	a1,16(a4)
    80001dd2:	ef10                	sd	a2,24(a4)
    80001dd4:	02078793          	addi	a5,a5,32
    80001dd8:	02070713          	addi	a4,a4,32
    80001ddc:	fed792e3          	bne	a5,a3,80001dc0 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001de0:	058a3783          	ld	a5,88(s4)
    80001de4:	0607b823          	sd	zero,112(a5)
    80001de8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dec:	15000993          	li	s3,336
    80001df0:	a03d                	j	80001e1e <fork+0xb8>
    freeproc(np);
    80001df2:	8552                	mv	a0,s4
    80001df4:	00000097          	auipc	ra,0x0
    80001df8:	d64080e7          	jalr	-668(ra) # 80001b58 <freeproc>
    release(&np->lock);
    80001dfc:	8552                	mv	a0,s4
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	e8c080e7          	jalr	-372(ra) # 80000c8a <release>
    return -1;
    80001e06:	5afd                	li	s5,-1
    80001e08:	a841                	j	80001e98 <fork+0x132>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e0a:	00003097          	auipc	ra,0x3
    80001e0e:	800080e7          	jalr	-2048(ra) # 8000460a <filedup>
    80001e12:	009a07b3          	add	a5,s4,s1
    80001e16:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e18:	04a1                	addi	s1,s1,8
    80001e1a:	01348763          	beq	s1,s3,80001e28 <fork+0xc2>
    if(p->ofile[i])
    80001e1e:	009907b3          	add	a5,s2,s1
    80001e22:	6388                	ld	a0,0(a5)
    80001e24:	f17d                	bnez	a0,80001e0a <fork+0xa4>
    80001e26:	bfcd                	j	80001e18 <fork+0xb2>
  np->cwd = idup(p->cwd);
    80001e28:	15093503          	ld	a0,336(s2)
    80001e2c:	00002097          	auipc	ra,0x2
    80001e30:	94c080e7          	jalr	-1716(ra) # 80003778 <idup>
    80001e34:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e38:	4641                	li	a2,16
    80001e3a:	15890593          	addi	a1,s2,344
    80001e3e:	158a0513          	addi	a0,s4,344
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	fe6080e7          	jalr	-26(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e4a:	038a2a83          	lw	s5,56(s4)
  np->state = RUNNABLE;
    80001e4e:	4789                	li	a5,2
    80001e50:	00fa2c23          	sw	a5,24(s4)
  for(int i = 0; i < VMASIZE; i++) {
    80001e54:	16890493          	addi	s1,s2,360
    80001e58:	168a0993          	addi	s3,s4,360
    80001e5c:	46890913          	addi	s2,s2,1128
    80001e60:	a025                	j	80001e88 <fork+0x122>
      memmove(&(np->vma[i]), &(p->vma[i]), sizeof(p->vma[i]));
    80001e62:	03000613          	li	a2,48
    80001e66:	85a6                	mv	a1,s1
    80001e68:	854e                	mv	a0,s3
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	ec8080e7          	jalr	-312(ra) # 80000d32 <memmove>
      filedup(p->vma[i].file);
    80001e72:	7488                	ld	a0,40(s1)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	796080e7          	jalr	1942(ra) # 8000460a <filedup>
  for(int i = 0; i < VMASIZE; i++) {
    80001e7c:	03048493          	addi	s1,s1,48
    80001e80:	03098993          	addi	s3,s3,48
    80001e84:	01248563          	beq	s1,s2,80001e8e <fork+0x128>
    if(p->vma[i].used){
    80001e88:	409c                	lw	a5,0(s1)
    80001e8a:	dbed                	beqz	a5,80001e7c <fork+0x116>
    80001e8c:	bfd9                	j	80001e62 <fork+0xfc>
  release(&np->lock);
    80001e8e:	8552                	mv	a0,s4
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
}
    80001e98:	8556                	mv	a0,s5
    80001e9a:	70e2                	ld	ra,56(sp)
    80001e9c:	7442                	ld	s0,48(sp)
    80001e9e:	74a2                	ld	s1,40(sp)
    80001ea0:	7902                	ld	s2,32(sp)
    80001ea2:	69e2                	ld	s3,24(sp)
    80001ea4:	6a42                	ld	s4,16(sp)
    80001ea6:	6aa2                	ld	s5,8(sp)
    80001ea8:	6121                	addi	sp,sp,64
    80001eaa:	8082                	ret
    return -1;
    80001eac:	5afd                	li	s5,-1
    80001eae:	b7ed                	j	80001e98 <fork+0x132>

0000000080001eb0 <reparent>:
{
    80001eb0:	7179                	addi	sp,sp,-48
    80001eb2:	f406                	sd	ra,40(sp)
    80001eb4:	f022                	sd	s0,32(sp)
    80001eb6:	ec26                	sd	s1,24(sp)
    80001eb8:	e84a                	sd	s2,16(sp)
    80001eba:	e44e                	sd	s3,8(sp)
    80001ebc:	e052                	sd	s4,0(sp)
    80001ebe:	1800                	addi	s0,sp,48
    80001ec0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ec2:	0000f497          	auipc	s1,0xf
    80001ec6:	7f648493          	addi	s1,s1,2038 # 800116b8 <proc>
      pp->parent = initproc;
    80001eca:	00007a17          	auipc	s4,0x7
    80001ece:	15ea0a13          	addi	s4,s4,350 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ed2:	00021997          	auipc	s3,0x21
    80001ed6:	1e698993          	addi	s3,s3,486 # 800230b8 <tickslock>
    80001eda:	a029                	j	80001ee4 <reparent+0x34>
    80001edc:	46848493          	addi	s1,s1,1128
    80001ee0:	03348363          	beq	s1,s3,80001f06 <reparent+0x56>
    if(pp->parent == p){
    80001ee4:	709c                	ld	a5,32(s1)
    80001ee6:	ff279be3          	bne	a5,s2,80001edc <reparent+0x2c>
      acquire(&pp->lock);
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	cea080e7          	jalr	-790(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001ef4:	000a3783          	ld	a5,0(s4)
    80001ef8:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	fffff097          	auipc	ra,0xfffff
    80001f00:	d8e080e7          	jalr	-626(ra) # 80000c8a <release>
    80001f04:	bfe1                	j	80001edc <reparent+0x2c>
}
    80001f06:	70a2                	ld	ra,40(sp)
    80001f08:	7402                	ld	s0,32(sp)
    80001f0a:	64e2                	ld	s1,24(sp)
    80001f0c:	6942                	ld	s2,16(sp)
    80001f0e:	69a2                	ld	s3,8(sp)
    80001f10:	6a02                	ld	s4,0(sp)
    80001f12:	6145                	addi	sp,sp,48
    80001f14:	8082                	ret

0000000080001f16 <scheduler>:
{
    80001f16:	711d                	addi	sp,sp,-96
    80001f18:	ec86                	sd	ra,88(sp)
    80001f1a:	e8a2                	sd	s0,80(sp)
    80001f1c:	e4a6                	sd	s1,72(sp)
    80001f1e:	e0ca                	sd	s2,64(sp)
    80001f20:	fc4e                	sd	s3,56(sp)
    80001f22:	f852                	sd	s4,48(sp)
    80001f24:	f456                	sd	s5,40(sp)
    80001f26:	f05a                	sd	s6,32(sp)
    80001f28:	ec5e                	sd	s7,24(sp)
    80001f2a:	e862                	sd	s8,16(sp)
    80001f2c:	e466                	sd	s9,8(sp)
    80001f2e:	1080                	addi	s0,sp,96
    80001f30:	8792                	mv	a5,tp
  int id = r_tp();
    80001f32:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f34:	00779c13          	slli	s8,a5,0x7
    80001f38:	0000f717          	auipc	a4,0xf
    80001f3c:	36870713          	addi	a4,a4,872 # 800112a0 <pid_lock>
    80001f40:	9762                	add	a4,a4,s8
    80001f42:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f46:	0000f717          	auipc	a4,0xf
    80001f4a:	37a70713          	addi	a4,a4,890 # 800112c0 <cpus+0x8>
    80001f4e:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001f50:	4a89                	li	s5,2
        c->proc = p;
    80001f52:	079e                	slli	a5,a5,0x7
    80001f54:	0000fb17          	auipc	s6,0xf
    80001f58:	34cb0b13          	addi	s6,s6,844 # 800112a0 <pid_lock>
    80001f5c:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5e:	00021a17          	auipc	s4,0x21
    80001f62:	15aa0a13          	addi	s4,s4,346 # 800230b8 <tickslock>
    int nproc = 0;
    80001f66:	4c81                	li	s9,0
    80001f68:	a8a1                	j	80001fc0 <scheduler+0xaa>
        p->state = RUNNING;
    80001f6a:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f6e:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001f72:	06048593          	addi	a1,s1,96
    80001f76:	8562                	mv	a0,s8
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	69e080e7          	jalr	1694(ra) # 80002616 <swtch>
        c->proc = 0;
    80001f80:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d04080e7          	jalr	-764(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8e:	46848493          	addi	s1,s1,1128
    80001f92:	01448d63          	beq	s1,s4,80001fac <scheduler+0x96>
      acquire(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	c3e080e7          	jalr	-962(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80001fa0:	4c9c                	lw	a5,24(s1)
    80001fa2:	d3ed                	beqz	a5,80001f84 <scheduler+0x6e>
        nproc++;
    80001fa4:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001fa6:	fd579fe3          	bne	a5,s5,80001f84 <scheduler+0x6e>
    80001faa:	b7c1                	j	80001f6a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001fac:	013aca63          	blt	s5,s3,80001fc0 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fb8:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fbc:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fc4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc8:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80001fcc:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fce:	0000f497          	auipc	s1,0xf
    80001fd2:	6ea48493          	addi	s1,s1,1770 # 800116b8 <proc>
        p->state = RUNNING;
    80001fd6:	4b8d                	li	s7,3
    80001fd8:	bf7d                	j	80001f96 <scheduler+0x80>

0000000080001fda <sched>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	9be080e7          	jalr	-1602(ra) # 800019a6 <myproc>
    80001ff0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	b6a080e7          	jalr	-1174(ra) # 80000b5c <holding>
    80001ffa:	c93d                	beqz	a0,80002070 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	0000f717          	auipc	a4,0xf
    80002006:	29e70713          	addi	a4,a4,670 # 800112a0 <pid_lock>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0907a703          	lw	a4,144(a5)
    80002010:	4785                	li	a5,1
    80002012:	06f71763          	bne	a4,a5,80002080 <sched+0xa6>
  if(p->state == RUNNING)
    80002016:	4c98                	lw	a4,24(s1)
    80002018:	478d                	li	a5,3
    8000201a:	06f70b63          	beq	a4,a5,80002090 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002022:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002024:	efb5                	bnez	a5,800020a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002028:	0000f917          	auipc	s2,0xf
    8000202c:	27890913          	addi	s2,s2,632 # 800112a0 <pid_lock>
    80002030:	2781                	sext.w	a5,a5
    80002032:	079e                	slli	a5,a5,0x7
    80002034:	97ca                	add	a5,a5,s2
    80002036:	0947a983          	lw	s3,148(a5)
    8000203a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	0000f597          	auipc	a1,0xf
    80002044:	28058593          	addi	a1,a1,640 # 800112c0 <cpus+0x8>
    80002048:	95be                	add	a1,a1,a5
    8000204a:	06048513          	addi	a0,s1,96
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	5c8080e7          	jalr	1480(ra) # 80002616 <swtch>
    80002056:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0937aa23          	sw	s3,148(a5)
}
    80002062:	70a2                	ld	ra,40(sp)
    80002064:	7402                	ld	s0,32(sp)
    80002066:	64e2                	ld	s1,24(sp)
    80002068:	6942                	ld	s2,16(sp)
    8000206a:	69a2                	ld	s3,8(sp)
    8000206c:	6145                	addi	sp,sp,48
    8000206e:	8082                	ret
    panic("sched p->lock");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	15050513          	addi	a0,a0,336 # 800081c0 <digits+0x180>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4b8080e7          	jalr	1208(ra) # 80000530 <panic>
    panic("sched locks");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	15050513          	addi	a0,a0,336 # 800081d0 <digits+0x190>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4a8080e7          	jalr	1192(ra) # 80000530 <panic>
    panic("sched running");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	15050513          	addi	a0,a0,336 # 800081e0 <digits+0x1a0>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	498080e7          	jalr	1176(ra) # 80000530 <panic>
    panic("sched interruptible");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	15050513          	addi	a0,a0,336 # 800081f0 <digits+0x1b0>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	488080e7          	jalr	1160(ra) # 80000530 <panic>

00000000800020b0 <exit>:
{
    800020b0:	7139                	addi	sp,sp,-64
    800020b2:	fc06                	sd	ra,56(sp)
    800020b4:	f822                	sd	s0,48(sp)
    800020b6:	f426                	sd	s1,40(sp)
    800020b8:	f04a                	sd	s2,32(sp)
    800020ba:	ec4e                	sd	s3,24(sp)
    800020bc:	e852                	sd	s4,16(sp)
    800020be:	e456                	sd	s5,8(sp)
    800020c0:	0080                	addi	s0,sp,64
    800020c2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	8e2080e7          	jalr	-1822(ra) # 800019a6 <myproc>
    800020cc:	89aa                	mv	s3,a0
  if(p == initproc)
    800020ce:	00007797          	auipc	a5,0x7
    800020d2:	f5a7b783          	ld	a5,-166(a5) # 80009028 <initproc>
    800020d6:	0d050493          	addi	s1,a0,208
    800020da:	15050913          	addi	s2,a0,336
    800020de:	02a79363          	bne	a5,a0,80002104 <exit+0x54>
    panic("init exiting");
    800020e2:	00006517          	auipc	a0,0x6
    800020e6:	12650513          	addi	a0,a0,294 # 80008208 <digits+0x1c8>
    800020ea:	ffffe097          	auipc	ra,0xffffe
    800020ee:	446080e7          	jalr	1094(ra) # 80000530 <panic>
      fileclose(f);
    800020f2:	00002097          	auipc	ra,0x2
    800020f6:	56a080e7          	jalr	1386(ra) # 8000465c <fileclose>
      p->ofile[fd] = 0;
    800020fa:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020fe:	04a1                	addi	s1,s1,8
    80002100:	01248563          	beq	s1,s2,8000210a <exit+0x5a>
    if(p->ofile[fd]){
    80002104:	6088                	ld	a0,0(s1)
    80002106:	f575                	bnez	a0,800020f2 <exit+0x42>
    80002108:	bfdd                	j	800020fe <exit+0x4e>
    8000210a:	16898493          	addi	s1,s3,360
    8000210e:	46898a93          	addi	s5,s3,1128
    80002112:	a0b1                	j	8000215e <exit+0xae>
        filewrite(p->vma[i].file, p->vma[i].addr, p->vma[i].length);
    80002114:	4890                	lw	a2,16(s1)
    80002116:	648c                	ld	a1,8(s1)
    80002118:	7488                	ld	a0,40(s1)
    8000211a:	00002097          	auipc	ra,0x2
    8000211e:	73e080e7          	jalr	1854(ra) # 80004858 <filewrite>
      fileclose(p->vma[i].file);
    80002122:	02893503          	ld	a0,40(s2)
    80002126:	00002097          	auipc	ra,0x2
    8000212a:	536080e7          	jalr	1334(ra) # 8000465c <fileclose>
      uvmunmap(p->pagetable, p->vma[i].addr, p->vma[i].length/PGSIZE, 1);
    8000212e:	01092783          	lw	a5,16(s2)
    80002132:	41f7d61b          	sraiw	a2,a5,0x1f
    80002136:	0146561b          	srliw	a2,a2,0x14
    8000213a:	9e3d                	addw	a2,a2,a5
    8000213c:	4685                	li	a3,1
    8000213e:	40c6561b          	sraiw	a2,a2,0xc
    80002142:	00893583          	ld	a1,8(s2)
    80002146:	0509b503          	ld	a0,80(s3)
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	110080e7          	jalr	272(ra) # 8000125a <uvmunmap>
      p->vma[i].used = 0;
    80002152:	00092023          	sw	zero,0(s2)
 for(int i = 0; i < VMASIZE; i++) {
    80002156:	03048493          	addi	s1,s1,48
    8000215a:	01548963          	beq	s1,s5,8000216c <exit+0xbc>
    if(p->vma[i].used) {
    8000215e:	8926                	mv	s2,s1
    80002160:	409c                	lw	a5,0(s1)
    80002162:	dbf5                	beqz	a5,80002156 <exit+0xa6>
      if(p->vma[i].flags & MAP_SHARED)
    80002164:	4c9c                	lw	a5,24(s1)
    80002166:	8b85                	andi	a5,a5,1
    80002168:	dfcd                	beqz	a5,80002122 <exit+0x72>
    8000216a:	b76d                	j	80002114 <exit+0x64>
  begin_op();
    8000216c:	00002097          	auipc	ra,0x2
    80002170:	01c080e7          	jalr	28(ra) # 80004188 <begin_op>
  iput(p->cwd);
    80002174:	1509b503          	ld	a0,336(s3)
    80002178:	00001097          	auipc	ra,0x1
    8000217c:	7f8080e7          	jalr	2040(ra) # 80003970 <iput>
  end_op();
    80002180:	00002097          	auipc	ra,0x2
    80002184:	088080e7          	jalr	136(ra) # 80004208 <end_op>
  p->cwd = 0;
    80002188:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000218c:	00007497          	auipc	s1,0x7
    80002190:	e9c48493          	addi	s1,s1,-356 # 80009028 <initproc>
    80002194:	6088                	ld	a0,0(s1)
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	a40080e7          	jalr	-1472(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    8000219e:	6088                	ld	a0,0(s1)
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	668080e7          	jalr	1640(ra) # 80001808 <wakeup1>
  release(&initproc->lock);
    800021a8:	6088                	ld	a0,0(s1)
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	ae0080e7          	jalr	-1312(ra) # 80000c8a <release>
  acquire(&p->lock);
    800021b2:	854e                	mv	a0,s3
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	a22080e7          	jalr	-1502(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    800021bc:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021c0:	854e                	mv	a0,s3
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ac8080e7          	jalr	-1336(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	a0a080e7          	jalr	-1526(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    800021d4:	854e                	mv	a0,s3
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	a00080e7          	jalr	-1536(ra) # 80000bd6 <acquire>
  reparent(p);
    800021de:	854e                	mv	a0,s3
    800021e0:	00000097          	auipc	ra,0x0
    800021e4:	cd0080e7          	jalr	-816(ra) # 80001eb0 <reparent>
  wakeup1(original_parent);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	61e080e7          	jalr	1566(ra) # 80001808 <wakeup1>
  p->xstate = status;
    800021f2:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021f6:	4791                	li	a5,4
    800021f8:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021fc:	8526                	mv	a0,s1
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	a8c080e7          	jalr	-1396(ra) # 80000c8a <release>
  sched();
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	dd4080e7          	jalr	-556(ra) # 80001fda <sched>
  panic("zombie exit");
    8000220e:	00006517          	auipc	a0,0x6
    80002212:	00a50513          	addi	a0,a0,10 # 80008218 <digits+0x1d8>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	31a080e7          	jalr	794(ra) # 80000530 <panic>

000000008000221e <yield>:
{
    8000221e:	1101                	addi	sp,sp,-32
    80002220:	ec06                	sd	ra,24(sp)
    80002222:	e822                	sd	s0,16(sp)
    80002224:	e426                	sd	s1,8(sp)
    80002226:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	77e080e7          	jalr	1918(ra) # 800019a6 <myproc>
    80002230:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9a4080e7          	jalr	-1628(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000223a:	4789                	li	a5,2
    8000223c:	cc9c                	sw	a5,24(s1)
  sched();
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	d9c080e7          	jalr	-612(ra) # 80001fda <sched>
  release(&p->lock);
    80002246:	8526                	mv	a0,s1
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	a42080e7          	jalr	-1470(ra) # 80000c8a <release>
}
    80002250:	60e2                	ld	ra,24(sp)
    80002252:	6442                	ld	s0,16(sp)
    80002254:	64a2                	ld	s1,8(sp)
    80002256:	6105                	addi	sp,sp,32
    80002258:	8082                	ret

000000008000225a <sleep>:
{
    8000225a:	7179                	addi	sp,sp,-48
    8000225c:	f406                	sd	ra,40(sp)
    8000225e:	f022                	sd	s0,32(sp)
    80002260:	ec26                	sd	s1,24(sp)
    80002262:	e84a                	sd	s2,16(sp)
    80002264:	e44e                	sd	s3,8(sp)
    80002266:	1800                	addi	s0,sp,48
    80002268:	89aa                	mv	s3,a0
    8000226a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	73a080e7          	jalr	1850(ra) # 800019a6 <myproc>
    80002274:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002276:	05250663          	beq	a0,s2,800022c2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	95c080e7          	jalr	-1700(ra) # 80000bd6 <acquire>
    release(lk);
    80002282:	854a                	mv	a0,s2
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	a06080e7          	jalr	-1530(ra) # 80000c8a <release>
  p->chan = chan;
    8000228c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002290:	4785                	li	a5,1
    80002292:	cc9c                	sw	a5,24(s1)
  sched();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	d46080e7          	jalr	-698(ra) # 80001fda <sched>
  p->chan = 0;
    8000229c:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9e8080e7          	jalr	-1560(ra) # 80000c8a <release>
    acquire(lk);
    800022aa:	854a                	mv	a0,s2
    800022ac:	fffff097          	auipc	ra,0xfffff
    800022b0:	92a080e7          	jalr	-1750(ra) # 80000bd6 <acquire>
}
    800022b4:	70a2                	ld	ra,40(sp)
    800022b6:	7402                	ld	s0,32(sp)
    800022b8:	64e2                	ld	s1,24(sp)
    800022ba:	6942                	ld	s2,16(sp)
    800022bc:	69a2                	ld	s3,8(sp)
    800022be:	6145                	addi	sp,sp,48
    800022c0:	8082                	ret
  p->chan = chan;
    800022c2:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022c6:	4785                	li	a5,1
    800022c8:	cd1c                	sw	a5,24(a0)
  sched();
    800022ca:	00000097          	auipc	ra,0x0
    800022ce:	d10080e7          	jalr	-752(ra) # 80001fda <sched>
  p->chan = 0;
    800022d2:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022d6:	bff9                	j	800022b4 <sleep+0x5a>

00000000800022d8 <wait>:
{
    800022d8:	715d                	addi	sp,sp,-80
    800022da:	e486                	sd	ra,72(sp)
    800022dc:	e0a2                	sd	s0,64(sp)
    800022de:	fc26                	sd	s1,56(sp)
    800022e0:	f84a                	sd	s2,48(sp)
    800022e2:	f44e                	sd	s3,40(sp)
    800022e4:	f052                	sd	s4,32(sp)
    800022e6:	ec56                	sd	s5,24(sp)
    800022e8:	e85a                	sd	s6,16(sp)
    800022ea:	e45e                	sd	s7,8(sp)
    800022ec:	e062                	sd	s8,0(sp)
    800022ee:	0880                	addi	s0,sp,80
    800022f0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	6b4080e7          	jalr	1716(ra) # 800019a6 <myproc>
    800022fa:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022fc:	8c2a                	mv	s8,a0
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8d8080e7          	jalr	-1832(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002306:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002308:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000230a:	00021997          	auipc	s3,0x21
    8000230e:	dae98993          	addi	s3,s3,-594 # 800230b8 <tickslock>
        havekids = 1;
    80002312:	4a85                	li	s5,1
    havekids = 0;
    80002314:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002316:	0000f497          	auipc	s1,0xf
    8000231a:	3a248493          	addi	s1,s1,930 # 800116b8 <proc>
    8000231e:	a08d                	j	80002380 <wait+0xa8>
          pid = np->pid;
    80002320:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002324:	000b0e63          	beqz	s6,80002340 <wait+0x68>
    80002328:	4691                	li	a3,4
    8000232a:	03448613          	addi	a2,s1,52
    8000232e:	85da                	mv	a1,s6
    80002330:	05093503          	ld	a0,80(s2)
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	308080e7          	jalr	776(ra) # 8000163c <copyout>
    8000233c:	02054263          	bltz	a0,80002360 <wait+0x88>
          freeproc(np);
    80002340:	8526                	mv	a0,s1
    80002342:	00000097          	auipc	ra,0x0
    80002346:	816080e7          	jalr	-2026(ra) # 80001b58 <freeproc>
          release(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	93e080e7          	jalr	-1730(ra) # 80000c8a <release>
          release(&p->lock);
    80002354:	854a                	mv	a0,s2
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
          return pid;
    8000235e:	a8a9                	j	800023b8 <wait+0xe0>
            release(&np->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
            release(&p->lock);
    8000236a:	854a                	mv	a0,s2
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
            return -1;
    80002374:	59fd                	li	s3,-1
    80002376:	a089                	j	800023b8 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002378:	46848493          	addi	s1,s1,1128
    8000237c:	03348463          	beq	s1,s3,800023a4 <wait+0xcc>
      if(np->parent == p){
    80002380:	709c                	ld	a5,32(s1)
    80002382:	ff279be3          	bne	a5,s2,80002378 <wait+0xa0>
        acquire(&np->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    80002390:	4c9c                	lw	a5,24(s1)
    80002392:	f94787e3          	beq	a5,s4,80002320 <wait+0x48>
        release(&np->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8f2080e7          	jalr	-1806(ra) # 80000c8a <release>
        havekids = 1;
    800023a0:	8756                	mv	a4,s5
    800023a2:	bfd9                	j	80002378 <wait+0xa0>
    if(!havekids || p->killed){
    800023a4:	c701                	beqz	a4,800023ac <wait+0xd4>
    800023a6:	03092783          	lw	a5,48(s2)
    800023aa:	c785                	beqz	a5,800023d2 <wait+0xfa>
      release(&p->lock);
    800023ac:	854a                	mv	a0,s2
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	8dc080e7          	jalr	-1828(ra) # 80000c8a <release>
      return -1;
    800023b6:	59fd                	li	s3,-1
}
    800023b8:	854e                	mv	a0,s3
    800023ba:	60a6                	ld	ra,72(sp)
    800023bc:	6406                	ld	s0,64(sp)
    800023be:	74e2                	ld	s1,56(sp)
    800023c0:	7942                	ld	s2,48(sp)
    800023c2:	79a2                	ld	s3,40(sp)
    800023c4:	7a02                	ld	s4,32(sp)
    800023c6:	6ae2                	ld	s5,24(sp)
    800023c8:	6b42                	ld	s6,16(sp)
    800023ca:	6ba2                	ld	s7,8(sp)
    800023cc:	6c02                	ld	s8,0(sp)
    800023ce:	6161                	addi	sp,sp,80
    800023d0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023d2:	85e2                	mv	a1,s8
    800023d4:	854a                	mv	a0,s2
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	e84080e7          	jalr	-380(ra) # 8000225a <sleep>
    havekids = 0;
    800023de:	bf1d                	j	80002314 <wait+0x3c>

00000000800023e0 <wakeup>:
{
    800023e0:	7139                	addi	sp,sp,-64
    800023e2:	fc06                	sd	ra,56(sp)
    800023e4:	f822                	sd	s0,48(sp)
    800023e6:	f426                	sd	s1,40(sp)
    800023e8:	f04a                	sd	s2,32(sp)
    800023ea:	ec4e                	sd	s3,24(sp)
    800023ec:	e852                	sd	s4,16(sp)
    800023ee:	e456                	sd	s5,8(sp)
    800023f0:	0080                	addi	s0,sp,64
    800023f2:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f4:	0000f497          	auipc	s1,0xf
    800023f8:	2c448493          	addi	s1,s1,708 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023fc:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023fe:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002400:	00021917          	auipc	s2,0x21
    80002404:	cb890913          	addi	s2,s2,-840 # 800230b8 <tickslock>
    80002408:	a821                	j	80002420 <wakeup+0x40>
      p->state = RUNNABLE;
    8000240a:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	87a080e7          	jalr	-1926(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002418:	46848493          	addi	s1,s1,1128
    8000241c:	01248e63          	beq	s1,s2,80002438 <wakeup+0x58>
    acquire(&p->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7b4080e7          	jalr	1972(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000242a:	4c9c                	lw	a5,24(s1)
    8000242c:	ff3791e3          	bne	a5,s3,8000240e <wakeup+0x2e>
    80002430:	749c                	ld	a5,40(s1)
    80002432:	fd479ee3          	bne	a5,s4,8000240e <wakeup+0x2e>
    80002436:	bfd1                	j	8000240a <wakeup+0x2a>
}
    80002438:	70e2                	ld	ra,56(sp)
    8000243a:	7442                	ld	s0,48(sp)
    8000243c:	74a2                	ld	s1,40(sp)
    8000243e:	7902                	ld	s2,32(sp)
    80002440:	69e2                	ld	s3,24(sp)
    80002442:	6a42                	ld	s4,16(sp)
    80002444:	6aa2                	ld	s5,8(sp)
    80002446:	6121                	addi	sp,sp,64
    80002448:	8082                	ret

000000008000244a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000244a:	7179                	addi	sp,sp,-48
    8000244c:	f406                	sd	ra,40(sp)
    8000244e:	f022                	sd	s0,32(sp)
    80002450:	ec26                	sd	s1,24(sp)
    80002452:	e84a                	sd	s2,16(sp)
    80002454:	e44e                	sd	s3,8(sp)
    80002456:	1800                	addi	s0,sp,48
    80002458:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000245a:	0000f497          	auipc	s1,0xf
    8000245e:	25e48493          	addi	s1,s1,606 # 800116b8 <proc>
    80002462:	00021997          	auipc	s3,0x21
    80002466:	c5698993          	addi	s3,s3,-938 # 800230b8 <tickslock>
    acquire(&p->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	ffffe097          	auipc	ra,0xffffe
    80002470:	76a080e7          	jalr	1898(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002474:	5c9c                	lw	a5,56(s1)
    80002476:	01278d63          	beq	a5,s2,80002490 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002484:	46848493          	addi	s1,s1,1128
    80002488:	ff3491e3          	bne	s1,s3,8000246a <kill+0x20>
  }
  return -1;
    8000248c:	557d                	li	a0,-1
    8000248e:	a829                	j	800024a8 <kill+0x5e>
      p->killed = 1;
    80002490:	4785                	li	a5,1
    80002492:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002494:	4c98                	lw	a4,24(s1)
    80002496:	4785                	li	a5,1
    80002498:	00f70f63          	beq	a4,a5,800024b6 <kill+0x6c>
      release(&p->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	7ec080e7          	jalr	2028(ra) # 80000c8a <release>
      return 0;
    800024a6:	4501                	li	a0,0
}
    800024a8:	70a2                	ld	ra,40(sp)
    800024aa:	7402                	ld	s0,32(sp)
    800024ac:	64e2                	ld	s1,24(sp)
    800024ae:	6942                	ld	s2,16(sp)
    800024b0:	69a2                	ld	s3,8(sp)
    800024b2:	6145                	addi	sp,sp,48
    800024b4:	8082                	ret
        p->state = RUNNABLE;
    800024b6:	4789                	li	a5,2
    800024b8:	cc9c                	sw	a5,24(s1)
    800024ba:	b7cd                	j	8000249c <kill+0x52>

00000000800024bc <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024bc:	7179                	addi	sp,sp,-48
    800024be:	f406                	sd	ra,40(sp)
    800024c0:	f022                	sd	s0,32(sp)
    800024c2:	ec26                	sd	s1,24(sp)
    800024c4:	e84a                	sd	s2,16(sp)
    800024c6:	e44e                	sd	s3,8(sp)
    800024c8:	e052                	sd	s4,0(sp)
    800024ca:	1800                	addi	s0,sp,48
    800024cc:	84aa                	mv	s1,a0
    800024ce:	892e                	mv	s2,a1
    800024d0:	89b2                	mv	s3,a2
    800024d2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	4d2080e7          	jalr	1234(ra) # 800019a6 <myproc>
  if(user_dst){
    800024dc:	c08d                	beqz	s1,800024fe <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024de:	86d2                	mv	a3,s4
    800024e0:	864e                	mv	a2,s3
    800024e2:	85ca                	mv	a1,s2
    800024e4:	6928                	ld	a0,80(a0)
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	156080e7          	jalr	342(ra) # 8000163c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024ee:	70a2                	ld	ra,40(sp)
    800024f0:	7402                	ld	s0,32(sp)
    800024f2:	64e2                	ld	s1,24(sp)
    800024f4:	6942                	ld	s2,16(sp)
    800024f6:	69a2                	ld	s3,8(sp)
    800024f8:	6a02                	ld	s4,0(sp)
    800024fa:	6145                	addi	sp,sp,48
    800024fc:	8082                	ret
    memmove((char *)dst, src, len);
    800024fe:	000a061b          	sext.w	a2,s4
    80002502:	85ce                	mv	a1,s3
    80002504:	854a                	mv	a0,s2
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	82c080e7          	jalr	-2004(ra) # 80000d32 <memmove>
    return 0;
    8000250e:	8526                	mv	a0,s1
    80002510:	bff9                	j	800024ee <either_copyout+0x32>

0000000080002512 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002512:	7179                	addi	sp,sp,-48
    80002514:	f406                	sd	ra,40(sp)
    80002516:	f022                	sd	s0,32(sp)
    80002518:	ec26                	sd	s1,24(sp)
    8000251a:	e84a                	sd	s2,16(sp)
    8000251c:	e44e                	sd	s3,8(sp)
    8000251e:	e052                	sd	s4,0(sp)
    80002520:	1800                	addi	s0,sp,48
    80002522:	892a                	mv	s2,a0
    80002524:	84ae                	mv	s1,a1
    80002526:	89b2                	mv	s3,a2
    80002528:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	47c080e7          	jalr	1148(ra) # 800019a6 <myproc>
  if(user_src){
    80002532:	c08d                	beqz	s1,80002554 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002534:	86d2                	mv	a3,s4
    80002536:	864e                	mv	a2,s3
    80002538:	85ca                	mv	a1,s2
    8000253a:	6928                	ld	a0,80(a0)
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	18c080e7          	jalr	396(ra) # 800016c8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002544:	70a2                	ld	ra,40(sp)
    80002546:	7402                	ld	s0,32(sp)
    80002548:	64e2                	ld	s1,24(sp)
    8000254a:	6942                	ld	s2,16(sp)
    8000254c:	69a2                	ld	s3,8(sp)
    8000254e:	6a02                	ld	s4,0(sp)
    80002550:	6145                	addi	sp,sp,48
    80002552:	8082                	ret
    memmove(dst, (char*)src, len);
    80002554:	000a061b          	sext.w	a2,s4
    80002558:	85ce                	mv	a1,s3
    8000255a:	854a                	mv	a0,s2
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	7d6080e7          	jalr	2006(ra) # 80000d32 <memmove>
    return 0;
    80002564:	8526                	mv	a0,s1
    80002566:	bff9                	j	80002544 <either_copyin+0x32>

0000000080002568 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002568:	715d                	addi	sp,sp,-80
    8000256a:	e486                	sd	ra,72(sp)
    8000256c:	e0a2                	sd	s0,64(sp)
    8000256e:	fc26                	sd	s1,56(sp)
    80002570:	f84a                	sd	s2,48(sp)
    80002572:	f44e                	sd	s3,40(sp)
    80002574:	f052                	sd	s4,32(sp)
    80002576:	ec56                	sd	s5,24(sp)
    80002578:	e85a                	sd	s6,16(sp)
    8000257a:	e45e                	sd	s7,8(sp)
    8000257c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000257e:	00006517          	auipc	a0,0x6
    80002582:	b4a50513          	addi	a0,a0,-1206 # 800080c8 <digits+0x88>
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	ff4080e7          	jalr	-12(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000258e:	0000f497          	auipc	s1,0xf
    80002592:	28248493          	addi	s1,s1,642 # 80011810 <proc+0x158>
    80002596:	00021917          	auipc	s2,0x21
    8000259a:	c7a90913          	addi	s2,s2,-902 # 80023210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000259e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025a0:	00006997          	auipc	s3,0x6
    800025a4:	c8898993          	addi	s3,s3,-888 # 80008228 <digits+0x1e8>
    printf("%d %s %s", p->pid, state, p->name);
    800025a8:	00006a97          	auipc	s5,0x6
    800025ac:	c88a8a93          	addi	s5,s5,-888 # 80008230 <digits+0x1f0>
    printf("\n");
    800025b0:	00006a17          	auipc	s4,0x6
    800025b4:	b18a0a13          	addi	s4,s4,-1256 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b8:	00006b97          	auipc	s7,0x6
    800025bc:	cb0b8b93          	addi	s7,s7,-848 # 80008268 <states.1728>
    800025c0:	a00d                	j	800025e2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c2:	ee06a583          	lw	a1,-288(a3)
    800025c6:	8556                	mv	a0,s5
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	fb2080e7          	jalr	-78(ra) # 8000057a <printf>
    printf("\n");
    800025d0:	8552                	mv	a0,s4
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	fa8080e7          	jalr	-88(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025da:	46848493          	addi	s1,s1,1128
    800025de:	03248163          	beq	s1,s2,80002600 <procdump+0x98>
    if(p->state == UNUSED)
    800025e2:	86a6                	mv	a3,s1
    800025e4:	ec04a783          	lw	a5,-320(s1)
    800025e8:	dbed                	beqz	a5,800025da <procdump+0x72>
      state = "???";
    800025ea:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ec:	fcfb6be3          	bltu	s6,a5,800025c2 <procdump+0x5a>
    800025f0:	1782                	slli	a5,a5,0x20
    800025f2:	9381                	srli	a5,a5,0x20
    800025f4:	078e                	slli	a5,a5,0x3
    800025f6:	97de                	add	a5,a5,s7
    800025f8:	6390                	ld	a2,0(a5)
    800025fa:	f661                	bnez	a2,800025c2 <procdump+0x5a>
      state = "???";
    800025fc:	864e                	mv	a2,s3
    800025fe:	b7d1                	j	800025c2 <procdump+0x5a>
  }
}
    80002600:	60a6                	ld	ra,72(sp)
    80002602:	6406                	ld	s0,64(sp)
    80002604:	74e2                	ld	s1,56(sp)
    80002606:	7942                	ld	s2,48(sp)
    80002608:	79a2                	ld	s3,40(sp)
    8000260a:	7a02                	ld	s4,32(sp)
    8000260c:	6ae2                	ld	s5,24(sp)
    8000260e:	6b42                	ld	s6,16(sp)
    80002610:	6ba2                	ld	s7,8(sp)
    80002612:	6161                	addi	sp,sp,80
    80002614:	8082                	ret

0000000080002616 <swtch>:
    80002616:	00153023          	sd	ra,0(a0)
    8000261a:	00253423          	sd	sp,8(a0)
    8000261e:	e900                	sd	s0,16(a0)
    80002620:	ed04                	sd	s1,24(a0)
    80002622:	03253023          	sd	s2,32(a0)
    80002626:	03353423          	sd	s3,40(a0)
    8000262a:	03453823          	sd	s4,48(a0)
    8000262e:	03553c23          	sd	s5,56(a0)
    80002632:	05653023          	sd	s6,64(a0)
    80002636:	05753423          	sd	s7,72(a0)
    8000263a:	05853823          	sd	s8,80(a0)
    8000263e:	05953c23          	sd	s9,88(a0)
    80002642:	07a53023          	sd	s10,96(a0)
    80002646:	07b53423          	sd	s11,104(a0)
    8000264a:	0005b083          	ld	ra,0(a1)
    8000264e:	0085b103          	ld	sp,8(a1)
    80002652:	6980                	ld	s0,16(a1)
    80002654:	6d84                	ld	s1,24(a1)
    80002656:	0205b903          	ld	s2,32(a1)
    8000265a:	0285b983          	ld	s3,40(a1)
    8000265e:	0305ba03          	ld	s4,48(a1)
    80002662:	0385ba83          	ld	s5,56(a1)
    80002666:	0405bb03          	ld	s6,64(a1)
    8000266a:	0485bb83          	ld	s7,72(a1)
    8000266e:	0505bc03          	ld	s8,80(a1)
    80002672:	0585bc83          	ld	s9,88(a1)
    80002676:	0605bd03          	ld	s10,96(a1)
    8000267a:	0685bd83          	ld	s11,104(a1)
    8000267e:	8082                	ret

0000000080002680 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002680:	1141                	addi	sp,sp,-16
    80002682:	e406                	sd	ra,8(sp)
    80002684:	e022                	sd	s0,0(sp)
    80002686:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002688:	00006597          	auipc	a1,0x6
    8000268c:	c0858593          	addi	a1,a1,-1016 # 80008290 <states.1728+0x28>
    80002690:	00021517          	auipc	a0,0x21
    80002694:	a2850513          	addi	a0,a0,-1496 # 800230b8 <tickslock>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	4ae080e7          	jalr	1198(ra) # 80000b46 <initlock>
}
    800026a0:	60a2                	ld	ra,8(sp)
    800026a2:	6402                	ld	s0,0(sp)
    800026a4:	0141                	addi	sp,sp,16
    800026a6:	8082                	ret

00000000800026a8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026a8:	1141                	addi	sp,sp,-16
    800026aa:	e422                	sd	s0,8(sp)
    800026ac:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026ae:	00004797          	auipc	a5,0x4
    800026b2:	86278793          	addi	a5,a5,-1950 # 80005f10 <kernelvec>
    800026b6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ba:	6422                	ld	s0,8(sp)
    800026bc:	0141                	addi	sp,sp,16
    800026be:	8082                	ret

00000000800026c0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026c0:	1141                	addi	sp,sp,-16
    800026c2:	e406                	sd	ra,8(sp)
    800026c4:	e022                	sd	s0,0(sp)
    800026c6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026c8:	fffff097          	auipc	ra,0xfffff
    800026cc:	2de080e7          	jalr	734(ra) # 800019a6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026d4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026da:	00005617          	auipc	a2,0x5
    800026de:	92660613          	addi	a2,a2,-1754 # 80007000 <_trampoline>
    800026e2:	00005697          	auipc	a3,0x5
    800026e6:	91e68693          	addi	a3,a3,-1762 # 80007000 <_trampoline>
    800026ea:	8e91                	sub	a3,a3,a2
    800026ec:	040007b7          	lui	a5,0x4000
    800026f0:	17fd                	addi	a5,a5,-1
    800026f2:	07b2                	slli	a5,a5,0xc
    800026f4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026fa:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026fc:	180026f3          	csrr	a3,satp
    80002700:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002702:	6d38                	ld	a4,88(a0)
    80002704:	6134                	ld	a3,64(a0)
    80002706:	6585                	lui	a1,0x1
    80002708:	96ae                	add	a3,a3,a1
    8000270a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000270c:	6d38                	ld	a4,88(a0)
    8000270e:	00000697          	auipc	a3,0x0
    80002712:	13868693          	addi	a3,a3,312 # 80002846 <usertrap>
    80002716:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002718:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000271a:	8692                	mv	a3,tp
    8000271c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000271e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002722:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002726:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000272e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002730:	6f18                	ld	a4,24(a4)
    80002732:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002736:	692c                	ld	a1,80(a0)
    80002738:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000273a:	00005717          	auipc	a4,0x5
    8000273e:	95670713          	addi	a4,a4,-1706 # 80007090 <userret>
    80002742:	8f11                	sub	a4,a4,a2
    80002744:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002746:	577d                	li	a4,-1
    80002748:	177e                	slli	a4,a4,0x3f
    8000274a:	8dd9                	or	a1,a1,a4
    8000274c:	02000537          	lui	a0,0x2000
    80002750:	157d                	addi	a0,a0,-1
    80002752:	0536                	slli	a0,a0,0xd
    80002754:	9782                	jalr	a5
}
    80002756:	60a2                	ld	ra,8(sp)
    80002758:	6402                	ld	s0,0(sp)
    8000275a:	0141                	addi	sp,sp,16
    8000275c:	8082                	ret

000000008000275e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000275e:	1101                	addi	sp,sp,-32
    80002760:	ec06                	sd	ra,24(sp)
    80002762:	e822                	sd	s0,16(sp)
    80002764:	e426                	sd	s1,8(sp)
    80002766:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002768:	00021497          	auipc	s1,0x21
    8000276c:	95048493          	addi	s1,s1,-1712 # 800230b8 <tickslock>
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	464080e7          	jalr	1124(ra) # 80000bd6 <acquire>
  ticks++;
    8000277a:	00007517          	auipc	a0,0x7
    8000277e:	8b650513          	addi	a0,a0,-1866 # 80009030 <ticks>
    80002782:	411c                	lw	a5,0(a0)
    80002784:	2785                	addiw	a5,a5,1
    80002786:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002788:	00000097          	auipc	ra,0x0
    8000278c:	c58080e7          	jalr	-936(ra) # 800023e0 <wakeup>
  release(&tickslock);
    80002790:	8526                	mv	a0,s1
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	4f8080e7          	jalr	1272(ra) # 80000c8a <release>
}
    8000279a:	60e2                	ld	ra,24(sp)
    8000279c:	6442                	ld	s0,16(sp)
    8000279e:	64a2                	ld	s1,8(sp)
    800027a0:	6105                	addi	sp,sp,32
    800027a2:	8082                	ret

00000000800027a4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027a4:	1101                	addi	sp,sp,-32
    800027a6:	ec06                	sd	ra,24(sp)
    800027a8:	e822                	sd	s0,16(sp)
    800027aa:	e426                	sd	s1,8(sp)
    800027ac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027b2:	00074d63          	bltz	a4,800027cc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027b6:	57fd                	li	a5,-1
    800027b8:	17fe                	slli	a5,a5,0x3f
    800027ba:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027bc:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027be:	06f70363          	beq	a4,a5,80002824 <devintr+0x80>
  }
}
    800027c2:	60e2                	ld	ra,24(sp)
    800027c4:	6442                	ld	s0,16(sp)
    800027c6:	64a2                	ld	s1,8(sp)
    800027c8:	6105                	addi	sp,sp,32
    800027ca:	8082                	ret
     (scause & 0xff) == 9){
    800027cc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027d0:	46a5                	li	a3,9
    800027d2:	fed792e3          	bne	a5,a3,800027b6 <devintr+0x12>
    int irq = plic_claim();
    800027d6:	00004097          	auipc	ra,0x4
    800027da:	842080e7          	jalr	-1982(ra) # 80006018 <plic_claim>
    800027de:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e0:	47a9                	li	a5,10
    800027e2:	02f50763          	beq	a0,a5,80002810 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027e6:	4785                	li	a5,1
    800027e8:	02f50963          	beq	a0,a5,8000281a <devintr+0x76>
    return 1;
    800027ec:	4505                	li	a0,1
    } else if(irq){
    800027ee:	d8f1                	beqz	s1,800027c2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f0:	85a6                	mv	a1,s1
    800027f2:	00006517          	auipc	a0,0x6
    800027f6:	aa650513          	addi	a0,a0,-1370 # 80008298 <states.1728+0x30>
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	d80080e7          	jalr	-640(ra) # 8000057a <printf>
      plic_complete(irq);
    80002802:	8526                	mv	a0,s1
    80002804:	00004097          	auipc	ra,0x4
    80002808:	838080e7          	jalr	-1992(ra) # 8000603c <plic_complete>
    return 1;
    8000280c:	4505                	li	a0,1
    8000280e:	bf55                	j	800027c2 <devintr+0x1e>
      uartintr();
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	18a080e7          	jalr	394(ra) # 8000099a <uartintr>
    80002818:	b7ed                	j	80002802 <devintr+0x5e>
      virtio_disk_intr();
    8000281a:	00004097          	auipc	ra,0x4
    8000281e:	d02080e7          	jalr	-766(ra) # 8000651c <virtio_disk_intr>
    80002822:	b7c5                	j	80002802 <devintr+0x5e>
    if(cpuid() == 0){
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	156080e7          	jalr	342(ra) # 8000197a <cpuid>
    8000282c:	c901                	beqz	a0,8000283c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000282e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002832:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002834:	14479073          	csrw	sip,a5
    return 2;
    80002838:	4509                	li	a0,2
    8000283a:	b761                	j	800027c2 <devintr+0x1e>
      clockintr();
    8000283c:	00000097          	auipc	ra,0x0
    80002840:	f22080e7          	jalr	-222(ra) # 8000275e <clockintr>
    80002844:	b7ed                	j	8000282e <devintr+0x8a>

0000000080002846 <usertrap>:
{
    80002846:	715d                	addi	sp,sp,-80
    80002848:	e486                	sd	ra,72(sp)
    8000284a:	e0a2                	sd	s0,64(sp)
    8000284c:	fc26                	sd	s1,56(sp)
    8000284e:	f84a                	sd	s2,48(sp)
    80002850:	f44e                	sd	s3,40(sp)
    80002852:	f052                	sd	s4,32(sp)
    80002854:	ec56                	sd	s5,24(sp)
    80002856:	e85a                	sd	s6,16(sp)
    80002858:	e45e                	sd	s7,8(sp)
    8000285a:	e062                	sd	s8,0(sp)
    8000285c:	0880                	addi	s0,sp,80
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002862:	1007f793          	andi	a5,a5,256
    80002866:	eba5                	bnez	a5,800028d6 <usertrap+0x90>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002868:	00003797          	auipc	a5,0x3
    8000286c:	6a878793          	addi	a5,a5,1704 # 80005f10 <kernelvec>
    80002870:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002874:	fffff097          	auipc	ra,0xfffff
    80002878:	132080e7          	jalr	306(ra) # 800019a6 <myproc>
    8000287c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000287e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002880:	14102773          	csrr	a4,sepc
    80002884:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002886:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000288a:	47a1                	li	a5,8
    8000288c:	06f71363          	bne	a4,a5,800028f2 <usertrap+0xac>
    if(p->killed)
    80002890:	591c                	lw	a5,48(a0)
    80002892:	ebb1                	bnez	a5,800028e6 <usertrap+0xa0>
    p->trapframe->epc += 4;
    80002894:	6cb8                	ld	a4,88(s1)
    80002896:	6f1c                	ld	a5,24(a4)
    80002898:	0791                	addi	a5,a5,4
    8000289a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a4:	10079073          	csrw	sstatus,a5
    syscall();
    800028a8:	00000097          	auipc	ra,0x0
    800028ac:	410080e7          	jalr	1040(ra) # 80002cb8 <syscall>
  if(p->killed)
    800028b0:	589c                	lw	a5,48(s1)
    800028b2:	1c079063          	bnez	a5,80002a72 <usertrap+0x22c>
  usertrapret();
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	e0a080e7          	jalr	-502(ra) # 800026c0 <usertrapret>
}
    800028be:	60a6                	ld	ra,72(sp)
    800028c0:	6406                	ld	s0,64(sp)
    800028c2:	74e2                	ld	s1,56(sp)
    800028c4:	7942                	ld	s2,48(sp)
    800028c6:	79a2                	ld	s3,40(sp)
    800028c8:	7a02                	ld	s4,32(sp)
    800028ca:	6ae2                	ld	s5,24(sp)
    800028cc:	6b42                	ld	s6,16(sp)
    800028ce:	6ba2                	ld	s7,8(sp)
    800028d0:	6c02                	ld	s8,0(sp)
    800028d2:	6161                	addi	sp,sp,80
    800028d4:	8082                	ret
    panic("usertrap: not from user mode");
    800028d6:	00006517          	auipc	a0,0x6
    800028da:	9e250513          	addi	a0,a0,-1566 # 800082b8 <states.1728+0x50>
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	c52080e7          	jalr	-942(ra) # 80000530 <panic>
      exit(-1);
    800028e6:	557d                	li	a0,-1
    800028e8:	fffff097          	auipc	ra,0xfffff
    800028ec:	7c8080e7          	jalr	1992(ra) # 800020b0 <exit>
    800028f0:	b755                	j	80002894 <usertrap+0x4e>
  } else if((which_dev = devintr()) != 0){
    800028f2:	00000097          	auipc	ra,0x0
    800028f6:	eb2080e7          	jalr	-334(ra) # 800027a4 <devintr>
    800028fa:	892a                	mv	s2,a0
    800028fc:	16051763          	bnez	a0,80002a6a <usertrap+0x224>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002900:	14202773          	csrr	a4,scause
  } else if(r_scause() == 13 || r_scause() == 15) {
    80002904:	47b5                	li	a5,13
    80002906:	00f70763          	beq	a4,a5,80002914 <usertrap+0xce>
    8000290a:	14202773          	csrr	a4,scause
    8000290e:	47bd                	li	a5,15
    80002910:	12f71363          	bne	a4,a5,80002a36 <usertrap+0x1f0>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002914:	14302a73          	csrr	s4,stval
    if(va >= p->sz || va > MAXVA || PGROUNDUP(va) == PGROUNDDOWN(p->trapframe->sp)) p->killed = 1;
    80002918:	64bc                	ld	a5,72(s1)
    8000291a:	00fa7f63          	bgeu	s4,a5,80002938 <usertrap+0xf2>
    8000291e:	4785                	li	a5,1
    80002920:	179a                	slli	a5,a5,0x26
    80002922:	0147eb63          	bltu	a5,s4,80002938 <usertrap+0xf2>
    80002926:	6cb8                	ld	a4,88(s1)
    80002928:	6785                	lui	a5,0x1
    8000292a:	17fd                	addi	a5,a5,-1
    8000292c:	97d2                	add	a5,a5,s4
    8000292e:	7b18                	ld	a4,48(a4)
    80002930:	8fb9                	xor	a5,a5,a4
    80002932:	777d                	lui	a4,0xfffff
    80002934:	8ff9                	and	a5,a5,a4
    80002936:	e385                	bnez	a5,80002956 <usertrap+0x110>
    80002938:	4785                	li	a5,1
    8000293a:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000293c:	557d                	li	a0,-1
    8000293e:	fffff097          	auipc	ra,0xfffff
    80002942:	772080e7          	jalr	1906(ra) # 800020b0 <exit>
  if(which_dev == 2)
    80002946:	4789                	li	a5,2
    80002948:	f6f917e3          	bne	s2,a5,800028b6 <usertrap+0x70>
    yield();
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	8d2080e7          	jalr	-1838(ra) # 8000221e <yield>
    80002954:	b78d                	j	800028b6 <usertrap+0x70>
    80002956:	16848793          	addi	a5,s1,360
      for (int i = 0; i < VMASIZE; i++) {
    8000295a:	89ca                	mv	s3,s2
        if (p->vma[i].used == 1 && va >= p->vma[i].addr && va < p->vma[i].addr + p->vma[i].length) {
    8000295c:	4605                	li	a2,1
      for (int i = 0; i < VMASIZE; i++) {
    8000295e:	45c1                	li	a1,16
    80002960:	a031                	j	8000296c <usertrap+0x126>
    80002962:	2985                	addiw	s3,s3,1
    80002964:	03078793          	addi	a5,a5,48 # 1030 <_entry-0x7fffefd0>
    80002968:	f4b984e3          	beq	s3,a1,800028b0 <usertrap+0x6a>
        if (p->vma[i].used == 1 && va >= p->vma[i].addr && va < p->vma[i].addr + p->vma[i].length) {
    8000296c:	4398                	lw	a4,0(a5)
    8000296e:	fec71ae3          	bne	a4,a2,80002962 <usertrap+0x11c>
    80002972:	6798                	ld	a4,8(a5)
    80002974:	feea67e3          	bltu	s4,a4,80002962 <usertrap+0x11c>
    80002978:	4b94                	lw	a3,16(a5)
    8000297a:	9736                	add	a4,a4,a3
    8000297c:	feea73e3          	bgeu	s4,a4,80002962 <usertrap+0x11c>
        uint64 offset = va - vma->addr;
    80002980:	00199793          	slli	a5,s3,0x1
    80002984:	97ce                	add	a5,a5,s3
    80002986:	0792                	slli	a5,a5,0x4
    80002988:	97a6                	add	a5,a5,s1
    8000298a:	1707bc03          	ld	s8,368(a5)
        uint64 mem = (uint64)kalloc();
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	158080e7          	jalr	344(ra) # 80000ae6 <kalloc>
    80002996:	8aaa                	mv	s5,a0
        if(mem == 0) {
    80002998:	cd41                	beqz	a0,80002a30 <usertrap+0x1ea>
        va = PGROUNDDOWN(va);
    8000299a:	7bfd                	lui	s7,0xfffff
    8000299c:	017a7bb3          	and	s7,s4,s7
          memset((void*)mem, 0, PGSIZE);
    800029a0:	6605                	lui	a2,0x1
    800029a2:	4581                	li	a1,0
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	32e080e7          	jalr	814(ra) # 80000cd2 <memset>
		  ilock(vma->file->ip);
    800029ac:	00199a13          	slli	s4,s3,0x1
    800029b0:	013a0b33          	add	s6,s4,s3
    800029b4:	0b12                	slli	s6,s6,0x4
    800029b6:	9b26                	add	s6,s6,s1
    800029b8:	190b3783          	ld	a5,400(s6)
    800029bc:	6f88                	ld	a0,24(a5)
    800029be:	00001097          	auipc	ra,0x1
    800029c2:	df8080e7          	jalr	-520(ra) # 800037b6 <ilock>
          readi(vma->file->ip, 0, mem, offset, PGSIZE);
    800029c6:	190b3783          	ld	a5,400(s6)
    800029ca:	6705                	lui	a4,0x1
    800029cc:	418b86bb          	subw	a3,s7,s8
    800029d0:	8656                	mv	a2,s5
    800029d2:	4581                	li	a1,0
    800029d4:	6f88                	ld	a0,24(a5)
    800029d6:	00001097          	auipc	ra,0x1
    800029da:	094080e7          	jalr	148(ra) # 80003a6a <readi>
          iunlock(vma->file->ip);
    800029de:	190b3783          	ld	a5,400(s6)
    800029e2:	6f88                	ld	a0,24(a5)
    800029e4:	00001097          	auipc	ra,0x1
    800029e8:	e94080e7          	jalr	-364(ra) # 80003878 <iunlock>
          if(vma->prot & PROT_READ) flag |= PTE_R;
    800029ec:	17cb2783          	lw	a5,380(s6)
    800029f0:	0017f693          	andi	a3,a5,1
          int flag = PTE_U;
    800029f4:	4741                	li	a4,16
          if(vma->prot & PROT_READ) flag |= PTE_R;
    800029f6:	c291                	beqz	a3,800029fa <usertrap+0x1b4>
    800029f8:	4749                	li	a4,18
          if(vma->prot & PROT_WRITE) flag |= PTE_W;
    800029fa:	0027f693          	andi	a3,a5,2
    800029fe:	c299                	beqz	a3,80002a04 <usertrap+0x1be>
    80002a00:	00476713          	ori	a4,a4,4
          if(vma->prot & PROT_EXEC) flag |= PTE_X;
    80002a04:	8b91                	andi	a5,a5,4
    80002a06:	c399                	beqz	a5,80002a0c <usertrap+0x1c6>
    80002a08:	00876713          	ori	a4,a4,8
          if(mappages(p->pagetable, va, PGSIZE, mem, flag) != 0) {
    80002a0c:	86d6                	mv	a3,s5
    80002a0e:	6605                	lui	a2,0x1
    80002a10:	85de                	mv	a1,s7
    80002a12:	68a8                	ld	a0,80(s1)
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	692080e7          	jalr	1682(ra) # 800010a6 <mappages>
    80002a1c:	e8050ae3          	beqz	a0,800028b0 <usertrap+0x6a>
            kfree((void*)mem);
    80002a20:	8556                	mv	a0,s5
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	fc8080e7          	jalr	-56(ra) # 800009ea <kfree>
            p->killed = 1;
    80002a2a:	4785                	li	a5,1
    80002a2c:	d89c                	sw	a5,48(s1)
    80002a2e:	b739                	j	8000293c <usertrap+0xf6>
          p->killed = 1;
    80002a30:	4785                	li	a5,1
    80002a32:	d89c                	sw	a5,48(s1)
    80002a34:	b721                	j	8000293c <usertrap+0xf6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a36:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a3a:	5c90                	lw	a2,56(s1)
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	89c50513          	addi	a0,a0,-1892 # 800082d8 <states.1728+0x70>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	b36080e7          	jalr	-1226(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a50:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	8b450513          	addi	a0,a0,-1868 # 80008308 <states.1728+0xa0>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	b1e080e7          	jalr	-1250(ra) # 8000057a <printf>
    p->killed = 1;
    80002a64:	4785                	li	a5,1
    80002a66:	d89c                	sw	a5,48(s1)
    80002a68:	bdd1                	j	8000293c <usertrap+0xf6>
  if(p->killed)
    80002a6a:	589c                	lw	a5,48(s1)
    80002a6c:	ec078de3          	beqz	a5,80002946 <usertrap+0x100>
    80002a70:	b5f1                	j	8000293c <usertrap+0xf6>
    80002a72:	4901                	li	s2,0
    80002a74:	b5e1                	j	8000293c <usertrap+0xf6>

0000000080002a76 <kerneltrap>:
{
    80002a76:	7179                	addi	sp,sp,-48
    80002a78:	f406                	sd	ra,40(sp)
    80002a7a:	f022                	sd	s0,32(sp)
    80002a7c:	ec26                	sd	s1,24(sp)
    80002a7e:	e84a                	sd	s2,16(sp)
    80002a80:	e44e                	sd	s3,8(sp)
    80002a82:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a84:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a88:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a90:	1004f793          	andi	a5,s1,256
    80002a94:	cb85                	beqz	a5,80002ac4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a96:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a9a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a9c:	ef85                	bnez	a5,80002ad4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a9e:	00000097          	auipc	ra,0x0
    80002aa2:	d06080e7          	jalr	-762(ra) # 800027a4 <devintr>
    80002aa6:	cd1d                	beqz	a0,80002ae4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aa8:	4789                	li	a5,2
    80002aaa:	06f50a63          	beq	a0,a5,80002b1e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aae:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab2:	10049073          	csrw	sstatus,s1
}
    80002ab6:	70a2                	ld	ra,40(sp)
    80002ab8:	7402                	ld	s0,32(sp)
    80002aba:	64e2                	ld	s1,24(sp)
    80002abc:	6942                	ld	s2,16(sp)
    80002abe:	69a2                	ld	s3,8(sp)
    80002ac0:	6145                	addi	sp,sp,48
    80002ac2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	86450513          	addi	a0,a0,-1948 # 80008328 <states.1728+0xc0>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	a64080e7          	jalr	-1436(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	87c50513          	addi	a0,a0,-1924 # 80008350 <states.1728+0xe8>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	a54080e7          	jalr	-1452(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002ae4:	85ce                	mv	a1,s3
    80002ae6:	00006517          	auipc	a0,0x6
    80002aea:	88a50513          	addi	a0,a0,-1910 # 80008370 <states.1728+0x108>
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	a8c080e7          	jalr	-1396(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002afa:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	88250513          	addi	a0,a0,-1918 # 80008380 <states.1728+0x118>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	a74080e7          	jalr	-1420(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002b0e:	00006517          	auipc	a0,0x6
    80002b12:	88a50513          	addi	a0,a0,-1910 # 80008398 <states.1728+0x130>
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	a1a080e7          	jalr	-1510(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b1e:	fffff097          	auipc	ra,0xfffff
    80002b22:	e88080e7          	jalr	-376(ra) # 800019a6 <myproc>
    80002b26:	d541                	beqz	a0,80002aae <kerneltrap+0x38>
    80002b28:	fffff097          	auipc	ra,0xfffff
    80002b2c:	e7e080e7          	jalr	-386(ra) # 800019a6 <myproc>
    80002b30:	4d18                	lw	a4,24(a0)
    80002b32:	478d                	li	a5,3
    80002b34:	f6f71de3          	bne	a4,a5,80002aae <kerneltrap+0x38>
    yield();
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	6e6080e7          	jalr	1766(ra) # 8000221e <yield>
    80002b40:	b7bd                	j	80002aae <kerneltrap+0x38>

0000000080002b42 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b42:	1101                	addi	sp,sp,-32
    80002b44:	ec06                	sd	ra,24(sp)
    80002b46:	e822                	sd	s0,16(sp)
    80002b48:	e426                	sd	s1,8(sp)
    80002b4a:	1000                	addi	s0,sp,32
    80002b4c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	e58080e7          	jalr	-424(ra) # 800019a6 <myproc>
  switch (n) {
    80002b56:	4795                	li	a5,5
    80002b58:	0497e163          	bltu	a5,s1,80002b9a <argraw+0x58>
    80002b5c:	048a                	slli	s1,s1,0x2
    80002b5e:	00006717          	auipc	a4,0x6
    80002b62:	87270713          	addi	a4,a4,-1934 # 800083d0 <states.1728+0x168>
    80002b66:	94ba                	add	s1,s1,a4
    80002b68:	409c                	lw	a5,0(s1)
    80002b6a:	97ba                	add	a5,a5,a4
    80002b6c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b6e:	6d3c                	ld	a5,88(a0)
    80002b70:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b72:	60e2                	ld	ra,24(sp)
    80002b74:	6442                	ld	s0,16(sp)
    80002b76:	64a2                	ld	s1,8(sp)
    80002b78:	6105                	addi	sp,sp,32
    80002b7a:	8082                	ret
    return p->trapframe->a1;
    80002b7c:	6d3c                	ld	a5,88(a0)
    80002b7e:	7fa8                	ld	a0,120(a5)
    80002b80:	bfcd                	j	80002b72 <argraw+0x30>
    return p->trapframe->a2;
    80002b82:	6d3c                	ld	a5,88(a0)
    80002b84:	63c8                	ld	a0,128(a5)
    80002b86:	b7f5                	j	80002b72 <argraw+0x30>
    return p->trapframe->a3;
    80002b88:	6d3c                	ld	a5,88(a0)
    80002b8a:	67c8                	ld	a0,136(a5)
    80002b8c:	b7dd                	j	80002b72 <argraw+0x30>
    return p->trapframe->a4;
    80002b8e:	6d3c                	ld	a5,88(a0)
    80002b90:	6bc8                	ld	a0,144(a5)
    80002b92:	b7c5                	j	80002b72 <argraw+0x30>
    return p->trapframe->a5;
    80002b94:	6d3c                	ld	a5,88(a0)
    80002b96:	6fc8                	ld	a0,152(a5)
    80002b98:	bfe9                	j	80002b72 <argraw+0x30>
  panic("argraw");
    80002b9a:	00006517          	auipc	a0,0x6
    80002b9e:	80e50513          	addi	a0,a0,-2034 # 800083a8 <states.1728+0x140>
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	98e080e7          	jalr	-1650(ra) # 80000530 <panic>

0000000080002baa <fetchaddr>:
{
    80002baa:	1101                	addi	sp,sp,-32
    80002bac:	ec06                	sd	ra,24(sp)
    80002bae:	e822                	sd	s0,16(sp)
    80002bb0:	e426                	sd	s1,8(sp)
    80002bb2:	e04a                	sd	s2,0(sp)
    80002bb4:	1000                	addi	s0,sp,32
    80002bb6:	84aa                	mv	s1,a0
    80002bb8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	dec080e7          	jalr	-532(ra) # 800019a6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bc2:	653c                	ld	a5,72(a0)
    80002bc4:	02f4f863          	bgeu	s1,a5,80002bf4 <fetchaddr+0x4a>
    80002bc8:	00848713          	addi	a4,s1,8
    80002bcc:	02e7e663          	bltu	a5,a4,80002bf8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bd0:	46a1                	li	a3,8
    80002bd2:	8626                	mv	a2,s1
    80002bd4:	85ca                	mv	a1,s2
    80002bd6:	6928                	ld	a0,80(a0)
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	af0080e7          	jalr	-1296(ra) # 800016c8 <copyin>
    80002be0:	00a03533          	snez	a0,a0
    80002be4:	40a00533          	neg	a0,a0
}
    80002be8:	60e2                	ld	ra,24(sp)
    80002bea:	6442                	ld	s0,16(sp)
    80002bec:	64a2                	ld	s1,8(sp)
    80002bee:	6902                	ld	s2,0(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret
    return -1;
    80002bf4:	557d                	li	a0,-1
    80002bf6:	bfcd                	j	80002be8 <fetchaddr+0x3e>
    80002bf8:	557d                	li	a0,-1
    80002bfa:	b7fd                	j	80002be8 <fetchaddr+0x3e>

0000000080002bfc <fetchstr>:
{
    80002bfc:	7179                	addi	sp,sp,-48
    80002bfe:	f406                	sd	ra,40(sp)
    80002c00:	f022                	sd	s0,32(sp)
    80002c02:	ec26                	sd	s1,24(sp)
    80002c04:	e84a                	sd	s2,16(sp)
    80002c06:	e44e                	sd	s3,8(sp)
    80002c08:	1800                	addi	s0,sp,48
    80002c0a:	892a                	mv	s2,a0
    80002c0c:	84ae                	mv	s1,a1
    80002c0e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c10:	fffff097          	auipc	ra,0xfffff
    80002c14:	d96080e7          	jalr	-618(ra) # 800019a6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c18:	86ce                	mv	a3,s3
    80002c1a:	864a                	mv	a2,s2
    80002c1c:	85a6                	mv	a1,s1
    80002c1e:	6928                	ld	a0,80(a0)
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	b34080e7          	jalr	-1228(ra) # 80001754 <copyinstr>
  if(err < 0)
    80002c28:	00054763          	bltz	a0,80002c36 <fetchstr+0x3a>
  return strlen(buf);
    80002c2c:	8526                	mv	a0,s1
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	22c080e7          	jalr	556(ra) # 80000e5a <strlen>
}
    80002c36:	70a2                	ld	ra,40(sp)
    80002c38:	7402                	ld	s0,32(sp)
    80002c3a:	64e2                	ld	s1,24(sp)
    80002c3c:	6942                	ld	s2,16(sp)
    80002c3e:	69a2                	ld	s3,8(sp)
    80002c40:	6145                	addi	sp,sp,48
    80002c42:	8082                	ret

0000000080002c44 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	1000                	addi	s0,sp,32
    80002c4e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	ef2080e7          	jalr	-270(ra) # 80002b42 <argraw>
    80002c58:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c5a:	4501                	li	a0,0
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret

0000000080002c66 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c66:	1101                	addi	sp,sp,-32
    80002c68:	ec06                	sd	ra,24(sp)
    80002c6a:	e822                	sd	s0,16(sp)
    80002c6c:	e426                	sd	s1,8(sp)
    80002c6e:	1000                	addi	s0,sp,32
    80002c70:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c72:	00000097          	auipc	ra,0x0
    80002c76:	ed0080e7          	jalr	-304(ra) # 80002b42 <argraw>
    80002c7a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c7c:	4501                	li	a0,0
    80002c7e:	60e2                	ld	ra,24(sp)
    80002c80:	6442                	ld	s0,16(sp)
    80002c82:	64a2                	ld	s1,8(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret

0000000080002c88 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	e04a                	sd	s2,0(sp)
    80002c92:	1000                	addi	s0,sp,32
    80002c94:	84ae                	mv	s1,a1
    80002c96:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c98:	00000097          	auipc	ra,0x0
    80002c9c:	eaa080e7          	jalr	-342(ra) # 80002b42 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ca0:	864a                	mv	a2,s2
    80002ca2:	85a6                	mv	a1,s1
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	f58080e7          	jalr	-168(ra) # 80002bfc <fetchstr>
}
    80002cac:	60e2                	ld	ra,24(sp)
    80002cae:	6442                	ld	s0,16(sp)
    80002cb0:	64a2                	ld	s1,8(sp)
    80002cb2:	6902                	ld	s2,0(sp)
    80002cb4:	6105                	addi	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <syscall>:
[SYS_munmap]  sys_munmap,
};

void
syscall(void)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	e04a                	sd	s2,0(sp)
    80002cc2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	ce2080e7          	jalr	-798(ra) # 800019a6 <myproc>
    80002ccc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cce:	05853903          	ld	s2,88(a0)
    80002cd2:	0a893783          	ld	a5,168(s2)
    80002cd6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cda:	37fd                	addiw	a5,a5,-1
    80002cdc:	4759                	li	a4,22
    80002cde:	00f76f63          	bltu	a4,a5,80002cfc <syscall+0x44>
    80002ce2:	00369713          	slli	a4,a3,0x3
    80002ce6:	00005797          	auipc	a5,0x5
    80002cea:	70278793          	addi	a5,a5,1794 # 800083e8 <syscalls>
    80002cee:	97ba                	add	a5,a5,a4
    80002cf0:	639c                	ld	a5,0(a5)
    80002cf2:	c789                	beqz	a5,80002cfc <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cf4:	9782                	jalr	a5
    80002cf6:	06a93823          	sd	a0,112(s2)
    80002cfa:	a839                	j	80002d18 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cfc:	15848613          	addi	a2,s1,344
    80002d00:	5c8c                	lw	a1,56(s1)
    80002d02:	00005517          	auipc	a0,0x5
    80002d06:	6ae50513          	addi	a0,a0,1710 # 800083b0 <states.1728+0x148>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	870080e7          	jalr	-1936(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d12:	6cbc                	ld	a5,88(s1)
    80002d14:	577d                	li	a4,-1
    80002d16:	fbb8                	sd	a4,112(a5)
  }
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6902                	ld	s2,0(sp)
    80002d20:	6105                	addi	sp,sp,32
    80002d22:	8082                	ret

0000000080002d24 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d2c:	fec40593          	addi	a1,s0,-20
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	f12080e7          	jalr	-238(ra) # 80002c44 <argint>
    return -1;
    80002d3a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d3c:	00054963          	bltz	a0,80002d4e <sys_exit+0x2a>
  exit(n);
    80002d40:	fec42503          	lw	a0,-20(s0)
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	36c080e7          	jalr	876(ra) # 800020b0 <exit>
  return 0;  // not reached
    80002d4c:	4781                	li	a5,0
}
    80002d4e:	853e                	mv	a0,a5
    80002d50:	60e2                	ld	ra,24(sp)
    80002d52:	6442                	ld	s0,16(sp)
    80002d54:	6105                	addi	sp,sp,32
    80002d56:	8082                	ret

0000000080002d58 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d58:	1141                	addi	sp,sp,-16
    80002d5a:	e406                	sd	ra,8(sp)
    80002d5c:	e022                	sd	s0,0(sp)
    80002d5e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	c46080e7          	jalr	-954(ra) # 800019a6 <myproc>
}
    80002d68:	5d08                	lw	a0,56(a0)
    80002d6a:	60a2                	ld	ra,8(sp)
    80002d6c:	6402                	ld	s0,0(sp)
    80002d6e:	0141                	addi	sp,sp,16
    80002d70:	8082                	ret

0000000080002d72 <sys_fork>:

uint64
sys_fork(void)
{
    80002d72:	1141                	addi	sp,sp,-16
    80002d74:	e406                	sd	ra,8(sp)
    80002d76:	e022                	sd	s0,0(sp)
    80002d78:	0800                	addi	s0,sp,16
  return fork();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	fec080e7          	jalr	-20(ra) # 80001d66 <fork>
}
    80002d82:	60a2                	ld	ra,8(sp)
    80002d84:	6402                	ld	s0,0(sp)
    80002d86:	0141                	addi	sp,sp,16
    80002d88:	8082                	ret

0000000080002d8a <sys_wait>:

uint64
sys_wait(void)
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d92:	fe840593          	addi	a1,s0,-24
    80002d96:	4501                	li	a0,0
    80002d98:	00000097          	auipc	ra,0x0
    80002d9c:	ece080e7          	jalr	-306(ra) # 80002c66 <argaddr>
    80002da0:	87aa                	mv	a5,a0
    return -1;
    80002da2:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002da4:	0007c863          	bltz	a5,80002db4 <sys_wait+0x2a>
  return wait(p);
    80002da8:	fe843503          	ld	a0,-24(s0)
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	52c080e7          	jalr	1324(ra) # 800022d8 <wait>
}
    80002db4:	60e2                	ld	ra,24(sp)
    80002db6:	6442                	ld	s0,16(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dbc:	7179                	addi	sp,sp,-48
    80002dbe:	f406                	sd	ra,40(sp)
    80002dc0:	f022                	sd	s0,32(sp)
    80002dc2:	ec26                	sd	s1,24(sp)
    80002dc4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dc6:	fdc40593          	addi	a1,s0,-36
    80002dca:	4501                	li	a0,0
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	e78080e7          	jalr	-392(ra) # 80002c44 <argint>
    80002dd4:	87aa                	mv	a5,a0
    return -1;
    80002dd6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002dd8:	0207c063          	bltz	a5,80002df8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	bca080e7          	jalr	-1078(ra) # 800019a6 <myproc>
    80002de4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002de6:	fdc42503          	lw	a0,-36(s0)
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	f08080e7          	jalr	-248(ra) # 80001cf2 <growproc>
    80002df2:	00054863          	bltz	a0,80002e02 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002df6:	8526                	mv	a0,s1
}
    80002df8:	70a2                	ld	ra,40(sp)
    80002dfa:	7402                	ld	s0,32(sp)
    80002dfc:	64e2                	ld	s1,24(sp)
    80002dfe:	6145                	addi	sp,sp,48
    80002e00:	8082                	ret
    return -1;
    80002e02:	557d                	li	a0,-1
    80002e04:	bfd5                	j	80002df8 <sys_sbrk+0x3c>

0000000080002e06 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e06:	7139                	addi	sp,sp,-64
    80002e08:	fc06                	sd	ra,56(sp)
    80002e0a:	f822                	sd	s0,48(sp)
    80002e0c:	f426                	sd	s1,40(sp)
    80002e0e:	f04a                	sd	s2,32(sp)
    80002e10:	ec4e                	sd	s3,24(sp)
    80002e12:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e14:	fcc40593          	addi	a1,s0,-52
    80002e18:	4501                	li	a0,0
    80002e1a:	00000097          	auipc	ra,0x0
    80002e1e:	e2a080e7          	jalr	-470(ra) # 80002c44 <argint>
    return -1;
    80002e22:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e24:	06054563          	bltz	a0,80002e8e <sys_sleep+0x88>
  acquire(&tickslock);
    80002e28:	00020517          	auipc	a0,0x20
    80002e2c:	29050513          	addi	a0,a0,656 # 800230b8 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	da6080e7          	jalr	-602(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e38:	00006917          	auipc	s2,0x6
    80002e3c:	1f892903          	lw	s2,504(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e40:	fcc42783          	lw	a5,-52(s0)
    80002e44:	cf85                	beqz	a5,80002e7c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e46:	00020997          	auipc	s3,0x20
    80002e4a:	27298993          	addi	s3,s3,626 # 800230b8 <tickslock>
    80002e4e:	00006497          	auipc	s1,0x6
    80002e52:	1e248493          	addi	s1,s1,482 # 80009030 <ticks>
    if(myproc()->killed){
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	b50080e7          	jalr	-1200(ra) # 800019a6 <myproc>
    80002e5e:	591c                	lw	a5,48(a0)
    80002e60:	ef9d                	bnez	a5,80002e9e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e62:	85ce                	mv	a1,s3
    80002e64:	8526                	mv	a0,s1
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	3f4080e7          	jalr	1012(ra) # 8000225a <sleep>
  while(ticks - ticks0 < n){
    80002e6e:	409c                	lw	a5,0(s1)
    80002e70:	412787bb          	subw	a5,a5,s2
    80002e74:	fcc42703          	lw	a4,-52(s0)
    80002e78:	fce7efe3          	bltu	a5,a4,80002e56 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e7c:	00020517          	auipc	a0,0x20
    80002e80:	23c50513          	addi	a0,a0,572 # 800230b8 <tickslock>
    80002e84:	ffffe097          	auipc	ra,0xffffe
    80002e88:	e06080e7          	jalr	-506(ra) # 80000c8a <release>
  return 0;
    80002e8c:	4781                	li	a5,0
}
    80002e8e:	853e                	mv	a0,a5
    80002e90:	70e2                	ld	ra,56(sp)
    80002e92:	7442                	ld	s0,48(sp)
    80002e94:	74a2                	ld	s1,40(sp)
    80002e96:	7902                	ld	s2,32(sp)
    80002e98:	69e2                	ld	s3,24(sp)
    80002e9a:	6121                	addi	sp,sp,64
    80002e9c:	8082                	ret
      release(&tickslock);
    80002e9e:	00020517          	auipc	a0,0x20
    80002ea2:	21a50513          	addi	a0,a0,538 # 800230b8 <tickslock>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
      return -1;
    80002eae:	57fd                	li	a5,-1
    80002eb0:	bff9                	j	80002e8e <sys_sleep+0x88>

0000000080002eb2 <sys_kill>:

uint64
sys_kill(void)
{
    80002eb2:	1101                	addi	sp,sp,-32
    80002eb4:	ec06                	sd	ra,24(sp)
    80002eb6:	e822                	sd	s0,16(sp)
    80002eb8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002eba:	fec40593          	addi	a1,s0,-20
    80002ebe:	4501                	li	a0,0
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	d84080e7          	jalr	-636(ra) # 80002c44 <argint>
    80002ec8:	87aa                	mv	a5,a0
    return -1;
    80002eca:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ecc:	0007c863          	bltz	a5,80002edc <sys_kill+0x2a>
  return kill(pid);
    80002ed0:	fec42503          	lw	a0,-20(s0)
    80002ed4:	fffff097          	auipc	ra,0xfffff
    80002ed8:	576080e7          	jalr	1398(ra) # 8000244a <kill>
}
    80002edc:	60e2                	ld	ra,24(sp)
    80002ede:	6442                	ld	s0,16(sp)
    80002ee0:	6105                	addi	sp,sp,32
    80002ee2:	8082                	ret

0000000080002ee4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ee4:	1101                	addi	sp,sp,-32
    80002ee6:	ec06                	sd	ra,24(sp)
    80002ee8:	e822                	sd	s0,16(sp)
    80002eea:	e426                	sd	s1,8(sp)
    80002eec:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eee:	00020517          	auipc	a0,0x20
    80002ef2:	1ca50513          	addi	a0,a0,458 # 800230b8 <tickslock>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	ce0080e7          	jalr	-800(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002efe:	00006497          	auipc	s1,0x6
    80002f02:	1324a483          	lw	s1,306(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f06:	00020517          	auipc	a0,0x20
    80002f0a:	1b250513          	addi	a0,a0,434 # 800230b8 <tickslock>
    80002f0e:	ffffe097          	auipc	ra,0xffffe
    80002f12:	d7c080e7          	jalr	-644(ra) # 80000c8a <release>
  return xticks;
}
    80002f16:	02049513          	slli	a0,s1,0x20
    80002f1a:	9101                	srli	a0,a0,0x20
    80002f1c:	60e2                	ld	ra,24(sp)
    80002f1e:	6442                	ld	s0,16(sp)
    80002f20:	64a2                	ld	s1,8(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f26:	7179                	addi	sp,sp,-48
    80002f28:	f406                	sd	ra,40(sp)
    80002f2a:	f022                	sd	s0,32(sp)
    80002f2c:	ec26                	sd	s1,24(sp)
    80002f2e:	e84a                	sd	s2,16(sp)
    80002f30:	e44e                	sd	s3,8(sp)
    80002f32:	e052                	sd	s4,0(sp)
    80002f34:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f36:	00005597          	auipc	a1,0x5
    80002f3a:	57258593          	addi	a1,a1,1394 # 800084a8 <syscalls+0xc0>
    80002f3e:	00020517          	auipc	a0,0x20
    80002f42:	19250513          	addi	a0,a0,402 # 800230d0 <bcache>
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	c00080e7          	jalr	-1024(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f4e:	00028797          	auipc	a5,0x28
    80002f52:	18278793          	addi	a5,a5,386 # 8002b0d0 <bcache+0x8000>
    80002f56:	00028717          	auipc	a4,0x28
    80002f5a:	3e270713          	addi	a4,a4,994 # 8002b338 <bcache+0x8268>
    80002f5e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f62:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f66:	00020497          	auipc	s1,0x20
    80002f6a:	18248493          	addi	s1,s1,386 # 800230e8 <bcache+0x18>
    b->next = bcache.head.next;
    80002f6e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f70:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f72:	00005a17          	auipc	s4,0x5
    80002f76:	53ea0a13          	addi	s4,s4,1342 # 800084b0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f7a:	2b893783          	ld	a5,696(s2)
    80002f7e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f80:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f84:	85d2                	mv	a1,s4
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	4c4080e7          	jalr	1220(ra) # 8000444e <initsleeplock>
    bcache.head.next->prev = b;
    80002f92:	2b893783          	ld	a5,696(s2)
    80002f96:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f98:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f9c:	45848493          	addi	s1,s1,1112
    80002fa0:	fd349de3          	bne	s1,s3,80002f7a <binit+0x54>
  }
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	69a2                	ld	s3,8(sp)
    80002fae:	6a02                	ld	s4,0(sp)
    80002fb0:	6145                	addi	sp,sp,48
    80002fb2:	8082                	ret

0000000080002fb4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fb4:	7179                	addi	sp,sp,-48
    80002fb6:	f406                	sd	ra,40(sp)
    80002fb8:	f022                	sd	s0,32(sp)
    80002fba:	ec26                	sd	s1,24(sp)
    80002fbc:	e84a                	sd	s2,16(sp)
    80002fbe:	e44e                	sd	s3,8(sp)
    80002fc0:	1800                	addi	s0,sp,48
    80002fc2:	89aa                	mv	s3,a0
    80002fc4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fc6:	00020517          	auipc	a0,0x20
    80002fca:	10a50513          	addi	a0,a0,266 # 800230d0 <bcache>
    80002fce:	ffffe097          	auipc	ra,0xffffe
    80002fd2:	c08080e7          	jalr	-1016(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd6:	00028497          	auipc	s1,0x28
    80002fda:	3b24b483          	ld	s1,946(s1) # 8002b388 <bcache+0x82b8>
    80002fde:	00028797          	auipc	a5,0x28
    80002fe2:	35a78793          	addi	a5,a5,858 # 8002b338 <bcache+0x8268>
    80002fe6:	02f48f63          	beq	s1,a5,80003024 <bread+0x70>
    80002fea:	873e                	mv	a4,a5
    80002fec:	a021                	j	80002ff4 <bread+0x40>
    80002fee:	68a4                	ld	s1,80(s1)
    80002ff0:	02e48a63          	beq	s1,a4,80003024 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ff4:	449c                	lw	a5,8(s1)
    80002ff6:	ff379ce3          	bne	a5,s3,80002fee <bread+0x3a>
    80002ffa:	44dc                	lw	a5,12(s1)
    80002ffc:	ff2799e3          	bne	a5,s2,80002fee <bread+0x3a>
      b->refcnt++;
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	2785                	addiw	a5,a5,1
    80003004:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003006:	00020517          	auipc	a0,0x20
    8000300a:	0ca50513          	addi	a0,a0,202 # 800230d0 <bcache>
    8000300e:	ffffe097          	auipc	ra,0xffffe
    80003012:	c7c080e7          	jalr	-900(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003016:	01048513          	addi	a0,s1,16
    8000301a:	00001097          	auipc	ra,0x1
    8000301e:	46e080e7          	jalr	1134(ra) # 80004488 <acquiresleep>
      return b;
    80003022:	a8b9                	j	80003080 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003024:	00028497          	auipc	s1,0x28
    80003028:	35c4b483          	ld	s1,860(s1) # 8002b380 <bcache+0x82b0>
    8000302c:	00028797          	auipc	a5,0x28
    80003030:	30c78793          	addi	a5,a5,780 # 8002b338 <bcache+0x8268>
    80003034:	00f48863          	beq	s1,a5,80003044 <bread+0x90>
    80003038:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000303a:	40bc                	lw	a5,64(s1)
    8000303c:	cf81                	beqz	a5,80003054 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000303e:	64a4                	ld	s1,72(s1)
    80003040:	fee49de3          	bne	s1,a4,8000303a <bread+0x86>
  panic("bget: no buffers");
    80003044:	00005517          	auipc	a0,0x5
    80003048:	47450513          	addi	a0,a0,1140 # 800084b8 <syscalls+0xd0>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	4e4080e7          	jalr	1252(ra) # 80000530 <panic>
      b->dev = dev;
    80003054:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003058:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000305c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003060:	4785                	li	a5,1
    80003062:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003064:	00020517          	auipc	a0,0x20
    80003068:	06c50513          	addi	a0,a0,108 # 800230d0 <bcache>
    8000306c:	ffffe097          	auipc	ra,0xffffe
    80003070:	c1e080e7          	jalr	-994(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003074:	01048513          	addi	a0,s1,16
    80003078:	00001097          	auipc	ra,0x1
    8000307c:	410080e7          	jalr	1040(ra) # 80004488 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003080:	409c                	lw	a5,0(s1)
    80003082:	cb89                	beqz	a5,80003094 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003084:	8526                	mv	a0,s1
    80003086:	70a2                	ld	ra,40(sp)
    80003088:	7402                	ld	s0,32(sp)
    8000308a:	64e2                	ld	s1,24(sp)
    8000308c:	6942                	ld	s2,16(sp)
    8000308e:	69a2                	ld	s3,8(sp)
    80003090:	6145                	addi	sp,sp,48
    80003092:	8082                	ret
    virtio_disk_rw(b, 0);
    80003094:	4581                	li	a1,0
    80003096:	8526                	mv	a0,s1
    80003098:	00003097          	auipc	ra,0x3
    8000309c:	1ae080e7          	jalr	430(ra) # 80006246 <virtio_disk_rw>
    b->valid = 1;
    800030a0:	4785                	li	a5,1
    800030a2:	c09c                	sw	a5,0(s1)
  return b;
    800030a4:	b7c5                	j	80003084 <bread+0xd0>

00000000800030a6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b2:	0541                	addi	a0,a0,16
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	46e080e7          	jalr	1134(ra) # 80004522 <holdingsleep>
    800030bc:	cd01                	beqz	a0,800030d4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030be:	4585                	li	a1,1
    800030c0:	8526                	mv	a0,s1
    800030c2:	00003097          	auipc	ra,0x3
    800030c6:	184080e7          	jalr	388(ra) # 80006246 <virtio_disk_rw>
}
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret
    panic("bwrite");
    800030d4:	00005517          	auipc	a0,0x5
    800030d8:	3fc50513          	addi	a0,a0,1020 # 800084d0 <syscalls+0xe8>
    800030dc:	ffffd097          	auipc	ra,0xffffd
    800030e0:	454080e7          	jalr	1108(ra) # 80000530 <panic>

00000000800030e4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	e04a                	sd	s2,0(sp)
    800030ee:	1000                	addi	s0,sp,32
    800030f0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030f2:	01050913          	addi	s2,a0,16
    800030f6:	854a                	mv	a0,s2
    800030f8:	00001097          	auipc	ra,0x1
    800030fc:	42a080e7          	jalr	1066(ra) # 80004522 <holdingsleep>
    80003100:	c92d                	beqz	a0,80003172 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003102:	854a                	mv	a0,s2
    80003104:	00001097          	auipc	ra,0x1
    80003108:	3da080e7          	jalr	986(ra) # 800044de <releasesleep>

  acquire(&bcache.lock);
    8000310c:	00020517          	auipc	a0,0x20
    80003110:	fc450513          	addi	a0,a0,-60 # 800230d0 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	ac2080e7          	jalr	-1342(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	37fd                	addiw	a5,a5,-1
    80003120:	0007871b          	sext.w	a4,a5
    80003124:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003126:	eb05                	bnez	a4,80003156 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003128:	68bc                	ld	a5,80(s1)
    8000312a:	64b8                	ld	a4,72(s1)
    8000312c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000312e:	64bc                	ld	a5,72(s1)
    80003130:	68b8                	ld	a4,80(s1)
    80003132:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003134:	00028797          	auipc	a5,0x28
    80003138:	f9c78793          	addi	a5,a5,-100 # 8002b0d0 <bcache+0x8000>
    8000313c:	2b87b703          	ld	a4,696(a5)
    80003140:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003142:	00028717          	auipc	a4,0x28
    80003146:	1f670713          	addi	a4,a4,502 # 8002b338 <bcache+0x8268>
    8000314a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000314c:	2b87b703          	ld	a4,696(a5)
    80003150:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003152:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003156:	00020517          	auipc	a0,0x20
    8000315a:	f7a50513          	addi	a0,a0,-134 # 800230d0 <bcache>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	b2c080e7          	jalr	-1236(ra) # 80000c8a <release>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6902                	ld	s2,0(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret
    panic("brelse");
    80003172:	00005517          	auipc	a0,0x5
    80003176:	36650513          	addi	a0,a0,870 # 800084d8 <syscalls+0xf0>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	3b6080e7          	jalr	950(ra) # 80000530 <panic>

0000000080003182 <bpin>:

void
bpin(struct buf *b) {
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	e426                	sd	s1,8(sp)
    8000318a:	1000                	addi	s0,sp,32
    8000318c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000318e:	00020517          	auipc	a0,0x20
    80003192:	f4250513          	addi	a0,a0,-190 # 800230d0 <bcache>
    80003196:	ffffe097          	auipc	ra,0xffffe
    8000319a:	a40080e7          	jalr	-1472(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000319e:	40bc                	lw	a5,64(s1)
    800031a0:	2785                	addiw	a5,a5,1
    800031a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a4:	00020517          	auipc	a0,0x20
    800031a8:	f2c50513          	addi	a0,a0,-212 # 800230d0 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	ade080e7          	jalr	-1314(ra) # 80000c8a <release>
}
    800031b4:	60e2                	ld	ra,24(sp)
    800031b6:	6442                	ld	s0,16(sp)
    800031b8:	64a2                	ld	s1,8(sp)
    800031ba:	6105                	addi	sp,sp,32
    800031bc:	8082                	ret

00000000800031be <bunpin>:

void
bunpin(struct buf *b) {
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ca:	00020517          	auipc	a0,0x20
    800031ce:	f0650513          	addi	a0,a0,-250 # 800230d0 <bcache>
    800031d2:	ffffe097          	auipc	ra,0xffffe
    800031d6:	a04080e7          	jalr	-1532(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031da:	40bc                	lw	a5,64(s1)
    800031dc:	37fd                	addiw	a5,a5,-1
    800031de:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e0:	00020517          	auipc	a0,0x20
    800031e4:	ef050513          	addi	a0,a0,-272 # 800230d0 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	aa2080e7          	jalr	-1374(ra) # 80000c8a <release>
}
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret

00000000800031fa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031fa:	1101                	addi	sp,sp,-32
    800031fc:	ec06                	sd	ra,24(sp)
    800031fe:	e822                	sd	s0,16(sp)
    80003200:	e426                	sd	s1,8(sp)
    80003202:	e04a                	sd	s2,0(sp)
    80003204:	1000                	addi	s0,sp,32
    80003206:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003208:	00d5d59b          	srliw	a1,a1,0xd
    8000320c:	00028797          	auipc	a5,0x28
    80003210:	5a07a783          	lw	a5,1440(a5) # 8002b7ac <sb+0x1c>
    80003214:	9dbd                	addw	a1,a1,a5
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	d9e080e7          	jalr	-610(ra) # 80002fb4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000321e:	0074f713          	andi	a4,s1,7
    80003222:	4785                	li	a5,1
    80003224:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003228:	14ce                	slli	s1,s1,0x33
    8000322a:	90d9                	srli	s1,s1,0x36
    8000322c:	00950733          	add	a4,a0,s1
    80003230:	05874703          	lbu	a4,88(a4)
    80003234:	00e7f6b3          	and	a3,a5,a4
    80003238:	c69d                	beqz	a3,80003266 <bfree+0x6c>
    8000323a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000323c:	94aa                	add	s1,s1,a0
    8000323e:	fff7c793          	not	a5,a5
    80003242:	8ff9                	and	a5,a5,a4
    80003244:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003248:	00001097          	auipc	ra,0x1
    8000324c:	118080e7          	jalr	280(ra) # 80004360 <log_write>
  brelse(bp);
    80003250:	854a                	mv	a0,s2
    80003252:	00000097          	auipc	ra,0x0
    80003256:	e92080e7          	jalr	-366(ra) # 800030e4 <brelse>
}
    8000325a:	60e2                	ld	ra,24(sp)
    8000325c:	6442                	ld	s0,16(sp)
    8000325e:	64a2                	ld	s1,8(sp)
    80003260:	6902                	ld	s2,0(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret
    panic("freeing free block");
    80003266:	00005517          	auipc	a0,0x5
    8000326a:	27a50513          	addi	a0,a0,634 # 800084e0 <syscalls+0xf8>
    8000326e:	ffffd097          	auipc	ra,0xffffd
    80003272:	2c2080e7          	jalr	706(ra) # 80000530 <panic>

0000000080003276 <balloc>:
{
    80003276:	711d                	addi	sp,sp,-96
    80003278:	ec86                	sd	ra,88(sp)
    8000327a:	e8a2                	sd	s0,80(sp)
    8000327c:	e4a6                	sd	s1,72(sp)
    8000327e:	e0ca                	sd	s2,64(sp)
    80003280:	fc4e                	sd	s3,56(sp)
    80003282:	f852                	sd	s4,48(sp)
    80003284:	f456                	sd	s5,40(sp)
    80003286:	f05a                	sd	s6,32(sp)
    80003288:	ec5e                	sd	s7,24(sp)
    8000328a:	e862                	sd	s8,16(sp)
    8000328c:	e466                	sd	s9,8(sp)
    8000328e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003290:	00028797          	auipc	a5,0x28
    80003294:	5047a783          	lw	a5,1284(a5) # 8002b794 <sb+0x4>
    80003298:	cbd1                	beqz	a5,8000332c <balloc+0xb6>
    8000329a:	8baa                	mv	s7,a0
    8000329c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000329e:	00028b17          	auipc	s6,0x28
    800032a2:	4f2b0b13          	addi	s6,s6,1266 # 8002b790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032a8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032aa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032ac:	6c89                	lui	s9,0x2
    800032ae:	a831                	j	800032ca <balloc+0x54>
    brelse(bp);
    800032b0:	854a                	mv	a0,s2
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	e32080e7          	jalr	-462(ra) # 800030e4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032ba:	015c87bb          	addw	a5,s9,s5
    800032be:	00078a9b          	sext.w	s5,a5
    800032c2:	004b2703          	lw	a4,4(s6)
    800032c6:	06eaf363          	bgeu	s5,a4,8000332c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032ca:	41fad79b          	sraiw	a5,s5,0x1f
    800032ce:	0137d79b          	srliw	a5,a5,0x13
    800032d2:	015787bb          	addw	a5,a5,s5
    800032d6:	40d7d79b          	sraiw	a5,a5,0xd
    800032da:	01cb2583          	lw	a1,28(s6)
    800032de:	9dbd                	addw	a1,a1,a5
    800032e0:	855e                	mv	a0,s7
    800032e2:	00000097          	auipc	ra,0x0
    800032e6:	cd2080e7          	jalr	-814(ra) # 80002fb4 <bread>
    800032ea:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ec:	004b2503          	lw	a0,4(s6)
    800032f0:	000a849b          	sext.w	s1,s5
    800032f4:	8662                	mv	a2,s8
    800032f6:	faa4fde3          	bgeu	s1,a0,800032b0 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032fa:	41f6579b          	sraiw	a5,a2,0x1f
    800032fe:	01d7d69b          	srliw	a3,a5,0x1d
    80003302:	00c6873b          	addw	a4,a3,a2
    80003306:	00777793          	andi	a5,a4,7
    8000330a:	9f95                	subw	a5,a5,a3
    8000330c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003310:	4037571b          	sraiw	a4,a4,0x3
    80003314:	00e906b3          	add	a3,s2,a4
    80003318:	0586c683          	lbu	a3,88(a3)
    8000331c:	00d7f5b3          	and	a1,a5,a3
    80003320:	cd91                	beqz	a1,8000333c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003322:	2605                	addiw	a2,a2,1
    80003324:	2485                	addiw	s1,s1,1
    80003326:	fd4618e3          	bne	a2,s4,800032f6 <balloc+0x80>
    8000332a:	b759                	j	800032b0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000332c:	00005517          	auipc	a0,0x5
    80003330:	1cc50513          	addi	a0,a0,460 # 800084f8 <syscalls+0x110>
    80003334:	ffffd097          	auipc	ra,0xffffd
    80003338:	1fc080e7          	jalr	508(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000333c:	974a                	add	a4,a4,s2
    8000333e:	8fd5                	or	a5,a5,a3
    80003340:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003344:	854a                	mv	a0,s2
    80003346:	00001097          	auipc	ra,0x1
    8000334a:	01a080e7          	jalr	26(ra) # 80004360 <log_write>
        brelse(bp);
    8000334e:	854a                	mv	a0,s2
    80003350:	00000097          	auipc	ra,0x0
    80003354:	d94080e7          	jalr	-620(ra) # 800030e4 <brelse>
  bp = bread(dev, bno);
    80003358:	85a6                	mv	a1,s1
    8000335a:	855e                	mv	a0,s7
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	c58080e7          	jalr	-936(ra) # 80002fb4 <bread>
    80003364:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003366:	40000613          	li	a2,1024
    8000336a:	4581                	li	a1,0
    8000336c:	05850513          	addi	a0,a0,88
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	962080e7          	jalr	-1694(ra) # 80000cd2 <memset>
  log_write(bp);
    80003378:	854a                	mv	a0,s2
    8000337a:	00001097          	auipc	ra,0x1
    8000337e:	fe6080e7          	jalr	-26(ra) # 80004360 <log_write>
  brelse(bp);
    80003382:	854a                	mv	a0,s2
    80003384:	00000097          	auipc	ra,0x0
    80003388:	d60080e7          	jalr	-672(ra) # 800030e4 <brelse>
}
    8000338c:	8526                	mv	a0,s1
    8000338e:	60e6                	ld	ra,88(sp)
    80003390:	6446                	ld	s0,80(sp)
    80003392:	64a6                	ld	s1,72(sp)
    80003394:	6906                	ld	s2,64(sp)
    80003396:	79e2                	ld	s3,56(sp)
    80003398:	7a42                	ld	s4,48(sp)
    8000339a:	7aa2                	ld	s5,40(sp)
    8000339c:	7b02                	ld	s6,32(sp)
    8000339e:	6be2                	ld	s7,24(sp)
    800033a0:	6c42                	ld	s8,16(sp)
    800033a2:	6ca2                	ld	s9,8(sp)
    800033a4:	6125                	addi	sp,sp,96
    800033a6:	8082                	ret

00000000800033a8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033a8:	7179                	addi	sp,sp,-48
    800033aa:	f406                	sd	ra,40(sp)
    800033ac:	f022                	sd	s0,32(sp)
    800033ae:	ec26                	sd	s1,24(sp)
    800033b0:	e84a                	sd	s2,16(sp)
    800033b2:	e44e                	sd	s3,8(sp)
    800033b4:	e052                	sd	s4,0(sp)
    800033b6:	1800                	addi	s0,sp,48
    800033b8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033ba:	47ad                	li	a5,11
    800033bc:	04b7fe63          	bgeu	a5,a1,80003418 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033c0:	ff45849b          	addiw	s1,a1,-12
    800033c4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033c8:	0ff00793          	li	a5,255
    800033cc:	0ae7e363          	bltu	a5,a4,80003472 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033d0:	08052583          	lw	a1,128(a0)
    800033d4:	c5ad                	beqz	a1,8000343e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033d6:	00092503          	lw	a0,0(s2)
    800033da:	00000097          	auipc	ra,0x0
    800033de:	bda080e7          	jalr	-1062(ra) # 80002fb4 <bread>
    800033e2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033e4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033e8:	02049593          	slli	a1,s1,0x20
    800033ec:	9181                	srli	a1,a1,0x20
    800033ee:	058a                	slli	a1,a1,0x2
    800033f0:	00b784b3          	add	s1,a5,a1
    800033f4:	0004a983          	lw	s3,0(s1)
    800033f8:	04098d63          	beqz	s3,80003452 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033fc:	8552                	mv	a0,s4
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	ce6080e7          	jalr	-794(ra) # 800030e4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003406:	854e                	mv	a0,s3
    80003408:	70a2                	ld	ra,40(sp)
    8000340a:	7402                	ld	s0,32(sp)
    8000340c:	64e2                	ld	s1,24(sp)
    8000340e:	6942                	ld	s2,16(sp)
    80003410:	69a2                	ld	s3,8(sp)
    80003412:	6a02                	ld	s4,0(sp)
    80003414:	6145                	addi	sp,sp,48
    80003416:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003418:	02059493          	slli	s1,a1,0x20
    8000341c:	9081                	srli	s1,s1,0x20
    8000341e:	048a                	slli	s1,s1,0x2
    80003420:	94aa                	add	s1,s1,a0
    80003422:	0504a983          	lw	s3,80(s1)
    80003426:	fe0990e3          	bnez	s3,80003406 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000342a:	4108                	lw	a0,0(a0)
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	e4a080e7          	jalr	-438(ra) # 80003276 <balloc>
    80003434:	0005099b          	sext.w	s3,a0
    80003438:	0534a823          	sw	s3,80(s1)
    8000343c:	b7e9                	j	80003406 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000343e:	4108                	lw	a0,0(a0)
    80003440:	00000097          	auipc	ra,0x0
    80003444:	e36080e7          	jalr	-458(ra) # 80003276 <balloc>
    80003448:	0005059b          	sext.w	a1,a0
    8000344c:	08b92023          	sw	a1,128(s2)
    80003450:	b759                	j	800033d6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003452:	00092503          	lw	a0,0(s2)
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	e20080e7          	jalr	-480(ra) # 80003276 <balloc>
    8000345e:	0005099b          	sext.w	s3,a0
    80003462:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003466:	8552                	mv	a0,s4
    80003468:	00001097          	auipc	ra,0x1
    8000346c:	ef8080e7          	jalr	-264(ra) # 80004360 <log_write>
    80003470:	b771                	j	800033fc <bmap+0x54>
  panic("bmap: out of range");
    80003472:	00005517          	auipc	a0,0x5
    80003476:	09e50513          	addi	a0,a0,158 # 80008510 <syscalls+0x128>
    8000347a:	ffffd097          	auipc	ra,0xffffd
    8000347e:	0b6080e7          	jalr	182(ra) # 80000530 <panic>

0000000080003482 <iget>:
{
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	e052                	sd	s4,0(sp)
    80003490:	1800                	addi	s0,sp,48
    80003492:	89aa                	mv	s3,a0
    80003494:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003496:	00028517          	auipc	a0,0x28
    8000349a:	31a50513          	addi	a0,a0,794 # 8002b7b0 <icache>
    8000349e:	ffffd097          	auipc	ra,0xffffd
    800034a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
  empty = 0;
    800034a6:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034a8:	00028497          	auipc	s1,0x28
    800034ac:	32048493          	addi	s1,s1,800 # 8002b7c8 <icache+0x18>
    800034b0:	0002a697          	auipc	a3,0x2a
    800034b4:	da868693          	addi	a3,a3,-600 # 8002d258 <log>
    800034b8:	a039                	j	800034c6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ba:	02090b63          	beqz	s2,800034f0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034be:	08848493          	addi	s1,s1,136
    800034c2:	02d48a63          	beq	s1,a3,800034f6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034c6:	449c                	lw	a5,8(s1)
    800034c8:	fef059e3          	blez	a5,800034ba <iget+0x38>
    800034cc:	4098                	lw	a4,0(s1)
    800034ce:	ff3716e3          	bne	a4,s3,800034ba <iget+0x38>
    800034d2:	40d8                	lw	a4,4(s1)
    800034d4:	ff4713e3          	bne	a4,s4,800034ba <iget+0x38>
      ip->ref++;
    800034d8:	2785                	addiw	a5,a5,1
    800034da:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034dc:	00028517          	auipc	a0,0x28
    800034e0:	2d450513          	addi	a0,a0,724 # 8002b7b0 <icache>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	7a6080e7          	jalr	1958(ra) # 80000c8a <release>
      return ip;
    800034ec:	8926                	mv	s2,s1
    800034ee:	a03d                	j	8000351c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f0:	f7f9                	bnez	a5,800034be <iget+0x3c>
    800034f2:	8926                	mv	s2,s1
    800034f4:	b7e9                	j	800034be <iget+0x3c>
  if(empty == 0)
    800034f6:	02090c63          	beqz	s2,8000352e <iget+0xac>
  ip->dev = dev;
    800034fa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034fe:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003502:	4785                	li	a5,1
    80003504:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003508:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000350c:	00028517          	auipc	a0,0x28
    80003510:	2a450513          	addi	a0,a0,676 # 8002b7b0 <icache>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	776080e7          	jalr	1910(ra) # 80000c8a <release>
}
    8000351c:	854a                	mv	a0,s2
    8000351e:	70a2                	ld	ra,40(sp)
    80003520:	7402                	ld	s0,32(sp)
    80003522:	64e2                	ld	s1,24(sp)
    80003524:	6942                	ld	s2,16(sp)
    80003526:	69a2                	ld	s3,8(sp)
    80003528:	6a02                	ld	s4,0(sp)
    8000352a:	6145                	addi	sp,sp,48
    8000352c:	8082                	ret
    panic("iget: no inodes");
    8000352e:	00005517          	auipc	a0,0x5
    80003532:	ffa50513          	addi	a0,a0,-6 # 80008528 <syscalls+0x140>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	ffa080e7          	jalr	-6(ra) # 80000530 <panic>

000000008000353e <fsinit>:
fsinit(int dev) {
    8000353e:	7179                	addi	sp,sp,-48
    80003540:	f406                	sd	ra,40(sp)
    80003542:	f022                	sd	s0,32(sp)
    80003544:	ec26                	sd	s1,24(sp)
    80003546:	e84a                	sd	s2,16(sp)
    80003548:	e44e                	sd	s3,8(sp)
    8000354a:	1800                	addi	s0,sp,48
    8000354c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000354e:	4585                	li	a1,1
    80003550:	00000097          	auipc	ra,0x0
    80003554:	a64080e7          	jalr	-1436(ra) # 80002fb4 <bread>
    80003558:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000355a:	00028997          	auipc	s3,0x28
    8000355e:	23698993          	addi	s3,s3,566 # 8002b790 <sb>
    80003562:	02000613          	li	a2,32
    80003566:	05850593          	addi	a1,a0,88
    8000356a:	854e                	mv	a0,s3
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	7c6080e7          	jalr	1990(ra) # 80000d32 <memmove>
  brelse(bp);
    80003574:	8526                	mv	a0,s1
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	b6e080e7          	jalr	-1170(ra) # 800030e4 <brelse>
  if(sb.magic != FSMAGIC)
    8000357e:	0009a703          	lw	a4,0(s3)
    80003582:	102037b7          	lui	a5,0x10203
    80003586:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000358a:	02f71263          	bne	a4,a5,800035ae <fsinit+0x70>
  initlog(dev, &sb);
    8000358e:	00028597          	auipc	a1,0x28
    80003592:	20258593          	addi	a1,a1,514 # 8002b790 <sb>
    80003596:	854a                	mv	a0,s2
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	b4c080e7          	jalr	-1204(ra) # 800040e4 <initlog>
}
    800035a0:	70a2                	ld	ra,40(sp)
    800035a2:	7402                	ld	s0,32(sp)
    800035a4:	64e2                	ld	s1,24(sp)
    800035a6:	6942                	ld	s2,16(sp)
    800035a8:	69a2                	ld	s3,8(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret
    panic("invalid file system");
    800035ae:	00005517          	auipc	a0,0x5
    800035b2:	f8a50513          	addi	a0,a0,-118 # 80008538 <syscalls+0x150>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	f7a080e7          	jalr	-134(ra) # 80000530 <panic>

00000000800035be <iinit>:
{
    800035be:	7179                	addi	sp,sp,-48
    800035c0:	f406                	sd	ra,40(sp)
    800035c2:	f022                	sd	s0,32(sp)
    800035c4:	ec26                	sd	s1,24(sp)
    800035c6:	e84a                	sd	s2,16(sp)
    800035c8:	e44e                	sd	s3,8(sp)
    800035ca:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035cc:	00005597          	auipc	a1,0x5
    800035d0:	f8458593          	addi	a1,a1,-124 # 80008550 <syscalls+0x168>
    800035d4:	00028517          	auipc	a0,0x28
    800035d8:	1dc50513          	addi	a0,a0,476 # 8002b7b0 <icache>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	56a080e7          	jalr	1386(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035e4:	00028497          	auipc	s1,0x28
    800035e8:	1f448493          	addi	s1,s1,500 # 8002b7d8 <icache+0x28>
    800035ec:	0002a997          	auipc	s3,0x2a
    800035f0:	c7c98993          	addi	s3,s3,-900 # 8002d268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035f4:	00005917          	auipc	s2,0x5
    800035f8:	f6490913          	addi	s2,s2,-156 # 80008558 <syscalls+0x170>
    800035fc:	85ca                	mv	a1,s2
    800035fe:	8526                	mv	a0,s1
    80003600:	00001097          	auipc	ra,0x1
    80003604:	e4e080e7          	jalr	-434(ra) # 8000444e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003608:	08848493          	addi	s1,s1,136
    8000360c:	ff3498e3          	bne	s1,s3,800035fc <iinit+0x3e>
}
    80003610:	70a2                	ld	ra,40(sp)
    80003612:	7402                	ld	s0,32(sp)
    80003614:	64e2                	ld	s1,24(sp)
    80003616:	6942                	ld	s2,16(sp)
    80003618:	69a2                	ld	s3,8(sp)
    8000361a:	6145                	addi	sp,sp,48
    8000361c:	8082                	ret

000000008000361e <ialloc>:
{
    8000361e:	715d                	addi	sp,sp,-80
    80003620:	e486                	sd	ra,72(sp)
    80003622:	e0a2                	sd	s0,64(sp)
    80003624:	fc26                	sd	s1,56(sp)
    80003626:	f84a                	sd	s2,48(sp)
    80003628:	f44e                	sd	s3,40(sp)
    8000362a:	f052                	sd	s4,32(sp)
    8000362c:	ec56                	sd	s5,24(sp)
    8000362e:	e85a                	sd	s6,16(sp)
    80003630:	e45e                	sd	s7,8(sp)
    80003632:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003634:	00028717          	auipc	a4,0x28
    80003638:	16872703          	lw	a4,360(a4) # 8002b79c <sb+0xc>
    8000363c:	4785                	li	a5,1
    8000363e:	04e7fa63          	bgeu	a5,a4,80003692 <ialloc+0x74>
    80003642:	8aaa                	mv	s5,a0
    80003644:	8bae                	mv	s7,a1
    80003646:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003648:	00028a17          	auipc	s4,0x28
    8000364c:	148a0a13          	addi	s4,s4,328 # 8002b790 <sb>
    80003650:	00048b1b          	sext.w	s6,s1
    80003654:	0044d593          	srli	a1,s1,0x4
    80003658:	018a2783          	lw	a5,24(s4)
    8000365c:	9dbd                	addw	a1,a1,a5
    8000365e:	8556                	mv	a0,s5
    80003660:	00000097          	auipc	ra,0x0
    80003664:	954080e7          	jalr	-1708(ra) # 80002fb4 <bread>
    80003668:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000366a:	05850993          	addi	s3,a0,88
    8000366e:	00f4f793          	andi	a5,s1,15
    80003672:	079a                	slli	a5,a5,0x6
    80003674:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003676:	00099783          	lh	a5,0(s3)
    8000367a:	c785                	beqz	a5,800036a2 <ialloc+0x84>
    brelse(bp);
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	a68080e7          	jalr	-1432(ra) # 800030e4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003684:	0485                	addi	s1,s1,1
    80003686:	00ca2703          	lw	a4,12(s4)
    8000368a:	0004879b          	sext.w	a5,s1
    8000368e:	fce7e1e3          	bltu	a5,a4,80003650 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003692:	00005517          	auipc	a0,0x5
    80003696:	ece50513          	addi	a0,a0,-306 # 80008560 <syscalls+0x178>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	e96080e7          	jalr	-362(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800036a2:	04000613          	li	a2,64
    800036a6:	4581                	li	a1,0
    800036a8:	854e                	mv	a0,s3
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	628080e7          	jalr	1576(ra) # 80000cd2 <memset>
      dip->type = type;
    800036b2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036b6:	854a                	mv	a0,s2
    800036b8:	00001097          	auipc	ra,0x1
    800036bc:	ca8080e7          	jalr	-856(ra) # 80004360 <log_write>
      brelse(bp);
    800036c0:	854a                	mv	a0,s2
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	a22080e7          	jalr	-1502(ra) # 800030e4 <brelse>
      return iget(dev, inum);
    800036ca:	85da                	mv	a1,s6
    800036cc:	8556                	mv	a0,s5
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	db4080e7          	jalr	-588(ra) # 80003482 <iget>
}
    800036d6:	60a6                	ld	ra,72(sp)
    800036d8:	6406                	ld	s0,64(sp)
    800036da:	74e2                	ld	s1,56(sp)
    800036dc:	7942                	ld	s2,48(sp)
    800036de:	79a2                	ld	s3,40(sp)
    800036e0:	7a02                	ld	s4,32(sp)
    800036e2:	6ae2                	ld	s5,24(sp)
    800036e4:	6b42                	ld	s6,16(sp)
    800036e6:	6ba2                	ld	s7,8(sp)
    800036e8:	6161                	addi	sp,sp,80
    800036ea:	8082                	ret

00000000800036ec <iupdate>:
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036fa:	415c                	lw	a5,4(a0)
    800036fc:	0047d79b          	srliw	a5,a5,0x4
    80003700:	00028597          	auipc	a1,0x28
    80003704:	0a85a583          	lw	a1,168(a1) # 8002b7a8 <sb+0x18>
    80003708:	9dbd                	addw	a1,a1,a5
    8000370a:	4108                	lw	a0,0(a0)
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	8a8080e7          	jalr	-1880(ra) # 80002fb4 <bread>
    80003714:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003716:	05850793          	addi	a5,a0,88
    8000371a:	40c8                	lw	a0,4(s1)
    8000371c:	893d                	andi	a0,a0,15
    8000371e:	051a                	slli	a0,a0,0x6
    80003720:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003722:	04449703          	lh	a4,68(s1)
    80003726:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000372a:	04649703          	lh	a4,70(s1)
    8000372e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003732:	04849703          	lh	a4,72(s1)
    80003736:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000373a:	04a49703          	lh	a4,74(s1)
    8000373e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003742:	44f8                	lw	a4,76(s1)
    80003744:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003746:	03400613          	li	a2,52
    8000374a:	05048593          	addi	a1,s1,80
    8000374e:	0531                	addi	a0,a0,12
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	5e2080e7          	jalr	1506(ra) # 80000d32 <memmove>
  log_write(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00001097          	auipc	ra,0x1
    8000375e:	c06080e7          	jalr	-1018(ra) # 80004360 <log_write>
  brelse(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00000097          	auipc	ra,0x0
    80003768:	980080e7          	jalr	-1664(ra) # 800030e4 <brelse>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret

0000000080003778 <idup>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	1000                	addi	s0,sp,32
    80003782:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003784:	00028517          	auipc	a0,0x28
    80003788:	02c50513          	addi	a0,a0,44 # 8002b7b0 <icache>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	44a080e7          	jalr	1098(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003794:	449c                	lw	a5,8(s1)
    80003796:	2785                	addiw	a5,a5,1
    80003798:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000379a:	00028517          	auipc	a0,0x28
    8000379e:	01650513          	addi	a0,a0,22 # 8002b7b0 <icache>
    800037a2:	ffffd097          	auipc	ra,0xffffd
    800037a6:	4e8080e7          	jalr	1256(ra) # 80000c8a <release>
}
    800037aa:	8526                	mv	a0,s1
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret

00000000800037b6 <ilock>:
{
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	e04a                	sd	s2,0(sp)
    800037c0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037c2:	c115                	beqz	a0,800037e6 <ilock+0x30>
    800037c4:	84aa                	mv	s1,a0
    800037c6:	451c                	lw	a5,8(a0)
    800037c8:	00f05f63          	blez	a5,800037e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037cc:	0541                	addi	a0,a0,16
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	cba080e7          	jalr	-838(ra) # 80004488 <acquiresleep>
  if(ip->valid == 0){
    800037d6:	40bc                	lw	a5,64(s1)
    800037d8:	cf99                	beqz	a5,800037f6 <ilock+0x40>
}
    800037da:	60e2                	ld	ra,24(sp)
    800037dc:	6442                	ld	s0,16(sp)
    800037de:	64a2                	ld	s1,8(sp)
    800037e0:	6902                	ld	s2,0(sp)
    800037e2:	6105                	addi	sp,sp,32
    800037e4:	8082                	ret
    panic("ilock");
    800037e6:	00005517          	auipc	a0,0x5
    800037ea:	d9250513          	addi	a0,a0,-622 # 80008578 <syscalls+0x190>
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	d42080e7          	jalr	-702(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037f6:	40dc                	lw	a5,4(s1)
    800037f8:	0047d79b          	srliw	a5,a5,0x4
    800037fc:	00028597          	auipc	a1,0x28
    80003800:	fac5a583          	lw	a1,-84(a1) # 8002b7a8 <sb+0x18>
    80003804:	9dbd                	addw	a1,a1,a5
    80003806:	4088                	lw	a0,0(s1)
    80003808:	fffff097          	auipc	ra,0xfffff
    8000380c:	7ac080e7          	jalr	1964(ra) # 80002fb4 <bread>
    80003810:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003812:	05850593          	addi	a1,a0,88
    80003816:	40dc                	lw	a5,4(s1)
    80003818:	8bbd                	andi	a5,a5,15
    8000381a:	079a                	slli	a5,a5,0x6
    8000381c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000381e:	00059783          	lh	a5,0(a1)
    80003822:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003826:	00259783          	lh	a5,2(a1)
    8000382a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000382e:	00459783          	lh	a5,4(a1)
    80003832:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003836:	00659783          	lh	a5,6(a1)
    8000383a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000383e:	459c                	lw	a5,8(a1)
    80003840:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003842:	03400613          	li	a2,52
    80003846:	05b1                	addi	a1,a1,12
    80003848:	05048513          	addi	a0,s1,80
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	4e6080e7          	jalr	1254(ra) # 80000d32 <memmove>
    brelse(bp);
    80003854:	854a                	mv	a0,s2
    80003856:	00000097          	auipc	ra,0x0
    8000385a:	88e080e7          	jalr	-1906(ra) # 800030e4 <brelse>
    ip->valid = 1;
    8000385e:	4785                	li	a5,1
    80003860:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003862:	04449783          	lh	a5,68(s1)
    80003866:	fbb5                	bnez	a5,800037da <ilock+0x24>
      panic("ilock: no type");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	d1850513          	addi	a0,a0,-744 # 80008580 <syscalls+0x198>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	cc0080e7          	jalr	-832(ra) # 80000530 <panic>

0000000080003878 <iunlock>:
{
    80003878:	1101                	addi	sp,sp,-32
    8000387a:	ec06                	sd	ra,24(sp)
    8000387c:	e822                	sd	s0,16(sp)
    8000387e:	e426                	sd	s1,8(sp)
    80003880:	e04a                	sd	s2,0(sp)
    80003882:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003884:	c905                	beqz	a0,800038b4 <iunlock+0x3c>
    80003886:	84aa                	mv	s1,a0
    80003888:	01050913          	addi	s2,a0,16
    8000388c:	854a                	mv	a0,s2
    8000388e:	00001097          	auipc	ra,0x1
    80003892:	c94080e7          	jalr	-876(ra) # 80004522 <holdingsleep>
    80003896:	cd19                	beqz	a0,800038b4 <iunlock+0x3c>
    80003898:	449c                	lw	a5,8(s1)
    8000389a:	00f05d63          	blez	a5,800038b4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000389e:	854a                	mv	a0,s2
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	c3e080e7          	jalr	-962(ra) # 800044de <releasesleep>
}
    800038a8:	60e2                	ld	ra,24(sp)
    800038aa:	6442                	ld	s0,16(sp)
    800038ac:	64a2                	ld	s1,8(sp)
    800038ae:	6902                	ld	s2,0(sp)
    800038b0:	6105                	addi	sp,sp,32
    800038b2:	8082                	ret
    panic("iunlock");
    800038b4:	00005517          	auipc	a0,0x5
    800038b8:	cdc50513          	addi	a0,a0,-804 # 80008590 <syscalls+0x1a8>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	c74080e7          	jalr	-908(ra) # 80000530 <panic>

00000000800038c4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038c4:	7179                	addi	sp,sp,-48
    800038c6:	f406                	sd	ra,40(sp)
    800038c8:	f022                	sd	s0,32(sp)
    800038ca:	ec26                	sd	s1,24(sp)
    800038cc:	e84a                	sd	s2,16(sp)
    800038ce:	e44e                	sd	s3,8(sp)
    800038d0:	e052                	sd	s4,0(sp)
    800038d2:	1800                	addi	s0,sp,48
    800038d4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038d6:	05050493          	addi	s1,a0,80
    800038da:	08050913          	addi	s2,a0,128
    800038de:	a021                	j	800038e6 <itrunc+0x22>
    800038e0:	0491                	addi	s1,s1,4
    800038e2:	01248d63          	beq	s1,s2,800038fc <itrunc+0x38>
    if(ip->addrs[i]){
    800038e6:	408c                	lw	a1,0(s1)
    800038e8:	dde5                	beqz	a1,800038e0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ea:	0009a503          	lw	a0,0(s3)
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	90c080e7          	jalr	-1780(ra) # 800031fa <bfree>
      ip->addrs[i] = 0;
    800038f6:	0004a023          	sw	zero,0(s1)
    800038fa:	b7dd                	j	800038e0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038fc:	0809a583          	lw	a1,128(s3)
    80003900:	e185                	bnez	a1,80003920 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003902:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003906:	854e                	mv	a0,s3
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	de4080e7          	jalr	-540(ra) # 800036ec <iupdate>
}
    80003910:	70a2                	ld	ra,40(sp)
    80003912:	7402                	ld	s0,32(sp)
    80003914:	64e2                	ld	s1,24(sp)
    80003916:	6942                	ld	s2,16(sp)
    80003918:	69a2                	ld	s3,8(sp)
    8000391a:	6a02                	ld	s4,0(sp)
    8000391c:	6145                	addi	sp,sp,48
    8000391e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003920:	0009a503          	lw	a0,0(s3)
    80003924:	fffff097          	auipc	ra,0xfffff
    80003928:	690080e7          	jalr	1680(ra) # 80002fb4 <bread>
    8000392c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000392e:	05850493          	addi	s1,a0,88
    80003932:	45850913          	addi	s2,a0,1112
    80003936:	a811                	j	8000394a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003938:	0009a503          	lw	a0,0(s3)
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	8be080e7          	jalr	-1858(ra) # 800031fa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003944:	0491                	addi	s1,s1,4
    80003946:	01248563          	beq	s1,s2,80003950 <itrunc+0x8c>
      if(a[j])
    8000394a:	408c                	lw	a1,0(s1)
    8000394c:	dde5                	beqz	a1,80003944 <itrunc+0x80>
    8000394e:	b7ed                	j	80003938 <itrunc+0x74>
    brelse(bp);
    80003950:	8552                	mv	a0,s4
    80003952:	fffff097          	auipc	ra,0xfffff
    80003956:	792080e7          	jalr	1938(ra) # 800030e4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000395a:	0809a583          	lw	a1,128(s3)
    8000395e:	0009a503          	lw	a0,0(s3)
    80003962:	00000097          	auipc	ra,0x0
    80003966:	898080e7          	jalr	-1896(ra) # 800031fa <bfree>
    ip->addrs[NDIRECT] = 0;
    8000396a:	0809a023          	sw	zero,128(s3)
    8000396e:	bf51                	j	80003902 <itrunc+0x3e>

0000000080003970 <iput>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	e04a                	sd	s2,0(sp)
    8000397a:	1000                	addi	s0,sp,32
    8000397c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000397e:	00028517          	auipc	a0,0x28
    80003982:	e3250513          	addi	a0,a0,-462 # 8002b7b0 <icache>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	250080e7          	jalr	592(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000398e:	4498                	lw	a4,8(s1)
    80003990:	4785                	li	a5,1
    80003992:	02f70363          	beq	a4,a5,800039b8 <iput+0x48>
  ip->ref--;
    80003996:	449c                	lw	a5,8(s1)
    80003998:	37fd                	addiw	a5,a5,-1
    8000399a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000399c:	00028517          	auipc	a0,0x28
    800039a0:	e1450513          	addi	a0,a0,-492 # 8002b7b0 <icache>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	2e6080e7          	jalr	742(ra) # 80000c8a <release>
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6902                	ld	s2,0(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b8:	40bc                	lw	a5,64(s1)
    800039ba:	dff1                	beqz	a5,80003996 <iput+0x26>
    800039bc:	04a49783          	lh	a5,74(s1)
    800039c0:	fbf9                	bnez	a5,80003996 <iput+0x26>
    acquiresleep(&ip->lock);
    800039c2:	01048913          	addi	s2,s1,16
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	ac0080e7          	jalr	-1344(ra) # 80004488 <acquiresleep>
    release(&icache.lock);
    800039d0:	00028517          	auipc	a0,0x28
    800039d4:	de050513          	addi	a0,a0,-544 # 8002b7b0 <icache>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
    itrunc(ip);
    800039e0:	8526                	mv	a0,s1
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	ee2080e7          	jalr	-286(ra) # 800038c4 <itrunc>
    ip->type = 0;
    800039ea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ee:	8526                	mv	a0,s1
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	cfc080e7          	jalr	-772(ra) # 800036ec <iupdate>
    ip->valid = 0;
    800039f8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039fc:	854a                	mv	a0,s2
    800039fe:	00001097          	auipc	ra,0x1
    80003a02:	ae0080e7          	jalr	-1312(ra) # 800044de <releasesleep>
    acquire(&icache.lock);
    80003a06:	00028517          	auipc	a0,0x28
    80003a0a:	daa50513          	addi	a0,a0,-598 # 8002b7b0 <icache>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	1c8080e7          	jalr	456(ra) # 80000bd6 <acquire>
    80003a16:	b741                	j	80003996 <iput+0x26>

0000000080003a18 <iunlockput>:
{
    80003a18:	1101                	addi	sp,sp,-32
    80003a1a:	ec06                	sd	ra,24(sp)
    80003a1c:	e822                	sd	s0,16(sp)
    80003a1e:	e426                	sd	s1,8(sp)
    80003a20:	1000                	addi	s0,sp,32
    80003a22:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a24:	00000097          	auipc	ra,0x0
    80003a28:	e54080e7          	jalr	-428(ra) # 80003878 <iunlock>
  iput(ip);
    80003a2c:	8526                	mv	a0,s1
    80003a2e:	00000097          	auipc	ra,0x0
    80003a32:	f42080e7          	jalr	-190(ra) # 80003970 <iput>
}
    80003a36:	60e2                	ld	ra,24(sp)
    80003a38:	6442                	ld	s0,16(sp)
    80003a3a:	64a2                	ld	s1,8(sp)
    80003a3c:	6105                	addi	sp,sp,32
    80003a3e:	8082                	ret

0000000080003a40 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a40:	1141                	addi	sp,sp,-16
    80003a42:	e422                	sd	s0,8(sp)
    80003a44:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a46:	411c                	lw	a5,0(a0)
    80003a48:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a4a:	415c                	lw	a5,4(a0)
    80003a4c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a4e:	04451783          	lh	a5,68(a0)
    80003a52:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a56:	04a51783          	lh	a5,74(a0)
    80003a5a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a5e:	04c56783          	lwu	a5,76(a0)
    80003a62:	e99c                	sd	a5,16(a1)
}
    80003a64:	6422                	ld	s0,8(sp)
    80003a66:	0141                	addi	sp,sp,16
    80003a68:	8082                	ret

0000000080003a6a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a6a:	457c                	lw	a5,76(a0)
    80003a6c:	0ed7e963          	bltu	a5,a3,80003b5e <readi+0xf4>
{
    80003a70:	7159                	addi	sp,sp,-112
    80003a72:	f486                	sd	ra,104(sp)
    80003a74:	f0a2                	sd	s0,96(sp)
    80003a76:	eca6                	sd	s1,88(sp)
    80003a78:	e8ca                	sd	s2,80(sp)
    80003a7a:	e4ce                	sd	s3,72(sp)
    80003a7c:	e0d2                	sd	s4,64(sp)
    80003a7e:	fc56                	sd	s5,56(sp)
    80003a80:	f85a                	sd	s6,48(sp)
    80003a82:	f45e                	sd	s7,40(sp)
    80003a84:	f062                	sd	s8,32(sp)
    80003a86:	ec66                	sd	s9,24(sp)
    80003a88:	e86a                	sd	s10,16(sp)
    80003a8a:	e46e                	sd	s11,8(sp)
    80003a8c:	1880                	addi	s0,sp,112
    80003a8e:	8baa                	mv	s7,a0
    80003a90:	8c2e                	mv	s8,a1
    80003a92:	8ab2                	mv	s5,a2
    80003a94:	84b6                	mv	s1,a3
    80003a96:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a98:	9f35                	addw	a4,a4,a3
    return 0;
    80003a9a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a9c:	0ad76063          	bltu	a4,a3,80003b3c <readi+0xd2>
  if(off + n > ip->size)
    80003aa0:	00e7f463          	bgeu	a5,a4,80003aa8 <readi+0x3e>
    n = ip->size - off;
    80003aa4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa8:	0a0b0963          	beqz	s6,80003b5a <readi+0xf0>
    80003aac:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aae:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ab2:	5cfd                	li	s9,-1
    80003ab4:	a82d                	j	80003aee <readi+0x84>
    80003ab6:	020a1d93          	slli	s11,s4,0x20
    80003aba:	020ddd93          	srli	s11,s11,0x20
    80003abe:	05890613          	addi	a2,s2,88
    80003ac2:	86ee                	mv	a3,s11
    80003ac4:	963a                	add	a2,a2,a4
    80003ac6:	85d6                	mv	a1,s5
    80003ac8:	8562                	mv	a0,s8
    80003aca:	fffff097          	auipc	ra,0xfffff
    80003ace:	9f2080e7          	jalr	-1550(ra) # 800024bc <either_copyout>
    80003ad2:	05950d63          	beq	a0,s9,80003b2c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ad6:	854a                	mv	a0,s2
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	60c080e7          	jalr	1548(ra) # 800030e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae0:	013a09bb          	addw	s3,s4,s3
    80003ae4:	009a04bb          	addw	s1,s4,s1
    80003ae8:	9aee                	add	s5,s5,s11
    80003aea:	0569f763          	bgeu	s3,s6,80003b38 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aee:	000ba903          	lw	s2,0(s7) # fffffffffffff000 <end+0xffffffff7ffcd000>
    80003af2:	00a4d59b          	srliw	a1,s1,0xa
    80003af6:	855e                	mv	a0,s7
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	8b0080e7          	jalr	-1872(ra) # 800033a8 <bmap>
    80003b00:	0005059b          	sext.w	a1,a0
    80003b04:	854a                	mv	a0,s2
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	4ae080e7          	jalr	1198(ra) # 80002fb4 <bread>
    80003b0e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b10:	3ff4f713          	andi	a4,s1,1023
    80003b14:	40ed07bb          	subw	a5,s10,a4
    80003b18:	413b06bb          	subw	a3,s6,s3
    80003b1c:	8a3e                	mv	s4,a5
    80003b1e:	2781                	sext.w	a5,a5
    80003b20:	0006861b          	sext.w	a2,a3
    80003b24:	f8f679e3          	bgeu	a2,a5,80003ab6 <readi+0x4c>
    80003b28:	8a36                	mv	s4,a3
    80003b2a:	b771                	j	80003ab6 <readi+0x4c>
      brelse(bp);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	5b6080e7          	jalr	1462(ra) # 800030e4 <brelse>
      tot = -1;
    80003b36:	59fd                	li	s3,-1
  }
  return tot;
    80003b38:	0009851b          	sext.w	a0,s3
}
    80003b3c:	70a6                	ld	ra,104(sp)
    80003b3e:	7406                	ld	s0,96(sp)
    80003b40:	64e6                	ld	s1,88(sp)
    80003b42:	6946                	ld	s2,80(sp)
    80003b44:	69a6                	ld	s3,72(sp)
    80003b46:	6a06                	ld	s4,64(sp)
    80003b48:	7ae2                	ld	s5,56(sp)
    80003b4a:	7b42                	ld	s6,48(sp)
    80003b4c:	7ba2                	ld	s7,40(sp)
    80003b4e:	7c02                	ld	s8,32(sp)
    80003b50:	6ce2                	ld	s9,24(sp)
    80003b52:	6d42                	ld	s10,16(sp)
    80003b54:	6da2                	ld	s11,8(sp)
    80003b56:	6165                	addi	sp,sp,112
    80003b58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	89da                	mv	s3,s6
    80003b5c:	bff1                	j	80003b38 <readi+0xce>
    return 0;
    80003b5e:	4501                	li	a0,0
}
    80003b60:	8082                	ret

0000000080003b62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b62:	457c                	lw	a5,76(a0)
    80003b64:	10d7e863          	bltu	a5,a3,80003c74 <writei+0x112>
{
    80003b68:	7159                	addi	sp,sp,-112
    80003b6a:	f486                	sd	ra,104(sp)
    80003b6c:	f0a2                	sd	s0,96(sp)
    80003b6e:	eca6                	sd	s1,88(sp)
    80003b70:	e8ca                	sd	s2,80(sp)
    80003b72:	e4ce                	sd	s3,72(sp)
    80003b74:	e0d2                	sd	s4,64(sp)
    80003b76:	fc56                	sd	s5,56(sp)
    80003b78:	f85a                	sd	s6,48(sp)
    80003b7a:	f45e                	sd	s7,40(sp)
    80003b7c:	f062                	sd	s8,32(sp)
    80003b7e:	ec66                	sd	s9,24(sp)
    80003b80:	e86a                	sd	s10,16(sp)
    80003b82:	e46e                	sd	s11,8(sp)
    80003b84:	1880                	addi	s0,sp,112
    80003b86:	8b2a                	mv	s6,a0
    80003b88:	8c2e                	mv	s8,a1
    80003b8a:	8ab2                	mv	s5,a2
    80003b8c:	8936                	mv	s2,a3
    80003b8e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b90:	00e687bb          	addw	a5,a3,a4
    80003b94:	0ed7e263          	bltu	a5,a3,80003c78 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b98:	00043737          	lui	a4,0x43
    80003b9c:	0ef76063          	bltu	a4,a5,80003c7c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba0:	0c0b8863          	beqz	s7,80003c70 <writei+0x10e>
    80003ba4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003baa:	5cfd                	li	s9,-1
    80003bac:	a091                	j	80003bf0 <writei+0x8e>
    80003bae:	02099d93          	slli	s11,s3,0x20
    80003bb2:	020ddd93          	srli	s11,s11,0x20
    80003bb6:	05848513          	addi	a0,s1,88
    80003bba:	86ee                	mv	a3,s11
    80003bbc:	8656                	mv	a2,s5
    80003bbe:	85e2                	mv	a1,s8
    80003bc0:	953a                	add	a0,a0,a4
    80003bc2:	fffff097          	auipc	ra,0xfffff
    80003bc6:	950080e7          	jalr	-1712(ra) # 80002512 <either_copyin>
    80003bca:	07950263          	beq	a0,s9,80003c2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bce:	8526                	mv	a0,s1
    80003bd0:	00000097          	auipc	ra,0x0
    80003bd4:	790080e7          	jalr	1936(ra) # 80004360 <log_write>
    brelse(bp);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	50a080e7          	jalr	1290(ra) # 800030e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be2:	01498a3b          	addw	s4,s3,s4
    80003be6:	0129893b          	addw	s2,s3,s2
    80003bea:	9aee                	add	s5,s5,s11
    80003bec:	057a7663          	bgeu	s4,s7,80003c38 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf0:	000b2483          	lw	s1,0(s6)
    80003bf4:	00a9559b          	srliw	a1,s2,0xa
    80003bf8:	855a                	mv	a0,s6
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	7ae080e7          	jalr	1966(ra) # 800033a8 <bmap>
    80003c02:	0005059b          	sext.w	a1,a0
    80003c06:	8526                	mv	a0,s1
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	3ac080e7          	jalr	940(ra) # 80002fb4 <bread>
    80003c10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	3ff97713          	andi	a4,s2,1023
    80003c16:	40ed07bb          	subw	a5,s10,a4
    80003c1a:	414b86bb          	subw	a3,s7,s4
    80003c1e:	89be                	mv	s3,a5
    80003c20:	2781                	sext.w	a5,a5
    80003c22:	0006861b          	sext.w	a2,a3
    80003c26:	f8f674e3          	bgeu	a2,a5,80003bae <writei+0x4c>
    80003c2a:	89b6                	mv	s3,a3
    80003c2c:	b749                	j	80003bae <writei+0x4c>
      brelse(bp);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	fffff097          	auipc	ra,0xfffff
    80003c34:	4b4080e7          	jalr	1204(ra) # 800030e4 <brelse>
  }

  if(off > ip->size)
    80003c38:	04cb2783          	lw	a5,76(s6)
    80003c3c:	0127f463          	bgeu	a5,s2,80003c44 <writei+0xe2>
    ip->size = off;
    80003c40:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c44:	855a                	mv	a0,s6
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	aa6080e7          	jalr	-1370(ra) # 800036ec <iupdate>

  return tot;
    80003c4e:	000a051b          	sext.w	a0,s4
}
    80003c52:	70a6                	ld	ra,104(sp)
    80003c54:	7406                	ld	s0,96(sp)
    80003c56:	64e6                	ld	s1,88(sp)
    80003c58:	6946                	ld	s2,80(sp)
    80003c5a:	69a6                	ld	s3,72(sp)
    80003c5c:	6a06                	ld	s4,64(sp)
    80003c5e:	7ae2                	ld	s5,56(sp)
    80003c60:	7b42                	ld	s6,48(sp)
    80003c62:	7ba2                	ld	s7,40(sp)
    80003c64:	7c02                	ld	s8,32(sp)
    80003c66:	6ce2                	ld	s9,24(sp)
    80003c68:	6d42                	ld	s10,16(sp)
    80003c6a:	6da2                	ld	s11,8(sp)
    80003c6c:	6165                	addi	sp,sp,112
    80003c6e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c70:	8a5e                	mv	s4,s7
    80003c72:	bfc9                	j	80003c44 <writei+0xe2>
    return -1;
    80003c74:	557d                	li	a0,-1
}
    80003c76:	8082                	ret
    return -1;
    80003c78:	557d                	li	a0,-1
    80003c7a:	bfe1                	j	80003c52 <writei+0xf0>
    return -1;
    80003c7c:	557d                	li	a0,-1
    80003c7e:	bfd1                	j	80003c52 <writei+0xf0>

0000000080003c80 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c80:	1141                	addi	sp,sp,-16
    80003c82:	e406                	sd	ra,8(sp)
    80003c84:	e022                	sd	s0,0(sp)
    80003c86:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c88:	4639                	li	a2,14
    80003c8a:	ffffd097          	auipc	ra,0xffffd
    80003c8e:	124080e7          	jalr	292(ra) # 80000dae <strncmp>
}
    80003c92:	60a2                	ld	ra,8(sp)
    80003c94:	6402                	ld	s0,0(sp)
    80003c96:	0141                	addi	sp,sp,16
    80003c98:	8082                	ret

0000000080003c9a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c9a:	7139                	addi	sp,sp,-64
    80003c9c:	fc06                	sd	ra,56(sp)
    80003c9e:	f822                	sd	s0,48(sp)
    80003ca0:	f426                	sd	s1,40(sp)
    80003ca2:	f04a                	sd	s2,32(sp)
    80003ca4:	ec4e                	sd	s3,24(sp)
    80003ca6:	e852                	sd	s4,16(sp)
    80003ca8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003caa:	04451703          	lh	a4,68(a0)
    80003cae:	4785                	li	a5,1
    80003cb0:	00f71a63          	bne	a4,a5,80003cc4 <dirlookup+0x2a>
    80003cb4:	892a                	mv	s2,a0
    80003cb6:	89ae                	mv	s3,a1
    80003cb8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cba:	457c                	lw	a5,76(a0)
    80003cbc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cbe:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc0:	e79d                	bnez	a5,80003cee <dirlookup+0x54>
    80003cc2:	a8a5                	j	80003d3a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cc4:	00005517          	auipc	a0,0x5
    80003cc8:	8d450513          	addi	a0,a0,-1836 # 80008598 <syscalls+0x1b0>
    80003ccc:	ffffd097          	auipc	ra,0xffffd
    80003cd0:	864080e7          	jalr	-1948(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	8dc50513          	addi	a0,a0,-1828 # 800085b0 <syscalls+0x1c8>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	854080e7          	jalr	-1964(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce4:	24c1                	addiw	s1,s1,16
    80003ce6:	04c92783          	lw	a5,76(s2)
    80003cea:	04f4f763          	bgeu	s1,a5,80003d38 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cee:	4741                	li	a4,16
    80003cf0:	86a6                	mv	a3,s1
    80003cf2:	fc040613          	addi	a2,s0,-64
    80003cf6:	4581                	li	a1,0
    80003cf8:	854a                	mv	a0,s2
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	d70080e7          	jalr	-656(ra) # 80003a6a <readi>
    80003d02:	47c1                	li	a5,16
    80003d04:	fcf518e3          	bne	a0,a5,80003cd4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d08:	fc045783          	lhu	a5,-64(s0)
    80003d0c:	dfe1                	beqz	a5,80003ce4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d0e:	fc240593          	addi	a1,s0,-62
    80003d12:	854e                	mv	a0,s3
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	f6c080e7          	jalr	-148(ra) # 80003c80 <namecmp>
    80003d1c:	f561                	bnez	a0,80003ce4 <dirlookup+0x4a>
      if(poff)
    80003d1e:	000a0463          	beqz	s4,80003d26 <dirlookup+0x8c>
        *poff = off;
    80003d22:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d26:	fc045583          	lhu	a1,-64(s0)
    80003d2a:	00092503          	lw	a0,0(s2)
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	754080e7          	jalr	1876(ra) # 80003482 <iget>
    80003d36:	a011                	j	80003d3a <dirlookup+0xa0>
  return 0;
    80003d38:	4501                	li	a0,0
}
    80003d3a:	70e2                	ld	ra,56(sp)
    80003d3c:	7442                	ld	s0,48(sp)
    80003d3e:	74a2                	ld	s1,40(sp)
    80003d40:	7902                	ld	s2,32(sp)
    80003d42:	69e2                	ld	s3,24(sp)
    80003d44:	6a42                	ld	s4,16(sp)
    80003d46:	6121                	addi	sp,sp,64
    80003d48:	8082                	ret

0000000080003d4a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d4a:	711d                	addi	sp,sp,-96
    80003d4c:	ec86                	sd	ra,88(sp)
    80003d4e:	e8a2                	sd	s0,80(sp)
    80003d50:	e4a6                	sd	s1,72(sp)
    80003d52:	e0ca                	sd	s2,64(sp)
    80003d54:	fc4e                	sd	s3,56(sp)
    80003d56:	f852                	sd	s4,48(sp)
    80003d58:	f456                	sd	s5,40(sp)
    80003d5a:	f05a                	sd	s6,32(sp)
    80003d5c:	ec5e                	sd	s7,24(sp)
    80003d5e:	e862                	sd	s8,16(sp)
    80003d60:	e466                	sd	s9,8(sp)
    80003d62:	1080                	addi	s0,sp,96
    80003d64:	84aa                	mv	s1,a0
    80003d66:	8b2e                	mv	s6,a1
    80003d68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d6a:	00054703          	lbu	a4,0(a0)
    80003d6e:	02f00793          	li	a5,47
    80003d72:	02f70363          	beq	a4,a5,80003d98 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d76:	ffffe097          	auipc	ra,0xffffe
    80003d7a:	c30080e7          	jalr	-976(ra) # 800019a6 <myproc>
    80003d7e:	15053503          	ld	a0,336(a0)
    80003d82:	00000097          	auipc	ra,0x0
    80003d86:	9f6080e7          	jalr	-1546(ra) # 80003778 <idup>
    80003d8a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d8c:	02f00913          	li	s2,47
  len = path - s;
    80003d90:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d92:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d94:	4c05                	li	s8,1
    80003d96:	a865                	j	80003e4e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d98:	4585                	li	a1,1
    80003d9a:	4505                	li	a0,1
    80003d9c:	fffff097          	auipc	ra,0xfffff
    80003da0:	6e6080e7          	jalr	1766(ra) # 80003482 <iget>
    80003da4:	89aa                	mv	s3,a0
    80003da6:	b7dd                	j	80003d8c <namex+0x42>
      iunlockput(ip);
    80003da8:	854e                	mv	a0,s3
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	c6e080e7          	jalr	-914(ra) # 80003a18 <iunlockput>
      return 0;
    80003db2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003db4:	854e                	mv	a0,s3
    80003db6:	60e6                	ld	ra,88(sp)
    80003db8:	6446                	ld	s0,80(sp)
    80003dba:	64a6                	ld	s1,72(sp)
    80003dbc:	6906                	ld	s2,64(sp)
    80003dbe:	79e2                	ld	s3,56(sp)
    80003dc0:	7a42                	ld	s4,48(sp)
    80003dc2:	7aa2                	ld	s5,40(sp)
    80003dc4:	7b02                	ld	s6,32(sp)
    80003dc6:	6be2                	ld	s7,24(sp)
    80003dc8:	6c42                	ld	s8,16(sp)
    80003dca:	6ca2                	ld	s9,8(sp)
    80003dcc:	6125                	addi	sp,sp,96
    80003dce:	8082                	ret
      iunlock(ip);
    80003dd0:	854e                	mv	a0,s3
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	aa6080e7          	jalr	-1370(ra) # 80003878 <iunlock>
      return ip;
    80003dda:	bfe9                	j	80003db4 <namex+0x6a>
      iunlockput(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	c3a080e7          	jalr	-966(ra) # 80003a18 <iunlockput>
      return 0;
    80003de6:	89d2                	mv	s3,s4
    80003de8:	b7f1                	j	80003db4 <namex+0x6a>
  len = path - s;
    80003dea:	40b48633          	sub	a2,s1,a1
    80003dee:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003df2:	094cd463          	bge	s9,s4,80003e7a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003df6:	4639                	li	a2,14
    80003df8:	8556                	mv	a0,s5
    80003dfa:	ffffd097          	auipc	ra,0xffffd
    80003dfe:	f38080e7          	jalr	-200(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	01279763          	bne	a5,s2,80003e14 <namex+0xca>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0xc0>
    ilock(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	9a0080e7          	jalr	-1632(ra) # 800037b6 <ilock>
    if(ip->type != T_DIR){
    80003e1e:	04499783          	lh	a5,68(s3)
    80003e22:	f98793e3          	bne	a5,s8,80003da8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e26:	000b0563          	beqz	s6,80003e30 <namex+0xe6>
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	d3cd                	beqz	a5,80003dd0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e30:	865e                	mv	a2,s7
    80003e32:	85d6                	mv	a1,s5
    80003e34:	854e                	mv	a0,s3
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	e64080e7          	jalr	-412(ra) # 80003c9a <dirlookup>
    80003e3e:	8a2a                	mv	s4,a0
    80003e40:	dd51                	beqz	a0,80003ddc <namex+0x92>
    iunlockput(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	bd4080e7          	jalr	-1068(ra) # 80003a18 <iunlockput>
    ip = next;
    80003e4c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	05279763          	bne	a5,s2,80003ea0 <namex+0x156>
    path++;
    80003e56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	ff278de3          	beq	a5,s2,80003e56 <namex+0x10c>
  if(*path == 0)
    80003e60:	c79d                	beqz	a5,80003e8e <namex+0x144>
    path++;
    80003e62:	85a6                	mv	a1,s1
  len = path - s;
    80003e64:	8a5e                	mv	s4,s7
    80003e66:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e68:	01278963          	beq	a5,s2,80003e7a <namex+0x130>
    80003e6c:	dfbd                	beqz	a5,80003dea <namex+0xa0>
    path++;
    80003e6e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	ff279ce3          	bne	a5,s2,80003e6c <namex+0x122>
    80003e78:	bf8d                	j	80003dea <namex+0xa0>
    memmove(name, s, len);
    80003e7a:	2601                	sext.w	a2,a2
    80003e7c:	8556                	mv	a0,s5
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	eb4080e7          	jalr	-332(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003e86:	9a56                	add	s4,s4,s5
    80003e88:	000a0023          	sb	zero,0(s4)
    80003e8c:	bf9d                	j	80003e02 <namex+0xb8>
  if(nameiparent){
    80003e8e:	f20b03e3          	beqz	s6,80003db4 <namex+0x6a>
    iput(ip);
    80003e92:	854e                	mv	a0,s3
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	adc080e7          	jalr	-1316(ra) # 80003970 <iput>
    return 0;
    80003e9c:	4981                	li	s3,0
    80003e9e:	bf19                	j	80003db4 <namex+0x6a>
  if(*path == 0)
    80003ea0:	d7fd                	beqz	a5,80003e8e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea2:	0004c783          	lbu	a5,0(s1)
    80003ea6:	85a6                	mv	a1,s1
    80003ea8:	b7d1                	j	80003e6c <namex+0x122>

0000000080003eaa <dirlink>:
{
    80003eaa:	7139                	addi	sp,sp,-64
    80003eac:	fc06                	sd	ra,56(sp)
    80003eae:	f822                	sd	s0,48(sp)
    80003eb0:	f426                	sd	s1,40(sp)
    80003eb2:	f04a                	sd	s2,32(sp)
    80003eb4:	ec4e                	sd	s3,24(sp)
    80003eb6:	e852                	sd	s4,16(sp)
    80003eb8:	0080                	addi	s0,sp,64
    80003eba:	892a                	mv	s2,a0
    80003ebc:	8a2e                	mv	s4,a1
    80003ebe:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ec0:	4601                	li	a2,0
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	dd8080e7          	jalr	-552(ra) # 80003c9a <dirlookup>
    80003eca:	e93d                	bnez	a0,80003f40 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ecc:	04c92483          	lw	s1,76(s2)
    80003ed0:	c49d                	beqz	s1,80003efe <dirlink+0x54>
    80003ed2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed4:	4741                	li	a4,16
    80003ed6:	86a6                	mv	a3,s1
    80003ed8:	fc040613          	addi	a2,s0,-64
    80003edc:	4581                	li	a1,0
    80003ede:	854a                	mv	a0,s2
    80003ee0:	00000097          	auipc	ra,0x0
    80003ee4:	b8a080e7          	jalr	-1142(ra) # 80003a6a <readi>
    80003ee8:	47c1                	li	a5,16
    80003eea:	06f51163          	bne	a0,a5,80003f4c <dirlink+0xa2>
    if(de.inum == 0)
    80003eee:	fc045783          	lhu	a5,-64(s0)
    80003ef2:	c791                	beqz	a5,80003efe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef4:	24c1                	addiw	s1,s1,16
    80003ef6:	04c92783          	lw	a5,76(s2)
    80003efa:	fcf4ede3          	bltu	s1,a5,80003ed4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efe:	4639                	li	a2,14
    80003f00:	85d2                	mv	a1,s4
    80003f02:	fc240513          	addi	a0,s0,-62
    80003f06:	ffffd097          	auipc	ra,0xffffd
    80003f0a:	ee4080e7          	jalr	-284(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003f0e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f12:	4741                	li	a4,16
    80003f14:	86a6                	mv	a3,s1
    80003f16:	fc040613          	addi	a2,s0,-64
    80003f1a:	4581                	li	a1,0
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	c44080e7          	jalr	-956(ra) # 80003b62 <writei>
    80003f26:	872a                	mv	a4,a0
    80003f28:	47c1                	li	a5,16
  return 0;
    80003f2a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f2c:	02f71863          	bne	a4,a5,80003f5c <dirlink+0xb2>
}
    80003f30:	70e2                	ld	ra,56(sp)
    80003f32:	7442                	ld	s0,48(sp)
    80003f34:	74a2                	ld	s1,40(sp)
    80003f36:	7902                	ld	s2,32(sp)
    80003f38:	69e2                	ld	s3,24(sp)
    80003f3a:	6a42                	ld	s4,16(sp)
    80003f3c:	6121                	addi	sp,sp,64
    80003f3e:	8082                	ret
    iput(ip);
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	a30080e7          	jalr	-1488(ra) # 80003970 <iput>
    return -1;
    80003f48:	557d                	li	a0,-1
    80003f4a:	b7dd                	j	80003f30 <dirlink+0x86>
      panic("dirlink read");
    80003f4c:	00004517          	auipc	a0,0x4
    80003f50:	67450513          	addi	a0,a0,1652 # 800085c0 <syscalls+0x1d8>
    80003f54:	ffffc097          	auipc	ra,0xffffc
    80003f58:	5dc080e7          	jalr	1500(ra) # 80000530 <panic>
    panic("dirlink");
    80003f5c:	00004517          	auipc	a0,0x4
    80003f60:	77450513          	addi	a0,a0,1908 # 800086d0 <syscalls+0x2e8>
    80003f64:	ffffc097          	auipc	ra,0xffffc
    80003f68:	5cc080e7          	jalr	1484(ra) # 80000530 <panic>

0000000080003f6c <namei>:

struct inode*
namei(char *path)
{
    80003f6c:	1101                	addi	sp,sp,-32
    80003f6e:	ec06                	sd	ra,24(sp)
    80003f70:	e822                	sd	s0,16(sp)
    80003f72:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f74:	fe040613          	addi	a2,s0,-32
    80003f78:	4581                	li	a1,0
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	dd0080e7          	jalr	-560(ra) # 80003d4a <namex>
}
    80003f82:	60e2                	ld	ra,24(sp)
    80003f84:	6442                	ld	s0,16(sp)
    80003f86:	6105                	addi	sp,sp,32
    80003f88:	8082                	ret

0000000080003f8a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f8a:	1141                	addi	sp,sp,-16
    80003f8c:	e406                	sd	ra,8(sp)
    80003f8e:	e022                	sd	s0,0(sp)
    80003f90:	0800                	addi	s0,sp,16
    80003f92:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f94:	4585                	li	a1,1
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	db4080e7          	jalr	-588(ra) # 80003d4a <namex>
}
    80003f9e:	60a2                	ld	ra,8(sp)
    80003fa0:	6402                	ld	s0,0(sp)
    80003fa2:	0141                	addi	sp,sp,16
    80003fa4:	8082                	ret

0000000080003fa6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fa6:	1101                	addi	sp,sp,-32
    80003fa8:	ec06                	sd	ra,24(sp)
    80003faa:	e822                	sd	s0,16(sp)
    80003fac:	e426                	sd	s1,8(sp)
    80003fae:	e04a                	sd	s2,0(sp)
    80003fb0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb2:	00029917          	auipc	s2,0x29
    80003fb6:	2a690913          	addi	s2,s2,678 # 8002d258 <log>
    80003fba:	01892583          	lw	a1,24(s2)
    80003fbe:	02892503          	lw	a0,40(s2)
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	ff2080e7          	jalr	-14(ra) # 80002fb4 <bread>
    80003fca:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fcc:	02c92683          	lw	a3,44(s2)
    80003fd0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd2:	02d05763          	blez	a3,80004000 <write_head+0x5a>
    80003fd6:	00029797          	auipc	a5,0x29
    80003fda:	2b278793          	addi	a5,a5,690 # 8002d288 <log+0x30>
    80003fde:	05c50713          	addi	a4,a0,92
    80003fe2:	36fd                	addiw	a3,a3,-1
    80003fe4:	1682                	slli	a3,a3,0x20
    80003fe6:	9281                	srli	a3,a3,0x20
    80003fe8:	068a                	slli	a3,a3,0x2
    80003fea:	00029617          	auipc	a2,0x29
    80003fee:	2a260613          	addi	a2,a2,674 # 8002d28c <log+0x34>
    80003ff2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ff4:	4390                	lw	a2,0(a5)
    80003ff6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ff8:	0791                	addi	a5,a5,4
    80003ffa:	0711                	addi	a4,a4,4
    80003ffc:	fed79ce3          	bne	a5,a3,80003ff4 <write_head+0x4e>
  }
  bwrite(buf);
    80004000:	8526                	mv	a0,s1
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	0a4080e7          	jalr	164(ra) # 800030a6 <bwrite>
  brelse(buf);
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	0d8080e7          	jalr	216(ra) # 800030e4 <brelse>
}
    80004014:	60e2                	ld	ra,24(sp)
    80004016:	6442                	ld	s0,16(sp)
    80004018:	64a2                	ld	s1,8(sp)
    8000401a:	6902                	ld	s2,0(sp)
    8000401c:	6105                	addi	sp,sp,32
    8000401e:	8082                	ret

0000000080004020 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004020:	00029797          	auipc	a5,0x29
    80004024:	2647a783          	lw	a5,612(a5) # 8002d284 <log+0x2c>
    80004028:	0af05d63          	blez	a5,800040e2 <install_trans+0xc2>
{
    8000402c:	7139                	addi	sp,sp,-64
    8000402e:	fc06                	sd	ra,56(sp)
    80004030:	f822                	sd	s0,48(sp)
    80004032:	f426                	sd	s1,40(sp)
    80004034:	f04a                	sd	s2,32(sp)
    80004036:	ec4e                	sd	s3,24(sp)
    80004038:	e852                	sd	s4,16(sp)
    8000403a:	e456                	sd	s5,8(sp)
    8000403c:	e05a                	sd	s6,0(sp)
    8000403e:	0080                	addi	s0,sp,64
    80004040:	8b2a                	mv	s6,a0
    80004042:	00029a97          	auipc	s5,0x29
    80004046:	246a8a93          	addi	s5,s5,582 # 8002d288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000404c:	00029997          	auipc	s3,0x29
    80004050:	20c98993          	addi	s3,s3,524 # 8002d258 <log>
    80004054:	a035                	j	80004080 <install_trans+0x60>
      bunpin(dbuf);
    80004056:	8526                	mv	a0,s1
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	166080e7          	jalr	358(ra) # 800031be <bunpin>
    brelse(lbuf);
    80004060:	854a                	mv	a0,s2
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	082080e7          	jalr	130(ra) # 800030e4 <brelse>
    brelse(dbuf);
    8000406a:	8526                	mv	a0,s1
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	078080e7          	jalr	120(ra) # 800030e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004074:	2a05                	addiw	s4,s4,1
    80004076:	0a91                	addi	s5,s5,4
    80004078:	02c9a783          	lw	a5,44(s3)
    8000407c:	04fa5963          	bge	s4,a5,800040ce <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004080:	0189a583          	lw	a1,24(s3)
    80004084:	014585bb          	addw	a1,a1,s4
    80004088:	2585                	addiw	a1,a1,1
    8000408a:	0289a503          	lw	a0,40(s3)
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	f26080e7          	jalr	-218(ra) # 80002fb4 <bread>
    80004096:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004098:	000aa583          	lw	a1,0(s5)
    8000409c:	0289a503          	lw	a0,40(s3)
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	f14080e7          	jalr	-236(ra) # 80002fb4 <bread>
    800040a8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040aa:	40000613          	li	a2,1024
    800040ae:	05890593          	addi	a1,s2,88
    800040b2:	05850513          	addi	a0,a0,88
    800040b6:	ffffd097          	auipc	ra,0xffffd
    800040ba:	c7c080e7          	jalr	-900(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040be:	8526                	mv	a0,s1
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	fe6080e7          	jalr	-26(ra) # 800030a6 <bwrite>
    if(recovering == 0)
    800040c8:	f80b1ce3          	bnez	s6,80004060 <install_trans+0x40>
    800040cc:	b769                	j	80004056 <install_trans+0x36>
}
    800040ce:	70e2                	ld	ra,56(sp)
    800040d0:	7442                	ld	s0,48(sp)
    800040d2:	74a2                	ld	s1,40(sp)
    800040d4:	7902                	ld	s2,32(sp)
    800040d6:	69e2                	ld	s3,24(sp)
    800040d8:	6a42                	ld	s4,16(sp)
    800040da:	6aa2                	ld	s5,8(sp)
    800040dc:	6b02                	ld	s6,0(sp)
    800040de:	6121                	addi	sp,sp,64
    800040e0:	8082                	ret
    800040e2:	8082                	ret

00000000800040e4 <initlog>:
{
    800040e4:	7179                	addi	sp,sp,-48
    800040e6:	f406                	sd	ra,40(sp)
    800040e8:	f022                	sd	s0,32(sp)
    800040ea:	ec26                	sd	s1,24(sp)
    800040ec:	e84a                	sd	s2,16(sp)
    800040ee:	e44e                	sd	s3,8(sp)
    800040f0:	1800                	addi	s0,sp,48
    800040f2:	892a                	mv	s2,a0
    800040f4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040f6:	00029497          	auipc	s1,0x29
    800040fa:	16248493          	addi	s1,s1,354 # 8002d258 <log>
    800040fe:	00004597          	auipc	a1,0x4
    80004102:	4d258593          	addi	a1,a1,1234 # 800085d0 <syscalls+0x1e8>
    80004106:	8526                	mv	a0,s1
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	a3e080e7          	jalr	-1474(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004110:	0149a583          	lw	a1,20(s3)
    80004114:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004116:	0109a783          	lw	a5,16(s3)
    8000411a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000411c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004120:	854a                	mv	a0,s2
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	e92080e7          	jalr	-366(ra) # 80002fb4 <bread>
  log.lh.n = lh->n;
    8000412a:	4d3c                	lw	a5,88(a0)
    8000412c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000412e:	02f05563          	blez	a5,80004158 <initlog+0x74>
    80004132:	05c50713          	addi	a4,a0,92
    80004136:	00029697          	auipc	a3,0x29
    8000413a:	15268693          	addi	a3,a3,338 # 8002d288 <log+0x30>
    8000413e:	37fd                	addiw	a5,a5,-1
    80004140:	1782                	slli	a5,a5,0x20
    80004142:	9381                	srli	a5,a5,0x20
    80004144:	078a                	slli	a5,a5,0x2
    80004146:	06050613          	addi	a2,a0,96
    8000414a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000414c:	4310                	lw	a2,0(a4)
    8000414e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004150:	0711                	addi	a4,a4,4
    80004152:	0691                	addi	a3,a3,4
    80004154:	fef71ce3          	bne	a4,a5,8000414c <initlog+0x68>
  brelse(buf);
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	f8c080e7          	jalr	-116(ra) # 800030e4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004160:	4505                	li	a0,1
    80004162:	00000097          	auipc	ra,0x0
    80004166:	ebe080e7          	jalr	-322(ra) # 80004020 <install_trans>
  log.lh.n = 0;
    8000416a:	00029797          	auipc	a5,0x29
    8000416e:	1007ad23          	sw	zero,282(a5) # 8002d284 <log+0x2c>
  write_head(); // clear the log
    80004172:	00000097          	auipc	ra,0x0
    80004176:	e34080e7          	jalr	-460(ra) # 80003fa6 <write_head>
}
    8000417a:	70a2                	ld	ra,40(sp)
    8000417c:	7402                	ld	s0,32(sp)
    8000417e:	64e2                	ld	s1,24(sp)
    80004180:	6942                	ld	s2,16(sp)
    80004182:	69a2                	ld	s3,8(sp)
    80004184:	6145                	addi	sp,sp,48
    80004186:	8082                	ret

0000000080004188 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004188:	1101                	addi	sp,sp,-32
    8000418a:	ec06                	sd	ra,24(sp)
    8000418c:	e822                	sd	s0,16(sp)
    8000418e:	e426                	sd	s1,8(sp)
    80004190:	e04a                	sd	s2,0(sp)
    80004192:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004194:	00029517          	auipc	a0,0x29
    80004198:	0c450513          	addi	a0,a0,196 # 8002d258 <log>
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	a3a080e7          	jalr	-1478(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041a4:	00029497          	auipc	s1,0x29
    800041a8:	0b448493          	addi	s1,s1,180 # 8002d258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ac:	4979                	li	s2,30
    800041ae:	a039                	j	800041bc <begin_op+0x34>
      sleep(&log, &log.lock);
    800041b0:	85a6                	mv	a1,s1
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffe097          	auipc	ra,0xffffe
    800041b8:	0a6080e7          	jalr	166(ra) # 8000225a <sleep>
    if(log.committing){
    800041bc:	50dc                	lw	a5,36(s1)
    800041be:	fbed                	bnez	a5,800041b0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041c0:	509c                	lw	a5,32(s1)
    800041c2:	0017871b          	addiw	a4,a5,1
    800041c6:	0007069b          	sext.w	a3,a4
    800041ca:	0027179b          	slliw	a5,a4,0x2
    800041ce:	9fb9                	addw	a5,a5,a4
    800041d0:	0017979b          	slliw	a5,a5,0x1
    800041d4:	54d8                	lw	a4,44(s1)
    800041d6:	9fb9                	addw	a5,a5,a4
    800041d8:	00f95963          	bge	s2,a5,800041ea <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041dc:	85a6                	mv	a1,s1
    800041de:	8526                	mv	a0,s1
    800041e0:	ffffe097          	auipc	ra,0xffffe
    800041e4:	07a080e7          	jalr	122(ra) # 8000225a <sleep>
    800041e8:	bfd1                	j	800041bc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041ea:	00029517          	auipc	a0,0x29
    800041ee:	06e50513          	addi	a0,a0,110 # 8002d258 <log>
    800041f2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	a96080e7          	jalr	-1386(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041fc:	60e2                	ld	ra,24(sp)
    800041fe:	6442                	ld	s0,16(sp)
    80004200:	64a2                	ld	s1,8(sp)
    80004202:	6902                	ld	s2,0(sp)
    80004204:	6105                	addi	sp,sp,32
    80004206:	8082                	ret

0000000080004208 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004208:	7139                	addi	sp,sp,-64
    8000420a:	fc06                	sd	ra,56(sp)
    8000420c:	f822                	sd	s0,48(sp)
    8000420e:	f426                	sd	s1,40(sp)
    80004210:	f04a                	sd	s2,32(sp)
    80004212:	ec4e                	sd	s3,24(sp)
    80004214:	e852                	sd	s4,16(sp)
    80004216:	e456                	sd	s5,8(sp)
    80004218:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000421a:	00029497          	auipc	s1,0x29
    8000421e:	03e48493          	addi	s1,s1,62 # 8002d258 <log>
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	9b2080e7          	jalr	-1614(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000422c:	509c                	lw	a5,32(s1)
    8000422e:	37fd                	addiw	a5,a5,-1
    80004230:	0007891b          	sext.w	s2,a5
    80004234:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004236:	50dc                	lw	a5,36(s1)
    80004238:	efb9                	bnez	a5,80004296 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000423a:	06091663          	bnez	s2,800042a6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000423e:	00029497          	auipc	s1,0x29
    80004242:	01a48493          	addi	s1,s1,26 # 8002d258 <log>
    80004246:	4785                	li	a5,1
    80004248:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffd097          	auipc	ra,0xffffd
    80004250:	a3e080e7          	jalr	-1474(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004254:	54dc                	lw	a5,44(s1)
    80004256:	06f04763          	bgtz	a5,800042c4 <end_op+0xbc>
    acquire(&log.lock);
    8000425a:	00029497          	auipc	s1,0x29
    8000425e:	ffe48493          	addi	s1,s1,-2 # 8002d258 <log>
    80004262:	8526                	mv	a0,s1
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	972080e7          	jalr	-1678(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000426c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffe097          	auipc	ra,0xffffe
    80004276:	16e080e7          	jalr	366(ra) # 800023e0 <wakeup>
    release(&log.lock);
    8000427a:	8526                	mv	a0,s1
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	a0e080e7          	jalr	-1522(ra) # 80000c8a <release>
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6aa2                	ld	s5,8(sp)
    80004292:	6121                	addi	sp,sp,64
    80004294:	8082                	ret
    panic("log.committing");
    80004296:	00004517          	auipc	a0,0x4
    8000429a:	34250513          	addi	a0,a0,834 # 800085d8 <syscalls+0x1f0>
    8000429e:	ffffc097          	auipc	ra,0xffffc
    800042a2:	292080e7          	jalr	658(ra) # 80000530 <panic>
    wakeup(&log);
    800042a6:	00029497          	auipc	s1,0x29
    800042aa:	fb248493          	addi	s1,s1,-78 # 8002d258 <log>
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffe097          	auipc	ra,0xffffe
    800042b4:	130080e7          	jalr	304(ra) # 800023e0 <wakeup>
  release(&log.lock);
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	9d0080e7          	jalr	-1584(ra) # 80000c8a <release>
  if(do_commit){
    800042c2:	b7c9                	j	80004284 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c4:	00029a97          	auipc	s5,0x29
    800042c8:	fc4a8a93          	addi	s5,s5,-60 # 8002d288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042cc:	00029a17          	auipc	s4,0x29
    800042d0:	f8ca0a13          	addi	s4,s4,-116 # 8002d258 <log>
    800042d4:	018a2583          	lw	a1,24(s4)
    800042d8:	012585bb          	addw	a1,a1,s2
    800042dc:	2585                	addiw	a1,a1,1
    800042de:	028a2503          	lw	a0,40(s4)
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	cd2080e7          	jalr	-814(ra) # 80002fb4 <bread>
    800042ea:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ec:	000aa583          	lw	a1,0(s5)
    800042f0:	028a2503          	lw	a0,40(s4)
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	cc0080e7          	jalr	-832(ra) # 80002fb4 <bread>
    800042fc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042fe:	40000613          	li	a2,1024
    80004302:	05850593          	addi	a1,a0,88
    80004306:	05848513          	addi	a0,s1,88
    8000430a:	ffffd097          	auipc	ra,0xffffd
    8000430e:	a28080e7          	jalr	-1496(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    80004312:	8526                	mv	a0,s1
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	d92080e7          	jalr	-622(ra) # 800030a6 <bwrite>
    brelse(from);
    8000431c:	854e                	mv	a0,s3
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	dc6080e7          	jalr	-570(ra) # 800030e4 <brelse>
    brelse(to);
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	dbc080e7          	jalr	-580(ra) # 800030e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004330:	2905                	addiw	s2,s2,1
    80004332:	0a91                	addi	s5,s5,4
    80004334:	02ca2783          	lw	a5,44(s4)
    80004338:	f8f94ee3          	blt	s2,a5,800042d4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	c6a080e7          	jalr	-918(ra) # 80003fa6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004344:	4501                	li	a0,0
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	cda080e7          	jalr	-806(ra) # 80004020 <install_trans>
    log.lh.n = 0;
    8000434e:	00029797          	auipc	a5,0x29
    80004352:	f207ab23          	sw	zero,-202(a5) # 8002d284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	c50080e7          	jalr	-944(ra) # 80003fa6 <write_head>
    8000435e:	bdf5                	j	8000425a <end_op+0x52>

0000000080004360 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004360:	1101                	addi	sp,sp,-32
    80004362:	ec06                	sd	ra,24(sp)
    80004364:	e822                	sd	s0,16(sp)
    80004366:	e426                	sd	s1,8(sp)
    80004368:	e04a                	sd	s2,0(sp)
    8000436a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000436c:	00029717          	auipc	a4,0x29
    80004370:	f1872703          	lw	a4,-232(a4) # 8002d284 <log+0x2c>
    80004374:	47f5                	li	a5,29
    80004376:	08e7c063          	blt	a5,a4,800043f6 <log_write+0x96>
    8000437a:	84aa                	mv	s1,a0
    8000437c:	00029797          	auipc	a5,0x29
    80004380:	ef87a783          	lw	a5,-264(a5) # 8002d274 <log+0x1c>
    80004384:	37fd                	addiw	a5,a5,-1
    80004386:	06f75863          	bge	a4,a5,800043f6 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000438a:	00029797          	auipc	a5,0x29
    8000438e:	eee7a783          	lw	a5,-274(a5) # 8002d278 <log+0x20>
    80004392:	06f05a63          	blez	a5,80004406 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004396:	00029917          	auipc	s2,0x29
    8000439a:	ec290913          	addi	s2,s2,-318 # 8002d258 <log>
    8000439e:	854a                	mv	a0,s2
    800043a0:	ffffd097          	auipc	ra,0xffffd
    800043a4:	836080e7          	jalr	-1994(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	02c92603          	lw	a2,44(s2)
    800043ac:	06c05563          	blez	a2,80004416 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043b0:	44cc                	lw	a1,12(s1)
    800043b2:	00029717          	auipc	a4,0x29
    800043b6:	ed670713          	addi	a4,a4,-298 # 8002d288 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043bc:	4314                	lw	a3,0(a4)
    800043be:	04b68d63          	beq	a3,a1,80004418 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043c2:	2785                	addiw	a5,a5,1
    800043c4:	0711                	addi	a4,a4,4
    800043c6:	fec79be3          	bne	a5,a2,800043bc <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ca:	0621                	addi	a2,a2,8
    800043cc:	060a                	slli	a2,a2,0x2
    800043ce:	00029797          	auipc	a5,0x29
    800043d2:	e8a78793          	addi	a5,a5,-374 # 8002d258 <log>
    800043d6:	963e                	add	a2,a2,a5
    800043d8:	44dc                	lw	a5,12(s1)
    800043da:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043dc:	8526                	mv	a0,s1
    800043de:	fffff097          	auipc	ra,0xfffff
    800043e2:	da4080e7          	jalr	-604(ra) # 80003182 <bpin>
    log.lh.n++;
    800043e6:	00029717          	auipc	a4,0x29
    800043ea:	e7270713          	addi	a4,a4,-398 # 8002d258 <log>
    800043ee:	575c                	lw	a5,44(a4)
    800043f0:	2785                	addiw	a5,a5,1
    800043f2:	d75c                	sw	a5,44(a4)
    800043f4:	a83d                	j	80004432 <log_write+0xd2>
    panic("too big a transaction");
    800043f6:	00004517          	auipc	a0,0x4
    800043fa:	1f250513          	addi	a0,a0,498 # 800085e8 <syscalls+0x200>
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	132080e7          	jalr	306(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	1fa50513          	addi	a0,a0,506 # 80008600 <syscalls+0x218>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	122080e7          	jalr	290(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004416:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004418:	00878713          	addi	a4,a5,8
    8000441c:	00271693          	slli	a3,a4,0x2
    80004420:	00029717          	auipc	a4,0x29
    80004424:	e3870713          	addi	a4,a4,-456 # 8002d258 <log>
    80004428:	9736                	add	a4,a4,a3
    8000442a:	44d4                	lw	a3,12(s1)
    8000442c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442e:	faf607e3          	beq	a2,a5,800043dc <log_write+0x7c>
  }
  release(&log.lock);
    80004432:	00029517          	auipc	a0,0x29
    80004436:	e2650513          	addi	a0,a0,-474 # 8002d258 <log>
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	850080e7          	jalr	-1968(ra) # 80000c8a <release>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6902                	ld	s2,0(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret

000000008000444e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
    8000445a:	84aa                	mv	s1,a0
    8000445c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000445e:	00004597          	auipc	a1,0x4
    80004462:	1c258593          	addi	a1,a1,450 # 80008620 <syscalls+0x238>
    80004466:	0521                	addi	a0,a0,8
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>
  lk->name = name;
    80004470:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004474:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004478:	0204a423          	sw	zero,40(s1)
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	64a2                	ld	s1,8(sp)
    80004482:	6902                	ld	s2,0(sp)
    80004484:	6105                	addi	sp,sp,32
    80004486:	8082                	ret

0000000080004488 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004488:	1101                	addi	sp,sp,-32
    8000448a:	ec06                	sd	ra,24(sp)
    8000448c:	e822                	sd	s0,16(sp)
    8000448e:	e426                	sd	s1,8(sp)
    80004490:	e04a                	sd	s2,0(sp)
    80004492:	1000                	addi	s0,sp,32
    80004494:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004496:	00850913          	addi	s2,a0,8
    8000449a:	854a                	mv	a0,s2
    8000449c:	ffffc097          	auipc	ra,0xffffc
    800044a0:	73a080e7          	jalr	1850(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044a4:	409c                	lw	a5,0(s1)
    800044a6:	cb89                	beqz	a5,800044b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a8:	85ca                	mv	a1,s2
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffe097          	auipc	ra,0xffffe
    800044b0:	dae080e7          	jalr	-594(ra) # 8000225a <sleep>
  while (lk->locked) {
    800044b4:	409c                	lw	a5,0(s1)
    800044b6:	fbed                	bnez	a5,800044a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b8:	4785                	li	a5,1
    800044ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	4ea080e7          	jalr	1258(ra) # 800019a6 <myproc>
    800044c4:	5d1c                	lw	a5,56(a0)
    800044c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c8:	854a                	mv	a0,s2
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	7c0080e7          	jalr	1984(ra) # 80000c8a <release>
}
    800044d2:	60e2                	ld	ra,24(sp)
    800044d4:	6442                	ld	s0,16(sp)
    800044d6:	64a2                	ld	s1,8(sp)
    800044d8:	6902                	ld	s2,0(sp)
    800044da:	6105                	addi	sp,sp,32
    800044dc:	8082                	ret

00000000800044de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044de:	1101                	addi	sp,sp,-32
    800044e0:	ec06                	sd	ra,24(sp)
    800044e2:	e822                	sd	s0,16(sp)
    800044e4:	e426                	sd	s1,8(sp)
    800044e6:	e04a                	sd	s2,0(sp)
    800044e8:	1000                	addi	s0,sp,32
    800044ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ec:	00850913          	addi	s2,a0,8
    800044f0:	854a                	mv	a0,s2
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	6e4080e7          	jalr	1764(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004502:	8526                	mv	a0,s1
    80004504:	ffffe097          	auipc	ra,0xffffe
    80004508:	edc080e7          	jalr	-292(ra) # 800023e0 <wakeup>
  release(&lk->lk);
    8000450c:	854a                	mv	a0,s2
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	77c080e7          	jalr	1916(ra) # 80000c8a <release>
}
    80004516:	60e2                	ld	ra,24(sp)
    80004518:	6442                	ld	s0,16(sp)
    8000451a:	64a2                	ld	s1,8(sp)
    8000451c:	6902                	ld	s2,0(sp)
    8000451e:	6105                	addi	sp,sp,32
    80004520:	8082                	ret

0000000080004522 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004522:	7179                	addi	sp,sp,-48
    80004524:	f406                	sd	ra,40(sp)
    80004526:	f022                	sd	s0,32(sp)
    80004528:	ec26                	sd	s1,24(sp)
    8000452a:	e84a                	sd	s2,16(sp)
    8000452c:	e44e                	sd	s3,8(sp)
    8000452e:	1800                	addi	s0,sp,48
    80004530:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004532:	00850913          	addi	s2,a0,8
    80004536:	854a                	mv	a0,s2
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	69e080e7          	jalr	1694(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004540:	409c                	lw	a5,0(s1)
    80004542:	ef99                	bnez	a5,80004560 <holdingsleep+0x3e>
    80004544:	4481                	li	s1,0
  release(&lk->lk);
    80004546:	854a                	mv	a0,s2
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	742080e7          	jalr	1858(ra) # 80000c8a <release>
  return r;
}
    80004550:	8526                	mv	a0,s1
    80004552:	70a2                	ld	ra,40(sp)
    80004554:	7402                	ld	s0,32(sp)
    80004556:	64e2                	ld	s1,24(sp)
    80004558:	6942                	ld	s2,16(sp)
    8000455a:	69a2                	ld	s3,8(sp)
    8000455c:	6145                	addi	sp,sp,48
    8000455e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004560:	0284a983          	lw	s3,40(s1)
    80004564:	ffffd097          	auipc	ra,0xffffd
    80004568:	442080e7          	jalr	1090(ra) # 800019a6 <myproc>
    8000456c:	5d04                	lw	s1,56(a0)
    8000456e:	413484b3          	sub	s1,s1,s3
    80004572:	0014b493          	seqz	s1,s1
    80004576:	bfc1                	j	80004546 <holdingsleep+0x24>

0000000080004578 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004578:	1141                	addi	sp,sp,-16
    8000457a:	e406                	sd	ra,8(sp)
    8000457c:	e022                	sd	s0,0(sp)
    8000457e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004580:	00004597          	auipc	a1,0x4
    80004584:	0b058593          	addi	a1,a1,176 # 80008630 <syscalls+0x248>
    80004588:	00029517          	auipc	a0,0x29
    8000458c:	e1850513          	addi	a0,a0,-488 # 8002d3a0 <ftable>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	5b6080e7          	jalr	1462(ra) # 80000b46 <initlock>
}
    80004598:	60a2                	ld	ra,8(sp)
    8000459a:	6402                	ld	s0,0(sp)
    8000459c:	0141                	addi	sp,sp,16
    8000459e:	8082                	ret

00000000800045a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045aa:	00029517          	auipc	a0,0x29
    800045ae:	df650513          	addi	a0,a0,-522 # 8002d3a0 <ftable>
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	624080e7          	jalr	1572(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ba:	00029497          	auipc	s1,0x29
    800045be:	dfe48493          	addi	s1,s1,-514 # 8002d3b8 <ftable+0x18>
    800045c2:	0002a717          	auipc	a4,0x2a
    800045c6:	d9670713          	addi	a4,a4,-618 # 8002e358 <ftable+0xfb8>
    if(f->ref == 0){
    800045ca:	40dc                	lw	a5,4(s1)
    800045cc:	cf99                	beqz	a5,800045ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ce:	02848493          	addi	s1,s1,40
    800045d2:	fee49ce3          	bne	s1,a4,800045ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d6:	00029517          	auipc	a0,0x29
    800045da:	dca50513          	addi	a0,a0,-566 # 8002d3a0 <ftable>
    800045de:	ffffc097          	auipc	ra,0xffffc
    800045e2:	6ac080e7          	jalr	1708(ra) # 80000c8a <release>
  return 0;
    800045e6:	4481                	li	s1,0
    800045e8:	a819                	j	800045fe <filealloc+0x5e>
      f->ref = 1;
    800045ea:	4785                	li	a5,1
    800045ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ee:	00029517          	auipc	a0,0x29
    800045f2:	db250513          	addi	a0,a0,-590 # 8002d3a0 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	694080e7          	jalr	1684(ra) # 80000c8a <release>
}
    800045fe:	8526                	mv	a0,s1
    80004600:	60e2                	ld	ra,24(sp)
    80004602:	6442                	ld	s0,16(sp)
    80004604:	64a2                	ld	s1,8(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	e426                	sd	s1,8(sp)
    80004612:	1000                	addi	s0,sp,32
    80004614:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004616:	00029517          	auipc	a0,0x29
    8000461a:	d8a50513          	addi	a0,a0,-630 # 8002d3a0 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	5b8080e7          	jalr	1464(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004626:	40dc                	lw	a5,4(s1)
    80004628:	02f05263          	blez	a5,8000464c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000462c:	2785                	addiw	a5,a5,1
    8000462e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004630:	00029517          	auipc	a0,0x29
    80004634:	d7050513          	addi	a0,a0,-656 # 8002d3a0 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
  return f;
}
    80004640:	8526                	mv	a0,s1
    80004642:	60e2                	ld	ra,24(sp)
    80004644:	6442                	ld	s0,16(sp)
    80004646:	64a2                	ld	s1,8(sp)
    80004648:	6105                	addi	sp,sp,32
    8000464a:	8082                	ret
    panic("filedup");
    8000464c:	00004517          	auipc	a0,0x4
    80004650:	fec50513          	addi	a0,a0,-20 # 80008638 <syscalls+0x250>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	edc080e7          	jalr	-292(ra) # 80000530 <panic>

000000008000465c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000465c:	7139                	addi	sp,sp,-64
    8000465e:	fc06                	sd	ra,56(sp)
    80004660:	f822                	sd	s0,48(sp)
    80004662:	f426                	sd	s1,40(sp)
    80004664:	f04a                	sd	s2,32(sp)
    80004666:	ec4e                	sd	s3,24(sp)
    80004668:	e852                	sd	s4,16(sp)
    8000466a:	e456                	sd	s5,8(sp)
    8000466c:	0080                	addi	s0,sp,64
    8000466e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004670:	00029517          	auipc	a0,0x29
    80004674:	d3050513          	addi	a0,a0,-720 # 8002d3a0 <ftable>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	55e080e7          	jalr	1374(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004680:	40dc                	lw	a5,4(s1)
    80004682:	06f05163          	blez	a5,800046e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004686:	37fd                	addiw	a5,a5,-1
    80004688:	0007871b          	sext.w	a4,a5
    8000468c:	c0dc                	sw	a5,4(s1)
    8000468e:	06e04363          	bgtz	a4,800046f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004692:	0004a903          	lw	s2,0(s1)
    80004696:	0094ca83          	lbu	s5,9(s1)
    8000469a:	0104ba03          	ld	s4,16(s1)
    8000469e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046aa:	00029517          	auipc	a0,0x29
    800046ae:	cf650513          	addi	a0,a0,-778 # 8002d3a0 <ftable>
    800046b2:	ffffc097          	auipc	ra,0xffffc
    800046b6:	5d8080e7          	jalr	1496(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046ba:	4785                	li	a5,1
    800046bc:	04f90d63          	beq	s2,a5,80004716 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046c0:	3979                	addiw	s2,s2,-2
    800046c2:	4785                	li	a5,1
    800046c4:	0527e063          	bltu	a5,s2,80004704 <fileclose+0xa8>
    begin_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	ac0080e7          	jalr	-1344(ra) # 80004188 <begin_op>
    iput(ff.ip);
    800046d0:	854e                	mv	a0,s3
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	29e080e7          	jalr	670(ra) # 80003970 <iput>
    end_op();
    800046da:	00000097          	auipc	ra,0x0
    800046de:	b2e080e7          	jalr	-1234(ra) # 80004208 <end_op>
    800046e2:	a00d                	j	80004704 <fileclose+0xa8>
    panic("fileclose");
    800046e4:	00004517          	auipc	a0,0x4
    800046e8:	f5c50513          	addi	a0,a0,-164 # 80008640 <syscalls+0x258>
    800046ec:	ffffc097          	auipc	ra,0xffffc
    800046f0:	e44080e7          	jalr	-444(ra) # 80000530 <panic>
    release(&ftable.lock);
    800046f4:	00029517          	auipc	a0,0x29
    800046f8:	cac50513          	addi	a0,a0,-852 # 8002d3a0 <ftable>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	58e080e7          	jalr	1422(ra) # 80000c8a <release>
  }
}
    80004704:	70e2                	ld	ra,56(sp)
    80004706:	7442                	ld	s0,48(sp)
    80004708:	74a2                	ld	s1,40(sp)
    8000470a:	7902                	ld	s2,32(sp)
    8000470c:	69e2                	ld	s3,24(sp)
    8000470e:	6a42                	ld	s4,16(sp)
    80004710:	6aa2                	ld	s5,8(sp)
    80004712:	6121                	addi	sp,sp,64
    80004714:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004716:	85d6                	mv	a1,s5
    80004718:	8552                	mv	a0,s4
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	34c080e7          	jalr	844(ra) # 80004a66 <pipeclose>
    80004722:	b7cd                	j	80004704 <fileclose+0xa8>

0000000080004724 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004724:	715d                	addi	sp,sp,-80
    80004726:	e486                	sd	ra,72(sp)
    80004728:	e0a2                	sd	s0,64(sp)
    8000472a:	fc26                	sd	s1,56(sp)
    8000472c:	f84a                	sd	s2,48(sp)
    8000472e:	f44e                	sd	s3,40(sp)
    80004730:	0880                	addi	s0,sp,80
    80004732:	84aa                	mv	s1,a0
    80004734:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004736:	ffffd097          	auipc	ra,0xffffd
    8000473a:	270080e7          	jalr	624(ra) # 800019a6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000473e:	409c                	lw	a5,0(s1)
    80004740:	37f9                	addiw	a5,a5,-2
    80004742:	4705                	li	a4,1
    80004744:	04f76763          	bltu	a4,a5,80004792 <filestat+0x6e>
    80004748:	892a                	mv	s2,a0
    ilock(f->ip);
    8000474a:	6c88                	ld	a0,24(s1)
    8000474c:	fffff097          	auipc	ra,0xfffff
    80004750:	06a080e7          	jalr	106(ra) # 800037b6 <ilock>
    stati(f->ip, &st);
    80004754:	fb840593          	addi	a1,s0,-72
    80004758:	6c88                	ld	a0,24(s1)
    8000475a:	fffff097          	auipc	ra,0xfffff
    8000475e:	2e6080e7          	jalr	742(ra) # 80003a40 <stati>
    iunlock(f->ip);
    80004762:	6c88                	ld	a0,24(s1)
    80004764:	fffff097          	auipc	ra,0xfffff
    80004768:	114080e7          	jalr	276(ra) # 80003878 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000476c:	46e1                	li	a3,24
    8000476e:	fb840613          	addi	a2,s0,-72
    80004772:	85ce                	mv	a1,s3
    80004774:	05093503          	ld	a0,80(s2)
    80004778:	ffffd097          	auipc	ra,0xffffd
    8000477c:	ec4080e7          	jalr	-316(ra) # 8000163c <copyout>
    80004780:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004784:	60a6                	ld	ra,72(sp)
    80004786:	6406                	ld	s0,64(sp)
    80004788:	74e2                	ld	s1,56(sp)
    8000478a:	7942                	ld	s2,48(sp)
    8000478c:	79a2                	ld	s3,40(sp)
    8000478e:	6161                	addi	sp,sp,80
    80004790:	8082                	ret
  return -1;
    80004792:	557d                	li	a0,-1
    80004794:	bfc5                	j	80004784 <filestat+0x60>

0000000080004796 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004796:	7179                	addi	sp,sp,-48
    80004798:	f406                	sd	ra,40(sp)
    8000479a:	f022                	sd	s0,32(sp)
    8000479c:	ec26                	sd	s1,24(sp)
    8000479e:	e84a                	sd	s2,16(sp)
    800047a0:	e44e                	sd	s3,8(sp)
    800047a2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a4:	00854783          	lbu	a5,8(a0)
    800047a8:	c3d5                	beqz	a5,8000484c <fileread+0xb6>
    800047aa:	84aa                	mv	s1,a0
    800047ac:	89ae                	mv	s3,a1
    800047ae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047b0:	411c                	lw	a5,0(a0)
    800047b2:	4705                	li	a4,1
    800047b4:	04e78963          	beq	a5,a4,80004806 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b8:	470d                	li	a4,3
    800047ba:	04e78d63          	beq	a5,a4,80004814 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047be:	4709                	li	a4,2
    800047c0:	06e79e63          	bne	a5,a4,8000483c <fileread+0xa6>
    ilock(f->ip);
    800047c4:	6d08                	ld	a0,24(a0)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	ff0080e7          	jalr	-16(ra) # 800037b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ce:	874a                	mv	a4,s2
    800047d0:	5094                	lw	a3,32(s1)
    800047d2:	864e                	mv	a2,s3
    800047d4:	4585                	li	a1,1
    800047d6:	6c88                	ld	a0,24(s1)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	292080e7          	jalr	658(ra) # 80003a6a <readi>
    800047e0:	892a                	mv	s2,a0
    800047e2:	00a05563          	blez	a0,800047ec <fileread+0x56>
      f->off += r;
    800047e6:	509c                	lw	a5,32(s1)
    800047e8:	9fa9                	addw	a5,a5,a0
    800047ea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ec:	6c88                	ld	a0,24(s1)
    800047ee:	fffff097          	auipc	ra,0xfffff
    800047f2:	08a080e7          	jalr	138(ra) # 80003878 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f6:	854a                	mv	a0,s2
    800047f8:	70a2                	ld	ra,40(sp)
    800047fa:	7402                	ld	s0,32(sp)
    800047fc:	64e2                	ld	s1,24(sp)
    800047fe:	6942                	ld	s2,16(sp)
    80004800:	69a2                	ld	s3,8(sp)
    80004802:	6145                	addi	sp,sp,48
    80004804:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004806:	6908                	ld	a0,16(a0)
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	3c8080e7          	jalr	968(ra) # 80004bd0 <piperead>
    80004810:	892a                	mv	s2,a0
    80004812:	b7d5                	j	800047f6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004814:	02451783          	lh	a5,36(a0)
    80004818:	03079693          	slli	a3,a5,0x30
    8000481c:	92c1                	srli	a3,a3,0x30
    8000481e:	4725                	li	a4,9
    80004820:	02d76863          	bltu	a4,a3,80004850 <fileread+0xba>
    80004824:	0792                	slli	a5,a5,0x4
    80004826:	00029717          	auipc	a4,0x29
    8000482a:	ada70713          	addi	a4,a4,-1318 # 8002d300 <devsw>
    8000482e:	97ba                	add	a5,a5,a4
    80004830:	639c                	ld	a5,0(a5)
    80004832:	c38d                	beqz	a5,80004854 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004834:	4505                	li	a0,1
    80004836:	9782                	jalr	a5
    80004838:	892a                	mv	s2,a0
    8000483a:	bf75                	j	800047f6 <fileread+0x60>
    panic("fileread");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	e1450513          	addi	a0,a0,-492 # 80008650 <syscalls+0x268>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	cec080e7          	jalr	-788(ra) # 80000530 <panic>
    return -1;
    8000484c:	597d                	li	s2,-1
    8000484e:	b765                	j	800047f6 <fileread+0x60>
      return -1;
    80004850:	597d                	li	s2,-1
    80004852:	b755                	j	800047f6 <fileread+0x60>
    80004854:	597d                	li	s2,-1
    80004856:	b745                	j	800047f6 <fileread+0x60>

0000000080004858 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004858:	715d                	addi	sp,sp,-80
    8000485a:	e486                	sd	ra,72(sp)
    8000485c:	e0a2                	sd	s0,64(sp)
    8000485e:	fc26                	sd	s1,56(sp)
    80004860:	f84a                	sd	s2,48(sp)
    80004862:	f44e                	sd	s3,40(sp)
    80004864:	f052                	sd	s4,32(sp)
    80004866:	ec56                	sd	s5,24(sp)
    80004868:	e85a                	sd	s6,16(sp)
    8000486a:	e45e                	sd	s7,8(sp)
    8000486c:	e062                	sd	s8,0(sp)
    8000486e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004870:	00954783          	lbu	a5,9(a0)
    80004874:	10078663          	beqz	a5,80004980 <filewrite+0x128>
    80004878:	892a                	mv	s2,a0
    8000487a:	8aae                	mv	s5,a1
    8000487c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487e:	411c                	lw	a5,0(a0)
    80004880:	4705                	li	a4,1
    80004882:	02e78263          	beq	a5,a4,800048a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004886:	470d                	li	a4,3
    80004888:	02e78663          	beq	a5,a4,800048b4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488c:	4709                	li	a4,2
    8000488e:	0ee79163          	bne	a5,a4,80004970 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004892:	0ac05d63          	blez	a2,8000494c <filewrite+0xf4>
    int i = 0;
    80004896:	4981                	li	s3,0
    80004898:	6b05                	lui	s6,0x1
    8000489a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000489e:	6b85                	lui	s7,0x1
    800048a0:	c00b8b9b          	addiw	s7,s7,-1024
    800048a4:	a861                	j	8000493c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048a6:	6908                	ld	a0,16(a0)
    800048a8:	00000097          	auipc	ra,0x0
    800048ac:	22e080e7          	jalr	558(ra) # 80004ad6 <pipewrite>
    800048b0:	8a2a                	mv	s4,a0
    800048b2:	a045                	j	80004952 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048b4:	02451783          	lh	a5,36(a0)
    800048b8:	03079693          	slli	a3,a5,0x30
    800048bc:	92c1                	srli	a3,a3,0x30
    800048be:	4725                	li	a4,9
    800048c0:	0cd76263          	bltu	a4,a3,80004984 <filewrite+0x12c>
    800048c4:	0792                	slli	a5,a5,0x4
    800048c6:	00029717          	auipc	a4,0x29
    800048ca:	a3a70713          	addi	a4,a4,-1478 # 8002d300 <devsw>
    800048ce:	97ba                	add	a5,a5,a4
    800048d0:	679c                	ld	a5,8(a5)
    800048d2:	cbdd                	beqz	a5,80004988 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048d4:	4505                	li	a0,1
    800048d6:	9782                	jalr	a5
    800048d8:	8a2a                	mv	s4,a0
    800048da:	a8a5                	j	80004952 <filewrite+0xfa>
    800048dc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	8a8080e7          	jalr	-1880(ra) # 80004188 <begin_op>
      ilock(f->ip);
    800048e8:	01893503          	ld	a0,24(s2)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	eca080e7          	jalr	-310(ra) # 800037b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048f4:	8762                	mv	a4,s8
    800048f6:	02092683          	lw	a3,32(s2)
    800048fa:	01598633          	add	a2,s3,s5
    800048fe:	4585                	li	a1,1
    80004900:	01893503          	ld	a0,24(s2)
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	25e080e7          	jalr	606(ra) # 80003b62 <writei>
    8000490c:	84aa                	mv	s1,a0
    8000490e:	00a05763          	blez	a0,8000491c <filewrite+0xc4>
        f->off += r;
    80004912:	02092783          	lw	a5,32(s2)
    80004916:	9fa9                	addw	a5,a5,a0
    80004918:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000491c:	01893503          	ld	a0,24(s2)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	f58080e7          	jalr	-168(ra) # 80003878 <iunlock>
      end_op();
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	8e0080e7          	jalr	-1824(ra) # 80004208 <end_op>

      if(r != n1){
    80004930:	009c1f63          	bne	s8,s1,8000494e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004934:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004938:	0149db63          	bge	s3,s4,8000494e <filewrite+0xf6>
      int n1 = n - i;
    8000493c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004940:	84be                	mv	s1,a5
    80004942:	2781                	sext.w	a5,a5
    80004944:	f8fb5ce3          	bge	s6,a5,800048dc <filewrite+0x84>
    80004948:	84de                	mv	s1,s7
    8000494a:	bf49                	j	800048dc <filewrite+0x84>
    int i = 0;
    8000494c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000494e:	013a1f63          	bne	s4,s3,8000496c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004952:	8552                	mv	a0,s4
    80004954:	60a6                	ld	ra,72(sp)
    80004956:	6406                	ld	s0,64(sp)
    80004958:	74e2                	ld	s1,56(sp)
    8000495a:	7942                	ld	s2,48(sp)
    8000495c:	79a2                	ld	s3,40(sp)
    8000495e:	7a02                	ld	s4,32(sp)
    80004960:	6ae2                	ld	s5,24(sp)
    80004962:	6b42                	ld	s6,16(sp)
    80004964:	6ba2                	ld	s7,8(sp)
    80004966:	6c02                	ld	s8,0(sp)
    80004968:	6161                	addi	sp,sp,80
    8000496a:	8082                	ret
    ret = (i == n ? n : -1);
    8000496c:	5a7d                	li	s4,-1
    8000496e:	b7d5                	j	80004952 <filewrite+0xfa>
    panic("filewrite");
    80004970:	00004517          	auipc	a0,0x4
    80004974:	cf050513          	addi	a0,a0,-784 # 80008660 <syscalls+0x278>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bb8080e7          	jalr	-1096(ra) # 80000530 <panic>
    return -1;
    80004980:	5a7d                	li	s4,-1
    80004982:	bfc1                	j	80004952 <filewrite+0xfa>
      return -1;
    80004984:	5a7d                	li	s4,-1
    80004986:	b7f1                	j	80004952 <filewrite+0xfa>
    80004988:	5a7d                	li	s4,-1
    8000498a:	b7e1                	j	80004952 <filewrite+0xfa>

000000008000498c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000498c:	7179                	addi	sp,sp,-48
    8000498e:	f406                	sd	ra,40(sp)
    80004990:	f022                	sd	s0,32(sp)
    80004992:	ec26                	sd	s1,24(sp)
    80004994:	e84a                	sd	s2,16(sp)
    80004996:	e44e                	sd	s3,8(sp)
    80004998:	e052                	sd	s4,0(sp)
    8000499a:	1800                	addi	s0,sp,48
    8000499c:	84aa                	mv	s1,a0
    8000499e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049a0:	0005b023          	sd	zero,0(a1)
    800049a4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a8:	00000097          	auipc	ra,0x0
    800049ac:	bf8080e7          	jalr	-1032(ra) # 800045a0 <filealloc>
    800049b0:	e088                	sd	a0,0(s1)
    800049b2:	c551                	beqz	a0,80004a3e <pipealloc+0xb2>
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	bec080e7          	jalr	-1044(ra) # 800045a0 <filealloc>
    800049bc:	00aa3023          	sd	a0,0(s4)
    800049c0:	c92d                	beqz	a0,80004a32 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c2:	ffffc097          	auipc	ra,0xffffc
    800049c6:	124080e7          	jalr	292(ra) # 80000ae6 <kalloc>
    800049ca:	892a                	mv	s2,a0
    800049cc:	c125                	beqz	a0,80004a2c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049ce:	4985                	li	s3,1
    800049d0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049d8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049dc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049e0:	00004597          	auipc	a1,0x4
    800049e4:	c9058593          	addi	a1,a1,-880 # 80008670 <syscalls+0x288>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	15e080e7          	jalr	350(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049f0:	609c                	ld	a5,0(s1)
    800049f2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f6:	609c                	ld	a5,0(s1)
    800049f8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049fc:	609c                	ld	a5,0(s1)
    800049fe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a02:	609c                	ld	a5,0(s1)
    80004a04:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a08:	000a3783          	ld	a5,0(s4)
    80004a0c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a10:	000a3783          	ld	a5,0(s4)
    80004a14:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a18:	000a3783          	ld	a5,0(s4)
    80004a1c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a20:	000a3783          	ld	a5,0(s4)
    80004a24:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a28:	4501                	li	a0,0
    80004a2a:	a025                	j	80004a52 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a2c:	6088                	ld	a0,0(s1)
    80004a2e:	e501                	bnez	a0,80004a36 <pipealloc+0xaa>
    80004a30:	a039                	j	80004a3e <pipealloc+0xb2>
    80004a32:	6088                	ld	a0,0(s1)
    80004a34:	c51d                	beqz	a0,80004a62 <pipealloc+0xd6>
    fileclose(*f0);
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	c26080e7          	jalr	-986(ra) # 8000465c <fileclose>
  if(*f1)
    80004a3e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a42:	557d                	li	a0,-1
  if(*f1)
    80004a44:	c799                	beqz	a5,80004a52 <pipealloc+0xc6>
    fileclose(*f1);
    80004a46:	853e                	mv	a0,a5
    80004a48:	00000097          	auipc	ra,0x0
    80004a4c:	c14080e7          	jalr	-1004(ra) # 8000465c <fileclose>
  return -1;
    80004a50:	557d                	li	a0,-1
}
    80004a52:	70a2                	ld	ra,40(sp)
    80004a54:	7402                	ld	s0,32(sp)
    80004a56:	64e2                	ld	s1,24(sp)
    80004a58:	6942                	ld	s2,16(sp)
    80004a5a:	69a2                	ld	s3,8(sp)
    80004a5c:	6a02                	ld	s4,0(sp)
    80004a5e:	6145                	addi	sp,sp,48
    80004a60:	8082                	ret
  return -1;
    80004a62:	557d                	li	a0,-1
    80004a64:	b7fd                	j	80004a52 <pipealloc+0xc6>

0000000080004a66 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a66:	1101                	addi	sp,sp,-32
    80004a68:	ec06                	sd	ra,24(sp)
    80004a6a:	e822                	sd	s0,16(sp)
    80004a6c:	e426                	sd	s1,8(sp)
    80004a6e:	e04a                	sd	s2,0(sp)
    80004a70:	1000                	addi	s0,sp,32
    80004a72:	84aa                	mv	s1,a0
    80004a74:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	160080e7          	jalr	352(ra) # 80000bd6 <acquire>
  if(writable){
    80004a7e:	02090d63          	beqz	s2,80004ab8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a82:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a86:	21848513          	addi	a0,s1,536
    80004a8a:	ffffe097          	auipc	ra,0xffffe
    80004a8e:	956080e7          	jalr	-1706(ra) # 800023e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a92:	2204b783          	ld	a5,544(s1)
    80004a96:	eb95                	bnez	a5,80004aca <pipeclose+0x64>
    release(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1f0080e7          	jalr	496(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffc097          	auipc	ra,0xffffc
    80004aa8:	f46080e7          	jalr	-186(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004aac:	60e2                	ld	ra,24(sp)
    80004aae:	6442                	ld	s0,16(sp)
    80004ab0:	64a2                	ld	s1,8(sp)
    80004ab2:	6902                	ld	s2,0(sp)
    80004ab4:	6105                	addi	sp,sp,32
    80004ab6:	8082                	ret
    pi->readopen = 0;
    80004ab8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004abc:	21c48513          	addi	a0,s1,540
    80004ac0:	ffffe097          	auipc	ra,0xffffe
    80004ac4:	920080e7          	jalr	-1760(ra) # 800023e0 <wakeup>
    80004ac8:	b7e9                	j	80004a92 <pipeclose+0x2c>
    release(&pi->lock);
    80004aca:	8526                	mv	a0,s1
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	1be080e7          	jalr	446(ra) # 80000c8a <release>
}
    80004ad4:	bfe1                	j	80004aac <pipeclose+0x46>

0000000080004ad6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ad6:	7159                	addi	sp,sp,-112
    80004ad8:	f486                	sd	ra,104(sp)
    80004ada:	f0a2                	sd	s0,96(sp)
    80004adc:	eca6                	sd	s1,88(sp)
    80004ade:	e8ca                	sd	s2,80(sp)
    80004ae0:	e4ce                	sd	s3,72(sp)
    80004ae2:	e0d2                	sd	s4,64(sp)
    80004ae4:	fc56                	sd	s5,56(sp)
    80004ae6:	f85a                	sd	s6,48(sp)
    80004ae8:	f45e                	sd	s7,40(sp)
    80004aea:	f062                	sd	s8,32(sp)
    80004aec:	ec66                	sd	s9,24(sp)
    80004aee:	1880                	addi	s0,sp,112
    80004af0:	84aa                	mv	s1,a0
    80004af2:	8aae                	mv	s5,a1
    80004af4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004af6:	ffffd097          	auipc	ra,0xffffd
    80004afa:	eb0080e7          	jalr	-336(ra) # 800019a6 <myproc>
    80004afe:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	0d4080e7          	jalr	212(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b0a:	0d405163          	blez	s4,80004bcc <pipewrite+0xf6>
    80004b0e:	8ba6                	mv	s7,s1
  int i = 0;
    80004b10:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b12:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b14:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b18:	21c48c13          	addi	s8,s1,540
    80004b1c:	a08d                	j	80004b7e <pipewrite+0xa8>
      release(&pi->lock);
    80004b1e:	8526                	mv	a0,s1
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	16a080e7          	jalr	362(ra) # 80000c8a <release>
      return -1;
    80004b28:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b2a:	854a                	mv	a0,s2
    80004b2c:	70a6                	ld	ra,104(sp)
    80004b2e:	7406                	ld	s0,96(sp)
    80004b30:	64e6                	ld	s1,88(sp)
    80004b32:	6946                	ld	s2,80(sp)
    80004b34:	69a6                	ld	s3,72(sp)
    80004b36:	6a06                	ld	s4,64(sp)
    80004b38:	7ae2                	ld	s5,56(sp)
    80004b3a:	7b42                	ld	s6,48(sp)
    80004b3c:	7ba2                	ld	s7,40(sp)
    80004b3e:	7c02                	ld	s8,32(sp)
    80004b40:	6ce2                	ld	s9,24(sp)
    80004b42:	6165                	addi	sp,sp,112
    80004b44:	8082                	ret
      wakeup(&pi->nread);
    80004b46:	8566                	mv	a0,s9
    80004b48:	ffffe097          	auipc	ra,0xffffe
    80004b4c:	898080e7          	jalr	-1896(ra) # 800023e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b50:	85de                	mv	a1,s7
    80004b52:	8562                	mv	a0,s8
    80004b54:	ffffd097          	auipc	ra,0xffffd
    80004b58:	706080e7          	jalr	1798(ra) # 8000225a <sleep>
    80004b5c:	a839                	j	80004b7a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b5e:	21c4a783          	lw	a5,540(s1)
    80004b62:	0017871b          	addiw	a4,a5,1
    80004b66:	20e4ae23          	sw	a4,540(s1)
    80004b6a:	1ff7f793          	andi	a5,a5,511
    80004b6e:	97a6                	add	a5,a5,s1
    80004b70:	f9f44703          	lbu	a4,-97(s0)
    80004b74:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b78:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b7a:	03495d63          	bge	s2,s4,80004bb4 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b7e:	2204a783          	lw	a5,544(s1)
    80004b82:	dfd1                	beqz	a5,80004b1e <pipewrite+0x48>
    80004b84:	0309a783          	lw	a5,48(s3)
    80004b88:	fbd9                	bnez	a5,80004b1e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b8a:	2184a783          	lw	a5,536(s1)
    80004b8e:	21c4a703          	lw	a4,540(s1)
    80004b92:	2007879b          	addiw	a5,a5,512
    80004b96:	faf708e3          	beq	a4,a5,80004b46 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b9a:	4685                	li	a3,1
    80004b9c:	01590633          	add	a2,s2,s5
    80004ba0:	f9f40593          	addi	a1,s0,-97
    80004ba4:	0509b503          	ld	a0,80(s3)
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	b20080e7          	jalr	-1248(ra) # 800016c8 <copyin>
    80004bb0:	fb6517e3          	bne	a0,s6,80004b5e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bb4:	21848513          	addi	a0,s1,536
    80004bb8:	ffffe097          	auipc	ra,0xffffe
    80004bbc:	828080e7          	jalr	-2008(ra) # 800023e0 <wakeup>
  release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0c8080e7          	jalr	200(ra) # 80000c8a <release>
  return i;
    80004bca:	b785                	j	80004b2a <pipewrite+0x54>
  int i = 0;
    80004bcc:	4901                	li	s2,0
    80004bce:	b7dd                	j	80004bb4 <pipewrite+0xde>

0000000080004bd0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bd0:	715d                	addi	sp,sp,-80
    80004bd2:	e486                	sd	ra,72(sp)
    80004bd4:	e0a2                	sd	s0,64(sp)
    80004bd6:	fc26                	sd	s1,56(sp)
    80004bd8:	f84a                	sd	s2,48(sp)
    80004bda:	f44e                	sd	s3,40(sp)
    80004bdc:	f052                	sd	s4,32(sp)
    80004bde:	ec56                	sd	s5,24(sp)
    80004be0:	e85a                	sd	s6,16(sp)
    80004be2:	0880                	addi	s0,sp,80
    80004be4:	84aa                	mv	s1,a0
    80004be6:	892e                	mv	s2,a1
    80004be8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	dbc080e7          	jalr	-580(ra) # 800019a6 <myproc>
    80004bf2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bf4:	8b26                	mv	s6,s1
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	fde080e7          	jalr	-34(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c00:	2184a703          	lw	a4,536(s1)
    80004c04:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c08:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c0c:	02f71463          	bne	a4,a5,80004c34 <piperead+0x64>
    80004c10:	2244a783          	lw	a5,548(s1)
    80004c14:	c385                	beqz	a5,80004c34 <piperead+0x64>
    if(pr->killed){
    80004c16:	030a2783          	lw	a5,48(s4)
    80004c1a:	ebc1                	bnez	a5,80004caa <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1c:	85da                	mv	a1,s6
    80004c1e:	854e                	mv	a0,s3
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	63a080e7          	jalr	1594(ra) # 8000225a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c28:	2184a703          	lw	a4,536(s1)
    80004c2c:	21c4a783          	lw	a5,540(s1)
    80004c30:	fef700e3          	beq	a4,a5,80004c10 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c34:	09505263          	blez	s5,80004cb8 <piperead+0xe8>
    80004c38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c3a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c3c:	2184a783          	lw	a5,536(s1)
    80004c40:	21c4a703          	lw	a4,540(s1)
    80004c44:	02f70d63          	beq	a4,a5,80004c7e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c48:	0017871b          	addiw	a4,a5,1
    80004c4c:	20e4ac23          	sw	a4,536(s1)
    80004c50:	1ff7f793          	andi	a5,a5,511
    80004c54:	97a6                	add	a5,a5,s1
    80004c56:	0187c783          	lbu	a5,24(a5)
    80004c5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c5e:	4685                	li	a3,1
    80004c60:	fbf40613          	addi	a2,s0,-65
    80004c64:	85ca                	mv	a1,s2
    80004c66:	050a3503          	ld	a0,80(s4)
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	9d2080e7          	jalr	-1582(ra) # 8000163c <copyout>
    80004c72:	01650663          	beq	a0,s6,80004c7e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c76:	2985                	addiw	s3,s3,1
    80004c78:	0905                	addi	s2,s2,1
    80004c7a:	fd3a91e3          	bne	s5,s3,80004c3c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c7e:	21c48513          	addi	a0,s1,540
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	75e080e7          	jalr	1886(ra) # 800023e0 <wakeup>
  release(&pi->lock);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	ffe080e7          	jalr	-2(ra) # 80000c8a <release>
  return i;
}
    80004c94:	854e                	mv	a0,s3
    80004c96:	60a6                	ld	ra,72(sp)
    80004c98:	6406                	ld	s0,64(sp)
    80004c9a:	74e2                	ld	s1,56(sp)
    80004c9c:	7942                	ld	s2,48(sp)
    80004c9e:	79a2                	ld	s3,40(sp)
    80004ca0:	7a02                	ld	s4,32(sp)
    80004ca2:	6ae2                	ld	s5,24(sp)
    80004ca4:	6b42                	ld	s6,16(sp)
    80004ca6:	6161                	addi	sp,sp,80
    80004ca8:	8082                	ret
      release(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	fde080e7          	jalr	-34(ra) # 80000c8a <release>
      return -1;
    80004cb4:	59fd                	li	s3,-1
    80004cb6:	bff9                	j	80004c94 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb8:	4981                	li	s3,0
    80004cba:	b7d1                	j	80004c7e <piperead+0xae>

0000000080004cbc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cbc:	df010113          	addi	sp,sp,-528
    80004cc0:	20113423          	sd	ra,520(sp)
    80004cc4:	20813023          	sd	s0,512(sp)
    80004cc8:	ffa6                	sd	s1,504(sp)
    80004cca:	fbca                	sd	s2,496(sp)
    80004ccc:	f7ce                	sd	s3,488(sp)
    80004cce:	f3d2                	sd	s4,480(sp)
    80004cd0:	efd6                	sd	s5,472(sp)
    80004cd2:	ebda                	sd	s6,464(sp)
    80004cd4:	e7de                	sd	s7,456(sp)
    80004cd6:	e3e2                	sd	s8,448(sp)
    80004cd8:	ff66                	sd	s9,440(sp)
    80004cda:	fb6a                	sd	s10,432(sp)
    80004cdc:	f76e                	sd	s11,424(sp)
    80004cde:	0c00                	addi	s0,sp,528
    80004ce0:	84aa                	mv	s1,a0
    80004ce2:	dea43c23          	sd	a0,-520(s0)
    80004ce6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cea:	ffffd097          	auipc	ra,0xffffd
    80004cee:	cbc080e7          	jalr	-836(ra) # 800019a6 <myproc>
    80004cf2:	892a                	mv	s2,a0

  begin_op();
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	494080e7          	jalr	1172(ra) # 80004188 <begin_op>

  if((ip = namei(path)) == 0){
    80004cfc:	8526                	mv	a0,s1
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	26e080e7          	jalr	622(ra) # 80003f6c <namei>
    80004d06:	c92d                	beqz	a0,80004d78 <exec+0xbc>
    80004d08:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	aac080e7          	jalr	-1364(ra) # 800037b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d12:	04000713          	li	a4,64
    80004d16:	4681                	li	a3,0
    80004d18:	e4840613          	addi	a2,s0,-440
    80004d1c:	4581                	li	a1,0
    80004d1e:	8526                	mv	a0,s1
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	d4a080e7          	jalr	-694(ra) # 80003a6a <readi>
    80004d28:	04000793          	li	a5,64
    80004d2c:	00f51a63          	bne	a0,a5,80004d40 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d30:	e4842703          	lw	a4,-440(s0)
    80004d34:	464c47b7          	lui	a5,0x464c4
    80004d38:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d3c:	04f70463          	beq	a4,a5,80004d84 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d40:	8526                	mv	a0,s1
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	cd6080e7          	jalr	-810(ra) # 80003a18 <iunlockput>
    end_op();
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	4be080e7          	jalr	1214(ra) # 80004208 <end_op>
  }
  return -1;
    80004d52:	557d                	li	a0,-1
}
    80004d54:	20813083          	ld	ra,520(sp)
    80004d58:	20013403          	ld	s0,512(sp)
    80004d5c:	74fe                	ld	s1,504(sp)
    80004d5e:	795e                	ld	s2,496(sp)
    80004d60:	79be                	ld	s3,488(sp)
    80004d62:	7a1e                	ld	s4,480(sp)
    80004d64:	6afe                	ld	s5,472(sp)
    80004d66:	6b5e                	ld	s6,464(sp)
    80004d68:	6bbe                	ld	s7,456(sp)
    80004d6a:	6c1e                	ld	s8,448(sp)
    80004d6c:	7cfa                	ld	s9,440(sp)
    80004d6e:	7d5a                	ld	s10,432(sp)
    80004d70:	7dba                	ld	s11,424(sp)
    80004d72:	21010113          	addi	sp,sp,528
    80004d76:	8082                	ret
    end_op();
    80004d78:	fffff097          	auipc	ra,0xfffff
    80004d7c:	490080e7          	jalr	1168(ra) # 80004208 <end_op>
    return -1;
    80004d80:	557d                	li	a0,-1
    80004d82:	bfc9                	j	80004d54 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d84:	854a                	mv	a0,s2
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	ce4080e7          	jalr	-796(ra) # 80001a6a <proc_pagetable>
    80004d8e:	8baa                	mv	s7,a0
    80004d90:	d945                	beqz	a0,80004d40 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d92:	e6842983          	lw	s3,-408(s0)
    80004d96:	e8045783          	lhu	a5,-384(s0)
    80004d9a:	c7ad                	beqz	a5,80004e04 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d9c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004da0:	6c85                	lui	s9,0x1
    80004da2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004da6:	def43823          	sd	a5,-528(s0)
    80004daa:	a42d                	j	80004fd4 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dac:	00004517          	auipc	a0,0x4
    80004db0:	8cc50513          	addi	a0,a0,-1844 # 80008678 <syscalls+0x290>
    80004db4:	ffffb097          	auipc	ra,0xffffb
    80004db8:	77c080e7          	jalr	1916(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dbc:	8756                	mv	a4,s5
    80004dbe:	012d86bb          	addw	a3,s11,s2
    80004dc2:	4581                	li	a1,0
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	ca4080e7          	jalr	-860(ra) # 80003a6a <readi>
    80004dce:	2501                	sext.w	a0,a0
    80004dd0:	1aaa9963          	bne	s5,a0,80004f82 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dd4:	6785                	lui	a5,0x1
    80004dd6:	0127893b          	addw	s2,a5,s2
    80004dda:	77fd                	lui	a5,0xfffff
    80004ddc:	01478a3b          	addw	s4,a5,s4
    80004de0:	1f897163          	bgeu	s2,s8,80004fc2 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004de4:	02091593          	slli	a1,s2,0x20
    80004de8:	9181                	srli	a1,a1,0x20
    80004dea:	95ea                	add	a1,a1,s10
    80004dec:	855e                	mv	a0,s7
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	276080e7          	jalr	630(ra) # 80001064 <walkaddr>
    80004df6:	862a                	mv	a2,a0
    if(pa == 0)
    80004df8:	d955                	beqz	a0,80004dac <exec+0xf0>
      n = PGSIZE;
    80004dfa:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dfc:	fd9a70e3          	bgeu	s4,s9,80004dbc <exec+0x100>
      n = sz - i;
    80004e00:	8ad2                	mv	s5,s4
    80004e02:	bf6d                	j	80004dbc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e04:	4901                	li	s2,0
  iunlockput(ip);
    80004e06:	8526                	mv	a0,s1
    80004e08:	fffff097          	auipc	ra,0xfffff
    80004e0c:	c10080e7          	jalr	-1008(ra) # 80003a18 <iunlockput>
  end_op();
    80004e10:	fffff097          	auipc	ra,0xfffff
    80004e14:	3f8080e7          	jalr	1016(ra) # 80004208 <end_op>
  p = myproc();
    80004e18:	ffffd097          	auipc	ra,0xffffd
    80004e1c:	b8e080e7          	jalr	-1138(ra) # 800019a6 <myproc>
    80004e20:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e22:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e26:	6785                	lui	a5,0x1
    80004e28:	17fd                	addi	a5,a5,-1
    80004e2a:	993e                	add	s2,s2,a5
    80004e2c:	757d                	lui	a0,0xfffff
    80004e2e:	00a977b3          	and	a5,s2,a0
    80004e32:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e36:	6609                	lui	a2,0x2
    80004e38:	963e                	add	a2,a2,a5
    80004e3a:	85be                	mv	a1,a5
    80004e3c:	855e                	mv	a0,s7
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	5ba080e7          	jalr	1466(ra) # 800013f8 <uvmalloc>
    80004e46:	8b2a                	mv	s6,a0
  ip = 0;
    80004e48:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e4a:	12050c63          	beqz	a0,80004f82 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e4e:	75f9                	lui	a1,0xffffe
    80004e50:	95aa                	add	a1,a1,a0
    80004e52:	855e                	mv	a0,s7
    80004e54:	ffffc097          	auipc	ra,0xffffc
    80004e58:	7b6080e7          	jalr	1974(ra) # 8000160a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e5c:	7c7d                	lui	s8,0xfffff
    80004e5e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e60:	e0043783          	ld	a5,-512(s0)
    80004e64:	6388                	ld	a0,0(a5)
    80004e66:	c535                	beqz	a0,80004ed2 <exec+0x216>
    80004e68:	e8840993          	addi	s3,s0,-376
    80004e6c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e70:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	fe8080e7          	jalr	-24(ra) # 80000e5a <strlen>
    80004e7a:	2505                	addiw	a0,a0,1
    80004e7c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e80:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e84:	13896363          	bltu	s2,s8,80004faa <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e88:	e0043d83          	ld	s11,-512(s0)
    80004e8c:	000dba03          	ld	s4,0(s11)
    80004e90:	8552                	mv	a0,s4
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	fc8080e7          	jalr	-56(ra) # 80000e5a <strlen>
    80004e9a:	0015069b          	addiw	a3,a0,1
    80004e9e:	8652                	mv	a2,s4
    80004ea0:	85ca                	mv	a1,s2
    80004ea2:	855e                	mv	a0,s7
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	798080e7          	jalr	1944(ra) # 8000163c <copyout>
    80004eac:	10054363          	bltz	a0,80004fb2 <exec+0x2f6>
    ustack[argc] = sp;
    80004eb0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eb4:	0485                	addi	s1,s1,1
    80004eb6:	008d8793          	addi	a5,s11,8
    80004eba:	e0f43023          	sd	a5,-512(s0)
    80004ebe:	008db503          	ld	a0,8(s11)
    80004ec2:	c911                	beqz	a0,80004ed6 <exec+0x21a>
    if(argc >= MAXARG)
    80004ec4:	09a1                	addi	s3,s3,8
    80004ec6:	fb3c96e3          	bne	s9,s3,80004e72 <exec+0x1b6>
  sz = sz1;
    80004eca:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ece:	4481                	li	s1,0
    80004ed0:	a84d                	j	80004f82 <exec+0x2c6>
  sp = sz;
    80004ed2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ed4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ed6:	00349793          	slli	a5,s1,0x3
    80004eda:	f9040713          	addi	a4,s0,-112
    80004ede:	97ba                	add	a5,a5,a4
    80004ee0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ee4:	00148693          	addi	a3,s1,1
    80004ee8:	068e                	slli	a3,a3,0x3
    80004eea:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eee:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ef2:	01897663          	bgeu	s2,s8,80004efe <exec+0x242>
  sz = sz1;
    80004ef6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004efa:	4481                	li	s1,0
    80004efc:	a059                	j	80004f82 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004efe:	e8840613          	addi	a2,s0,-376
    80004f02:	85ca                	mv	a1,s2
    80004f04:	855e                	mv	a0,s7
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	736080e7          	jalr	1846(ra) # 8000163c <copyout>
    80004f0e:	0a054663          	bltz	a0,80004fba <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f12:	058ab783          	ld	a5,88(s5)
    80004f16:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f1a:	df843783          	ld	a5,-520(s0)
    80004f1e:	0007c703          	lbu	a4,0(a5)
    80004f22:	cf11                	beqz	a4,80004f3e <exec+0x282>
    80004f24:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f26:	02f00693          	li	a3,47
    80004f2a:	a029                	j	80004f34 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f2c:	0785                	addi	a5,a5,1
    80004f2e:	fff7c703          	lbu	a4,-1(a5)
    80004f32:	c711                	beqz	a4,80004f3e <exec+0x282>
    if(*s == '/')
    80004f34:	fed71ce3          	bne	a4,a3,80004f2c <exec+0x270>
      last = s+1;
    80004f38:	def43c23          	sd	a5,-520(s0)
    80004f3c:	bfc5                	j	80004f2c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f3e:	4641                	li	a2,16
    80004f40:	df843583          	ld	a1,-520(s0)
    80004f44:	158a8513          	addi	a0,s5,344
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	ee0080e7          	jalr	-288(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f50:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f54:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f58:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f5c:	058ab783          	ld	a5,88(s5)
    80004f60:	e6043703          	ld	a4,-416(s0)
    80004f64:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f66:	058ab783          	ld	a5,88(s5)
    80004f6a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f6e:	85ea                	mv	a1,s10
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	b96080e7          	jalr	-1130(ra) # 80001b06 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f78:	0004851b          	sext.w	a0,s1
    80004f7c:	bbe1                	j	80004d54 <exec+0x98>
    80004f7e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f82:	e0843583          	ld	a1,-504(s0)
    80004f86:	855e                	mv	a0,s7
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	b7e080e7          	jalr	-1154(ra) # 80001b06 <proc_freepagetable>
  if(ip){
    80004f90:	da0498e3          	bnez	s1,80004d40 <exec+0x84>
  return -1;
    80004f94:	557d                	li	a0,-1
    80004f96:	bb7d                	j	80004d54 <exec+0x98>
    80004f98:	e1243423          	sd	s2,-504(s0)
    80004f9c:	b7dd                	j	80004f82 <exec+0x2c6>
    80004f9e:	e1243423          	sd	s2,-504(s0)
    80004fa2:	b7c5                	j	80004f82 <exec+0x2c6>
    80004fa4:	e1243423          	sd	s2,-504(s0)
    80004fa8:	bfe9                	j	80004f82 <exec+0x2c6>
  sz = sz1;
    80004faa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fae:	4481                	li	s1,0
    80004fb0:	bfc9                	j	80004f82 <exec+0x2c6>
  sz = sz1;
    80004fb2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb6:	4481                	li	s1,0
    80004fb8:	b7e9                	j	80004f82 <exec+0x2c6>
  sz = sz1;
    80004fba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fbe:	4481                	li	s1,0
    80004fc0:	b7c9                	j	80004f82 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fc2:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc6:	2b05                	addiw	s6,s6,1
    80004fc8:	0389899b          	addiw	s3,s3,56
    80004fcc:	e8045783          	lhu	a5,-384(s0)
    80004fd0:	e2fb5be3          	bge	s6,a5,80004e06 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fd4:	2981                	sext.w	s3,s3
    80004fd6:	03800713          	li	a4,56
    80004fda:	86ce                	mv	a3,s3
    80004fdc:	e1040613          	addi	a2,s0,-496
    80004fe0:	4581                	li	a1,0
    80004fe2:	8526                	mv	a0,s1
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	a86080e7          	jalr	-1402(ra) # 80003a6a <readi>
    80004fec:	03800793          	li	a5,56
    80004ff0:	f8f517e3          	bne	a0,a5,80004f7e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004ff4:	e1042783          	lw	a5,-496(s0)
    80004ff8:	4705                	li	a4,1
    80004ffa:	fce796e3          	bne	a5,a4,80004fc6 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ffe:	e3843603          	ld	a2,-456(s0)
    80005002:	e3043783          	ld	a5,-464(s0)
    80005006:	f8f669e3          	bltu	a2,a5,80004f98 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000500a:	e2043783          	ld	a5,-480(s0)
    8000500e:	963e                	add	a2,a2,a5
    80005010:	f8f667e3          	bltu	a2,a5,80004f9e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005014:	85ca                	mv	a1,s2
    80005016:	855e                	mv	a0,s7
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	3e0080e7          	jalr	992(ra) # 800013f8 <uvmalloc>
    80005020:	e0a43423          	sd	a0,-504(s0)
    80005024:	d141                	beqz	a0,80004fa4 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005026:	e2043d03          	ld	s10,-480(s0)
    8000502a:	df043783          	ld	a5,-528(s0)
    8000502e:	00fd77b3          	and	a5,s10,a5
    80005032:	fba1                	bnez	a5,80004f82 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005034:	e1842d83          	lw	s11,-488(s0)
    80005038:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000503c:	f80c03e3          	beqz	s8,80004fc2 <exec+0x306>
    80005040:	8a62                	mv	s4,s8
    80005042:	4901                	li	s2,0
    80005044:	b345                	j	80004de4 <exec+0x128>

0000000080005046 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005046:	7179                	addi	sp,sp,-48
    80005048:	f406                	sd	ra,40(sp)
    8000504a:	f022                	sd	s0,32(sp)
    8000504c:	ec26                	sd	s1,24(sp)
    8000504e:	e84a                	sd	s2,16(sp)
    80005050:	1800                	addi	s0,sp,48
    80005052:	892e                	mv	s2,a1
    80005054:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005056:	fdc40593          	addi	a1,s0,-36
    8000505a:	ffffe097          	auipc	ra,0xffffe
    8000505e:	bea080e7          	jalr	-1046(ra) # 80002c44 <argint>
    80005062:	04054063          	bltz	a0,800050a2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005066:	fdc42703          	lw	a4,-36(s0)
    8000506a:	47bd                	li	a5,15
    8000506c:	02e7ed63          	bltu	a5,a4,800050a6 <argfd+0x60>
    80005070:	ffffd097          	auipc	ra,0xffffd
    80005074:	936080e7          	jalr	-1738(ra) # 800019a6 <myproc>
    80005078:	fdc42703          	lw	a4,-36(s0)
    8000507c:	01a70793          	addi	a5,a4,26
    80005080:	078e                	slli	a5,a5,0x3
    80005082:	953e                	add	a0,a0,a5
    80005084:	611c                	ld	a5,0(a0)
    80005086:	c395                	beqz	a5,800050aa <argfd+0x64>
    return -1;
  if(pfd)
    80005088:	00090463          	beqz	s2,80005090 <argfd+0x4a>
    *pfd = fd;
    8000508c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005090:	4501                	li	a0,0
  if(pf)
    80005092:	c091                	beqz	s1,80005096 <argfd+0x50>
    *pf = f;
    80005094:	e09c                	sd	a5,0(s1)
}
    80005096:	70a2                	ld	ra,40(sp)
    80005098:	7402                	ld	s0,32(sp)
    8000509a:	64e2                	ld	s1,24(sp)
    8000509c:	6942                	ld	s2,16(sp)
    8000509e:	6145                	addi	sp,sp,48
    800050a0:	8082                	ret
    return -1;
    800050a2:	557d                	li	a0,-1
    800050a4:	bfcd                	j	80005096 <argfd+0x50>
    return -1;
    800050a6:	557d                	li	a0,-1
    800050a8:	b7fd                	j	80005096 <argfd+0x50>
    800050aa:	557d                	li	a0,-1
    800050ac:	b7ed                	j	80005096 <argfd+0x50>

00000000800050ae <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050ae:	1101                	addi	sp,sp,-32
    800050b0:	ec06                	sd	ra,24(sp)
    800050b2:	e822                	sd	s0,16(sp)
    800050b4:	e426                	sd	s1,8(sp)
    800050b6:	1000                	addi	s0,sp,32
    800050b8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050ba:	ffffd097          	auipc	ra,0xffffd
    800050be:	8ec080e7          	jalr	-1812(ra) # 800019a6 <myproc>
    800050c2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffcd0d0>
    800050c8:	4501                	li	a0,0
    800050ca:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050cc:	6398                	ld	a4,0(a5)
    800050ce:	cb19                	beqz	a4,800050e4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050d0:	2505                	addiw	a0,a0,1
    800050d2:	07a1                	addi	a5,a5,8
    800050d4:	fed51ce3          	bne	a0,a3,800050cc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050d8:	557d                	li	a0,-1
}
    800050da:	60e2                	ld	ra,24(sp)
    800050dc:	6442                	ld	s0,16(sp)
    800050de:	64a2                	ld	s1,8(sp)
    800050e0:	6105                	addi	sp,sp,32
    800050e2:	8082                	ret
      p->ofile[fd] = f;
    800050e4:	01a50793          	addi	a5,a0,26
    800050e8:	078e                	slli	a5,a5,0x3
    800050ea:	963e                	add	a2,a2,a5
    800050ec:	e204                	sd	s1,0(a2)
      return fd;
    800050ee:	b7f5                	j	800050da <fdalloc+0x2c>

00000000800050f0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050f0:	715d                	addi	sp,sp,-80
    800050f2:	e486                	sd	ra,72(sp)
    800050f4:	e0a2                	sd	s0,64(sp)
    800050f6:	fc26                	sd	s1,56(sp)
    800050f8:	f84a                	sd	s2,48(sp)
    800050fa:	f44e                	sd	s3,40(sp)
    800050fc:	f052                	sd	s4,32(sp)
    800050fe:	ec56                	sd	s5,24(sp)
    80005100:	0880                	addi	s0,sp,80
    80005102:	89ae                	mv	s3,a1
    80005104:	8ab2                	mv	s5,a2
    80005106:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005108:	fb040593          	addi	a1,s0,-80
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	e7e080e7          	jalr	-386(ra) # 80003f8a <nameiparent>
    80005114:	892a                	mv	s2,a0
    80005116:	12050f63          	beqz	a0,80005254 <create+0x164>
    return 0;

  ilock(dp);
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	69c080e7          	jalr	1692(ra) # 800037b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005122:	4601                	li	a2,0
    80005124:	fb040593          	addi	a1,s0,-80
    80005128:	854a                	mv	a0,s2
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	b70080e7          	jalr	-1168(ra) # 80003c9a <dirlookup>
    80005132:	84aa                	mv	s1,a0
    80005134:	c921                	beqz	a0,80005184 <create+0x94>
    iunlockput(dp);
    80005136:	854a                	mv	a0,s2
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	8e0080e7          	jalr	-1824(ra) # 80003a18 <iunlockput>
    ilock(ip);
    80005140:	8526                	mv	a0,s1
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	674080e7          	jalr	1652(ra) # 800037b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000514a:	2981                	sext.w	s3,s3
    8000514c:	4789                	li	a5,2
    8000514e:	02f99463          	bne	s3,a5,80005176 <create+0x86>
    80005152:	0444d783          	lhu	a5,68(s1)
    80005156:	37f9                	addiw	a5,a5,-2
    80005158:	17c2                	slli	a5,a5,0x30
    8000515a:	93c1                	srli	a5,a5,0x30
    8000515c:	4705                	li	a4,1
    8000515e:	00f76c63          	bltu	a4,a5,80005176 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005162:	8526                	mv	a0,s1
    80005164:	60a6                	ld	ra,72(sp)
    80005166:	6406                	ld	s0,64(sp)
    80005168:	74e2                	ld	s1,56(sp)
    8000516a:	7942                	ld	s2,48(sp)
    8000516c:	79a2                	ld	s3,40(sp)
    8000516e:	7a02                	ld	s4,32(sp)
    80005170:	6ae2                	ld	s5,24(sp)
    80005172:	6161                	addi	sp,sp,80
    80005174:	8082                	ret
    iunlockput(ip);
    80005176:	8526                	mv	a0,s1
    80005178:	fffff097          	auipc	ra,0xfffff
    8000517c:	8a0080e7          	jalr	-1888(ra) # 80003a18 <iunlockput>
    return 0;
    80005180:	4481                	li	s1,0
    80005182:	b7c5                	j	80005162 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005184:	85ce                	mv	a1,s3
    80005186:	00092503          	lw	a0,0(s2)
    8000518a:	ffffe097          	auipc	ra,0xffffe
    8000518e:	494080e7          	jalr	1172(ra) # 8000361e <ialloc>
    80005192:	84aa                	mv	s1,a0
    80005194:	c529                	beqz	a0,800051de <create+0xee>
  ilock(ip);
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	620080e7          	jalr	1568(ra) # 800037b6 <ilock>
  ip->major = major;
    8000519e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051a2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051a6:	4785                	li	a5,1
    800051a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051ac:	8526                	mv	a0,s1
    800051ae:	ffffe097          	auipc	ra,0xffffe
    800051b2:	53e080e7          	jalr	1342(ra) # 800036ec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051b6:	2981                	sext.w	s3,s3
    800051b8:	4785                	li	a5,1
    800051ba:	02f98a63          	beq	s3,a5,800051ee <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051be:	40d0                	lw	a2,4(s1)
    800051c0:	fb040593          	addi	a1,s0,-80
    800051c4:	854a                	mv	a0,s2
    800051c6:	fffff097          	auipc	ra,0xfffff
    800051ca:	ce4080e7          	jalr	-796(ra) # 80003eaa <dirlink>
    800051ce:	06054b63          	bltz	a0,80005244 <create+0x154>
  iunlockput(dp);
    800051d2:	854a                	mv	a0,s2
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	844080e7          	jalr	-1980(ra) # 80003a18 <iunlockput>
  return ip;
    800051dc:	b759                	j	80005162 <create+0x72>
    panic("create: ialloc");
    800051de:	00003517          	auipc	a0,0x3
    800051e2:	4ba50513          	addi	a0,a0,1210 # 80008698 <syscalls+0x2b0>
    800051e6:	ffffb097          	auipc	ra,0xffffb
    800051ea:	34a080e7          	jalr	842(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    800051ee:	04a95783          	lhu	a5,74(s2)
    800051f2:	2785                	addiw	a5,a5,1
    800051f4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051f8:	854a                	mv	a0,s2
    800051fa:	ffffe097          	auipc	ra,0xffffe
    800051fe:	4f2080e7          	jalr	1266(ra) # 800036ec <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005202:	40d0                	lw	a2,4(s1)
    80005204:	00003597          	auipc	a1,0x3
    80005208:	4a458593          	addi	a1,a1,1188 # 800086a8 <syscalls+0x2c0>
    8000520c:	8526                	mv	a0,s1
    8000520e:	fffff097          	auipc	ra,0xfffff
    80005212:	c9c080e7          	jalr	-868(ra) # 80003eaa <dirlink>
    80005216:	00054f63          	bltz	a0,80005234 <create+0x144>
    8000521a:	00492603          	lw	a2,4(s2)
    8000521e:	00003597          	auipc	a1,0x3
    80005222:	49258593          	addi	a1,a1,1170 # 800086b0 <syscalls+0x2c8>
    80005226:	8526                	mv	a0,s1
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	c82080e7          	jalr	-894(ra) # 80003eaa <dirlink>
    80005230:	f80557e3          	bgez	a0,800051be <create+0xce>
      panic("create dots");
    80005234:	00003517          	auipc	a0,0x3
    80005238:	48450513          	addi	a0,a0,1156 # 800086b8 <syscalls+0x2d0>
    8000523c:	ffffb097          	auipc	ra,0xffffb
    80005240:	2f4080e7          	jalr	756(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005244:	00003517          	auipc	a0,0x3
    80005248:	48450513          	addi	a0,a0,1156 # 800086c8 <syscalls+0x2e0>
    8000524c:	ffffb097          	auipc	ra,0xffffb
    80005250:	2e4080e7          	jalr	740(ra) # 80000530 <panic>
    return 0;
    80005254:	84aa                	mv	s1,a0
    80005256:	b731                	j	80005162 <create+0x72>

0000000080005258 <sys_dup>:
{
    80005258:	7179                	addi	sp,sp,-48
    8000525a:	f406                	sd	ra,40(sp)
    8000525c:	f022                	sd	s0,32(sp)
    8000525e:	ec26                	sd	s1,24(sp)
    80005260:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005262:	fd840613          	addi	a2,s0,-40
    80005266:	4581                	li	a1,0
    80005268:	4501                	li	a0,0
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	ddc080e7          	jalr	-548(ra) # 80005046 <argfd>
    return -1;
    80005272:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005274:	02054363          	bltz	a0,8000529a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005278:	fd843503          	ld	a0,-40(s0)
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	e32080e7          	jalr	-462(ra) # 800050ae <fdalloc>
    80005284:	84aa                	mv	s1,a0
    return -1;
    80005286:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005288:	00054963          	bltz	a0,8000529a <sys_dup+0x42>
  filedup(f);
    8000528c:	fd843503          	ld	a0,-40(s0)
    80005290:	fffff097          	auipc	ra,0xfffff
    80005294:	37a080e7          	jalr	890(ra) # 8000460a <filedup>
  return fd;
    80005298:	87a6                	mv	a5,s1
}
    8000529a:	853e                	mv	a0,a5
    8000529c:	70a2                	ld	ra,40(sp)
    8000529e:	7402                	ld	s0,32(sp)
    800052a0:	64e2                	ld	s1,24(sp)
    800052a2:	6145                	addi	sp,sp,48
    800052a4:	8082                	ret

00000000800052a6 <sys_read>:
{
    800052a6:	7179                	addi	sp,sp,-48
    800052a8:	f406                	sd	ra,40(sp)
    800052aa:	f022                	sd	s0,32(sp)
    800052ac:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ae:	fe840613          	addi	a2,s0,-24
    800052b2:	4581                	li	a1,0
    800052b4:	4501                	li	a0,0
    800052b6:	00000097          	auipc	ra,0x0
    800052ba:	d90080e7          	jalr	-624(ra) # 80005046 <argfd>
    return -1;
    800052be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052c0:	04054163          	bltz	a0,80005302 <sys_read+0x5c>
    800052c4:	fe440593          	addi	a1,s0,-28
    800052c8:	4509                	li	a0,2
    800052ca:	ffffe097          	auipc	ra,0xffffe
    800052ce:	97a080e7          	jalr	-1670(ra) # 80002c44 <argint>
    return -1;
    800052d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d4:	02054763          	bltz	a0,80005302 <sys_read+0x5c>
    800052d8:	fd840593          	addi	a1,s0,-40
    800052dc:	4505                	li	a0,1
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	988080e7          	jalr	-1656(ra) # 80002c66 <argaddr>
    return -1;
    800052e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e8:	00054d63          	bltz	a0,80005302 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ec:	fe442603          	lw	a2,-28(s0)
    800052f0:	fd843583          	ld	a1,-40(s0)
    800052f4:	fe843503          	ld	a0,-24(s0)
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	49e080e7          	jalr	1182(ra) # 80004796 <fileread>
    80005300:	87aa                	mv	a5,a0
}
    80005302:	853e                	mv	a0,a5
    80005304:	70a2                	ld	ra,40(sp)
    80005306:	7402                	ld	s0,32(sp)
    80005308:	6145                	addi	sp,sp,48
    8000530a:	8082                	ret

000000008000530c <sys_write>:
{
    8000530c:	7179                	addi	sp,sp,-48
    8000530e:	f406                	sd	ra,40(sp)
    80005310:	f022                	sd	s0,32(sp)
    80005312:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005314:	fe840613          	addi	a2,s0,-24
    80005318:	4581                	li	a1,0
    8000531a:	4501                	li	a0,0
    8000531c:	00000097          	auipc	ra,0x0
    80005320:	d2a080e7          	jalr	-726(ra) # 80005046 <argfd>
    return -1;
    80005324:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005326:	04054163          	bltz	a0,80005368 <sys_write+0x5c>
    8000532a:	fe440593          	addi	a1,s0,-28
    8000532e:	4509                	li	a0,2
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	914080e7          	jalr	-1772(ra) # 80002c44 <argint>
    return -1;
    80005338:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	02054763          	bltz	a0,80005368 <sys_write+0x5c>
    8000533e:	fd840593          	addi	a1,s0,-40
    80005342:	4505                	li	a0,1
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	922080e7          	jalr	-1758(ra) # 80002c66 <argaddr>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534e:	00054d63          	bltz	a0,80005368 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005352:	fe442603          	lw	a2,-28(s0)
    80005356:	fd843583          	ld	a1,-40(s0)
    8000535a:	fe843503          	ld	a0,-24(s0)
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	4fa080e7          	jalr	1274(ra) # 80004858 <filewrite>
    80005366:	87aa                	mv	a5,a0
}
    80005368:	853e                	mv	a0,a5
    8000536a:	70a2                	ld	ra,40(sp)
    8000536c:	7402                	ld	s0,32(sp)
    8000536e:	6145                	addi	sp,sp,48
    80005370:	8082                	ret

0000000080005372 <sys_close>:
{
    80005372:	1101                	addi	sp,sp,-32
    80005374:	ec06                	sd	ra,24(sp)
    80005376:	e822                	sd	s0,16(sp)
    80005378:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000537a:	fe040613          	addi	a2,s0,-32
    8000537e:	fec40593          	addi	a1,s0,-20
    80005382:	4501                	li	a0,0
    80005384:	00000097          	auipc	ra,0x0
    80005388:	cc2080e7          	jalr	-830(ra) # 80005046 <argfd>
    return -1;
    8000538c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000538e:	02054463          	bltz	a0,800053b6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	614080e7          	jalr	1556(ra) # 800019a6 <myproc>
    8000539a:	fec42783          	lw	a5,-20(s0)
    8000539e:	07e9                	addi	a5,a5,26
    800053a0:	078e                	slli	a5,a5,0x3
    800053a2:	97aa                	add	a5,a5,a0
    800053a4:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053a8:	fe043503          	ld	a0,-32(s0)
    800053ac:	fffff097          	auipc	ra,0xfffff
    800053b0:	2b0080e7          	jalr	688(ra) # 8000465c <fileclose>
  return 0;
    800053b4:	4781                	li	a5,0
}
    800053b6:	853e                	mv	a0,a5
    800053b8:	60e2                	ld	ra,24(sp)
    800053ba:	6442                	ld	s0,16(sp)
    800053bc:	6105                	addi	sp,sp,32
    800053be:	8082                	ret

00000000800053c0 <sys_fstat>:
{
    800053c0:	1101                	addi	sp,sp,-32
    800053c2:	ec06                	sd	ra,24(sp)
    800053c4:	e822                	sd	s0,16(sp)
    800053c6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c8:	fe840613          	addi	a2,s0,-24
    800053cc:	4581                	li	a1,0
    800053ce:	4501                	li	a0,0
    800053d0:	00000097          	auipc	ra,0x0
    800053d4:	c76080e7          	jalr	-906(ra) # 80005046 <argfd>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053da:	02054563          	bltz	a0,80005404 <sys_fstat+0x44>
    800053de:	fe040593          	addi	a1,s0,-32
    800053e2:	4505                	li	a0,1
    800053e4:	ffffe097          	auipc	ra,0xffffe
    800053e8:	882080e7          	jalr	-1918(ra) # 80002c66 <argaddr>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ee:	00054b63          	bltz	a0,80005404 <sys_fstat+0x44>
  return filestat(f, st);
    800053f2:	fe043583          	ld	a1,-32(s0)
    800053f6:	fe843503          	ld	a0,-24(s0)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	32a080e7          	jalr	810(ra) # 80004724 <filestat>
    80005402:	87aa                	mv	a5,a0
}
    80005404:	853e                	mv	a0,a5
    80005406:	60e2                	ld	ra,24(sp)
    80005408:	6442                	ld	s0,16(sp)
    8000540a:	6105                	addi	sp,sp,32
    8000540c:	8082                	ret

000000008000540e <sys_link>:
{
    8000540e:	7169                	addi	sp,sp,-304
    80005410:	f606                	sd	ra,296(sp)
    80005412:	f222                	sd	s0,288(sp)
    80005414:	ee26                	sd	s1,280(sp)
    80005416:	ea4a                	sd	s2,272(sp)
    80005418:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541a:	08000613          	li	a2,128
    8000541e:	ed040593          	addi	a1,s0,-304
    80005422:	4501                	li	a0,0
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	864080e7          	jalr	-1948(ra) # 80002c88 <argstr>
    return -1;
    8000542c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542e:	10054e63          	bltz	a0,8000554a <sys_link+0x13c>
    80005432:	08000613          	li	a2,128
    80005436:	f5040593          	addi	a1,s0,-176
    8000543a:	4505                	li	a0,1
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	84c080e7          	jalr	-1972(ra) # 80002c88 <argstr>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005446:	10054263          	bltz	a0,8000554a <sys_link+0x13c>
  begin_op();
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	d3e080e7          	jalr	-706(ra) # 80004188 <begin_op>
  if((ip = namei(old)) == 0){
    80005452:	ed040513          	addi	a0,s0,-304
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	b16080e7          	jalr	-1258(ra) # 80003f6c <namei>
    8000545e:	84aa                	mv	s1,a0
    80005460:	c551                	beqz	a0,800054ec <sys_link+0xde>
  ilock(ip);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	354080e7          	jalr	852(ra) # 800037b6 <ilock>
  if(ip->type == T_DIR){
    8000546a:	04449703          	lh	a4,68(s1)
    8000546e:	4785                	li	a5,1
    80005470:	08f70463          	beq	a4,a5,800054f8 <sys_link+0xea>
  ip->nlink++;
    80005474:	04a4d783          	lhu	a5,74(s1)
    80005478:	2785                	addiw	a5,a5,1
    8000547a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	26c080e7          	jalr	620(ra) # 800036ec <iupdate>
  iunlock(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	3ee080e7          	jalr	1006(ra) # 80003878 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005492:	fd040593          	addi	a1,s0,-48
    80005496:	f5040513          	addi	a0,s0,-176
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	af0080e7          	jalr	-1296(ra) # 80003f8a <nameiparent>
    800054a2:	892a                	mv	s2,a0
    800054a4:	c935                	beqz	a0,80005518 <sys_link+0x10a>
  ilock(dp);
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	310080e7          	jalr	784(ra) # 800037b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ae:	00092703          	lw	a4,0(s2)
    800054b2:	409c                	lw	a5,0(s1)
    800054b4:	04f71d63          	bne	a4,a5,8000550e <sys_link+0x100>
    800054b8:	40d0                	lw	a2,4(s1)
    800054ba:	fd040593          	addi	a1,s0,-48
    800054be:	854a                	mv	a0,s2
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	9ea080e7          	jalr	-1558(ra) # 80003eaa <dirlink>
    800054c8:	04054363          	bltz	a0,8000550e <sys_link+0x100>
  iunlockput(dp);
    800054cc:	854a                	mv	a0,s2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	54a080e7          	jalr	1354(ra) # 80003a18 <iunlockput>
  iput(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	498080e7          	jalr	1176(ra) # 80003970 <iput>
  end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	d28080e7          	jalr	-728(ra) # 80004208 <end_op>
  return 0;
    800054e8:	4781                	li	a5,0
    800054ea:	a085                	j	8000554a <sys_link+0x13c>
    end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	d1c080e7          	jalr	-740(ra) # 80004208 <end_op>
    return -1;
    800054f4:	57fd                	li	a5,-1
    800054f6:	a891                	j	8000554a <sys_link+0x13c>
    iunlockput(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	51e080e7          	jalr	1310(ra) # 80003a18 <iunlockput>
    end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	d06080e7          	jalr	-762(ra) # 80004208 <end_op>
    return -1;
    8000550a:	57fd                	li	a5,-1
    8000550c:	a83d                	j	8000554a <sys_link+0x13c>
    iunlockput(dp);
    8000550e:	854a                	mv	a0,s2
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	508080e7          	jalr	1288(ra) # 80003a18 <iunlockput>
  ilock(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	29c080e7          	jalr	668(ra) # 800037b6 <ilock>
  ip->nlink--;
    80005522:	04a4d783          	lhu	a5,74(s1)
    80005526:	37fd                	addiw	a5,a5,-1
    80005528:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	1be080e7          	jalr	446(ra) # 800036ec <iupdate>
  iunlockput(ip);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	4e0080e7          	jalr	1248(ra) # 80003a18 <iunlockput>
  end_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	cc8080e7          	jalr	-824(ra) # 80004208 <end_op>
  return -1;
    80005548:	57fd                	li	a5,-1
}
    8000554a:	853e                	mv	a0,a5
    8000554c:	70b2                	ld	ra,296(sp)
    8000554e:	7412                	ld	s0,288(sp)
    80005550:	64f2                	ld	s1,280(sp)
    80005552:	6952                	ld	s2,272(sp)
    80005554:	6155                	addi	sp,sp,304
    80005556:	8082                	ret

0000000080005558 <sys_unlink>:
{
    80005558:	7151                	addi	sp,sp,-240
    8000555a:	f586                	sd	ra,232(sp)
    8000555c:	f1a2                	sd	s0,224(sp)
    8000555e:	eda6                	sd	s1,216(sp)
    80005560:	e9ca                	sd	s2,208(sp)
    80005562:	e5ce                	sd	s3,200(sp)
    80005564:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005566:	08000613          	li	a2,128
    8000556a:	f3040593          	addi	a1,s0,-208
    8000556e:	4501                	li	a0,0
    80005570:	ffffd097          	auipc	ra,0xffffd
    80005574:	718080e7          	jalr	1816(ra) # 80002c88 <argstr>
    80005578:	18054163          	bltz	a0,800056fa <sys_unlink+0x1a2>
  begin_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	c0c080e7          	jalr	-1012(ra) # 80004188 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005584:	fb040593          	addi	a1,s0,-80
    80005588:	f3040513          	addi	a0,s0,-208
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	9fe080e7          	jalr	-1538(ra) # 80003f8a <nameiparent>
    80005594:	84aa                	mv	s1,a0
    80005596:	c979                	beqz	a0,8000566c <sys_unlink+0x114>
  ilock(dp);
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	21e080e7          	jalr	542(ra) # 800037b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055a0:	00003597          	auipc	a1,0x3
    800055a4:	10858593          	addi	a1,a1,264 # 800086a8 <syscalls+0x2c0>
    800055a8:	fb040513          	addi	a0,s0,-80
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	6d4080e7          	jalr	1748(ra) # 80003c80 <namecmp>
    800055b4:	14050a63          	beqz	a0,80005708 <sys_unlink+0x1b0>
    800055b8:	00003597          	auipc	a1,0x3
    800055bc:	0f858593          	addi	a1,a1,248 # 800086b0 <syscalls+0x2c8>
    800055c0:	fb040513          	addi	a0,s0,-80
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	6bc080e7          	jalr	1724(ra) # 80003c80 <namecmp>
    800055cc:	12050e63          	beqz	a0,80005708 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055d0:	f2c40613          	addi	a2,s0,-212
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	8526                	mv	a0,s1
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	6c0080e7          	jalr	1728(ra) # 80003c9a <dirlookup>
    800055e2:	892a                	mv	s2,a0
    800055e4:	12050263          	beqz	a0,80005708 <sys_unlink+0x1b0>
  ilock(ip);
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	1ce080e7          	jalr	462(ra) # 800037b6 <ilock>
  if(ip->nlink < 1)
    800055f0:	04a91783          	lh	a5,74(s2)
    800055f4:	08f05263          	blez	a5,80005678 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f8:	04491703          	lh	a4,68(s2)
    800055fc:	4785                	li	a5,1
    800055fe:	08f70563          	beq	a4,a5,80005688 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005602:	4641                	li	a2,16
    80005604:	4581                	li	a1,0
    80005606:	fc040513          	addi	a0,s0,-64
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	6c8080e7          	jalr	1736(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005612:	4741                	li	a4,16
    80005614:	f2c42683          	lw	a3,-212(s0)
    80005618:	fc040613          	addi	a2,s0,-64
    8000561c:	4581                	li	a1,0
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	542080e7          	jalr	1346(ra) # 80003b62 <writei>
    80005628:	47c1                	li	a5,16
    8000562a:	0af51563          	bne	a0,a5,800056d4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000562e:	04491703          	lh	a4,68(s2)
    80005632:	4785                	li	a5,1
    80005634:	0af70863          	beq	a4,a5,800056e4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	3de080e7          	jalr	990(ra) # 80003a18 <iunlockput>
  ip->nlink--;
    80005642:	04a95783          	lhu	a5,74(s2)
    80005646:	37fd                	addiw	a5,a5,-1
    80005648:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	09e080e7          	jalr	158(ra) # 800036ec <iupdate>
  iunlockput(ip);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	3c0080e7          	jalr	960(ra) # 80003a18 <iunlockput>
  end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	ba8080e7          	jalr	-1112(ra) # 80004208 <end_op>
  return 0;
    80005668:	4501                	li	a0,0
    8000566a:	a84d                	j	8000571c <sys_unlink+0x1c4>
    end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	b9c080e7          	jalr	-1124(ra) # 80004208 <end_op>
    return -1;
    80005674:	557d                	li	a0,-1
    80005676:	a05d                	j	8000571c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005678:	00003517          	auipc	a0,0x3
    8000567c:	06050513          	addi	a0,a0,96 # 800086d8 <syscalls+0x2f0>
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	eb0080e7          	jalr	-336(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005688:	04c92703          	lw	a4,76(s2)
    8000568c:	02000793          	li	a5,32
    80005690:	f6e7f9e3          	bgeu	a5,a4,80005602 <sys_unlink+0xaa>
    80005694:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005698:	4741                	li	a4,16
    8000569a:	86ce                	mv	a3,s3
    8000569c:	f1840613          	addi	a2,s0,-232
    800056a0:	4581                	li	a1,0
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	3c6080e7          	jalr	966(ra) # 80003a6a <readi>
    800056ac:	47c1                	li	a5,16
    800056ae:	00f51b63          	bne	a0,a5,800056c4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b2:	f1845783          	lhu	a5,-232(s0)
    800056b6:	e7a1                	bnez	a5,800056fe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b8:	29c1                	addiw	s3,s3,16
    800056ba:	04c92783          	lw	a5,76(s2)
    800056be:	fcf9ede3          	bltu	s3,a5,80005698 <sys_unlink+0x140>
    800056c2:	b781                	j	80005602 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056c4:	00003517          	auipc	a0,0x3
    800056c8:	02c50513          	addi	a0,a0,44 # 800086f0 <syscalls+0x308>
    800056cc:	ffffb097          	auipc	ra,0xffffb
    800056d0:	e64080e7          	jalr	-412(ra) # 80000530 <panic>
    panic("unlink: writei");
    800056d4:	00003517          	auipc	a0,0x3
    800056d8:	03450513          	addi	a0,a0,52 # 80008708 <syscalls+0x320>
    800056dc:	ffffb097          	auipc	ra,0xffffb
    800056e0:	e54080e7          	jalr	-428(ra) # 80000530 <panic>
    dp->nlink--;
    800056e4:	04a4d783          	lhu	a5,74(s1)
    800056e8:	37fd                	addiw	a5,a5,-1
    800056ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ee:	8526                	mv	a0,s1
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	ffc080e7          	jalr	-4(ra) # 800036ec <iupdate>
    800056f8:	b781                	j	80005638 <sys_unlink+0xe0>
    return -1;
    800056fa:	557d                	li	a0,-1
    800056fc:	a005                	j	8000571c <sys_unlink+0x1c4>
    iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	318080e7          	jalr	792(ra) # 80003a18 <iunlockput>
  iunlockput(dp);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	30e080e7          	jalr	782(ra) # 80003a18 <iunlockput>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	af6080e7          	jalr	-1290(ra) # 80004208 <end_op>
  return -1;
    8000571a:	557d                	li	a0,-1
}
    8000571c:	70ae                	ld	ra,232(sp)
    8000571e:	740e                	ld	s0,224(sp)
    80005720:	64ee                	ld	s1,216(sp)
    80005722:	694e                	ld	s2,208(sp)
    80005724:	69ae                	ld	s3,200(sp)
    80005726:	616d                	addi	sp,sp,240
    80005728:	8082                	ret

000000008000572a <sys_open>:

uint64
sys_open(void)
{
    8000572a:	7131                	addi	sp,sp,-192
    8000572c:	fd06                	sd	ra,184(sp)
    8000572e:	f922                	sd	s0,176(sp)
    80005730:	f526                	sd	s1,168(sp)
    80005732:	f14a                	sd	s2,160(sp)
    80005734:	ed4e                	sd	s3,152(sp)
    80005736:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005738:	08000613          	li	a2,128
    8000573c:	f5040593          	addi	a1,s0,-176
    80005740:	4501                	li	a0,0
    80005742:	ffffd097          	auipc	ra,0xffffd
    80005746:	546080e7          	jalr	1350(ra) # 80002c88 <argstr>
    return -1;
    8000574a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000574c:	0c054163          	bltz	a0,8000580e <sys_open+0xe4>
    80005750:	f4c40593          	addi	a1,s0,-180
    80005754:	4505                	li	a0,1
    80005756:	ffffd097          	auipc	ra,0xffffd
    8000575a:	4ee080e7          	jalr	1262(ra) # 80002c44 <argint>
    8000575e:	0a054863          	bltz	a0,8000580e <sys_open+0xe4>

  begin_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	a26080e7          	jalr	-1498(ra) # 80004188 <begin_op>

  if(omode & O_CREATE){
    8000576a:	f4c42783          	lw	a5,-180(s0)
    8000576e:	2007f793          	andi	a5,a5,512
    80005772:	cbdd                	beqz	a5,80005828 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005774:	4681                	li	a3,0
    80005776:	4601                	li	a2,0
    80005778:	4589                	li	a1,2
    8000577a:	f5040513          	addi	a0,s0,-176
    8000577e:	00000097          	auipc	ra,0x0
    80005782:	972080e7          	jalr	-1678(ra) # 800050f0 <create>
    80005786:	892a                	mv	s2,a0
    if(ip == 0){
    80005788:	c959                	beqz	a0,8000581e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000578a:	04491703          	lh	a4,68(s2)
    8000578e:	478d                	li	a5,3
    80005790:	00f71763          	bne	a4,a5,8000579e <sys_open+0x74>
    80005794:	04695703          	lhu	a4,70(s2)
    80005798:	47a5                	li	a5,9
    8000579a:	0ce7ec63          	bltu	a5,a4,80005872 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	e02080e7          	jalr	-510(ra) # 800045a0 <filealloc>
    800057a6:	89aa                	mv	s3,a0
    800057a8:	10050263          	beqz	a0,800058ac <sys_open+0x182>
    800057ac:	00000097          	auipc	ra,0x0
    800057b0:	902080e7          	jalr	-1790(ra) # 800050ae <fdalloc>
    800057b4:	84aa                	mv	s1,a0
    800057b6:	0e054663          	bltz	a0,800058a2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ba:	04491703          	lh	a4,68(s2)
    800057be:	478d                	li	a5,3
    800057c0:	0cf70463          	beq	a4,a5,80005888 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057c4:	4789                	li	a5,2
    800057c6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057ca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ce:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057d2:	f4c42783          	lw	a5,-180(s0)
    800057d6:	0017c713          	xori	a4,a5,1
    800057da:	8b05                	andi	a4,a4,1
    800057dc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057e0:	0037f713          	andi	a4,a5,3
    800057e4:	00e03733          	snez	a4,a4
    800057e8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ec:	4007f793          	andi	a5,a5,1024
    800057f0:	c791                	beqz	a5,800057fc <sys_open+0xd2>
    800057f2:	04491703          	lh	a4,68(s2)
    800057f6:	4789                	li	a5,2
    800057f8:	08f70f63          	beq	a4,a5,80005896 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057fc:	854a                	mv	a0,s2
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	07a080e7          	jalr	122(ra) # 80003878 <iunlock>
  end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	a02080e7          	jalr	-1534(ra) # 80004208 <end_op>

  return fd;
}
    8000580e:	8526                	mv	a0,s1
    80005810:	70ea                	ld	ra,184(sp)
    80005812:	744a                	ld	s0,176(sp)
    80005814:	74aa                	ld	s1,168(sp)
    80005816:	790a                	ld	s2,160(sp)
    80005818:	69ea                	ld	s3,152(sp)
    8000581a:	6129                	addi	sp,sp,192
    8000581c:	8082                	ret
      end_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	9ea080e7          	jalr	-1558(ra) # 80004208 <end_op>
      return -1;
    80005826:	b7e5                	j	8000580e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005828:	f5040513          	addi	a0,s0,-176
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	740080e7          	jalr	1856(ra) # 80003f6c <namei>
    80005834:	892a                	mv	s2,a0
    80005836:	c905                	beqz	a0,80005866 <sys_open+0x13c>
    ilock(ip);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	f7e080e7          	jalr	-130(ra) # 800037b6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005840:	04491703          	lh	a4,68(s2)
    80005844:	4785                	li	a5,1
    80005846:	f4f712e3          	bne	a4,a5,8000578a <sys_open+0x60>
    8000584a:	f4c42783          	lw	a5,-180(s0)
    8000584e:	dba1                	beqz	a5,8000579e <sys_open+0x74>
      iunlockput(ip);
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	1c6080e7          	jalr	454(ra) # 80003a18 <iunlockput>
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	9ae080e7          	jalr	-1618(ra) # 80004208 <end_op>
      return -1;
    80005862:	54fd                	li	s1,-1
    80005864:	b76d                	j	8000580e <sys_open+0xe4>
      end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	9a2080e7          	jalr	-1630(ra) # 80004208 <end_op>
      return -1;
    8000586e:	54fd                	li	s1,-1
    80005870:	bf79                	j	8000580e <sys_open+0xe4>
    iunlockput(ip);
    80005872:	854a                	mv	a0,s2
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	1a4080e7          	jalr	420(ra) # 80003a18 <iunlockput>
    end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	98c080e7          	jalr	-1652(ra) # 80004208 <end_op>
    return -1;
    80005884:	54fd                	li	s1,-1
    80005886:	b761                	j	8000580e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005888:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000588c:	04691783          	lh	a5,70(s2)
    80005890:	02f99223          	sh	a5,36(s3)
    80005894:	bf2d                	j	800057ce <sys_open+0xa4>
    itrunc(ip);
    80005896:	854a                	mv	a0,s2
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	02c080e7          	jalr	44(ra) # 800038c4 <itrunc>
    800058a0:	bfb1                	j	800057fc <sys_open+0xd2>
      fileclose(f);
    800058a2:	854e                	mv	a0,s3
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	db8080e7          	jalr	-584(ra) # 8000465c <fileclose>
    iunlockput(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	16a080e7          	jalr	362(ra) # 80003a18 <iunlockput>
    end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	952080e7          	jalr	-1710(ra) # 80004208 <end_op>
    return -1;
    800058be:	54fd                	li	s1,-1
    800058c0:	b7b9                	j	8000580e <sys_open+0xe4>

00000000800058c2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058c2:	7175                	addi	sp,sp,-144
    800058c4:	e506                	sd	ra,136(sp)
    800058c6:	e122                	sd	s0,128(sp)
    800058c8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	8be080e7          	jalr	-1858(ra) # 80004188 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058d2:	08000613          	li	a2,128
    800058d6:	f7040593          	addi	a1,s0,-144
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	3ac080e7          	jalr	940(ra) # 80002c88 <argstr>
    800058e4:	02054963          	bltz	a0,80005916 <sys_mkdir+0x54>
    800058e8:	4681                	li	a3,0
    800058ea:	4601                	li	a2,0
    800058ec:	4585                	li	a1,1
    800058ee:	f7040513          	addi	a0,s0,-144
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	7fe080e7          	jalr	2046(ra) # 800050f0 <create>
    800058fa:	cd11                	beqz	a0,80005916 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	11c080e7          	jalr	284(ra) # 80003a18 <iunlockput>
  end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	904080e7          	jalr	-1788(ra) # 80004208 <end_op>
  return 0;
    8000590c:	4501                	li	a0,0
}
    8000590e:	60aa                	ld	ra,136(sp)
    80005910:	640a                	ld	s0,128(sp)
    80005912:	6149                	addi	sp,sp,144
    80005914:	8082                	ret
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	8f2080e7          	jalr	-1806(ra) # 80004208 <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	b7fd                	j	8000590e <sys_mkdir+0x4c>

0000000080005922 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005922:	7135                	addi	sp,sp,-160
    80005924:	ed06                	sd	ra,152(sp)
    80005926:	e922                	sd	s0,144(sp)
    80005928:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	85e080e7          	jalr	-1954(ra) # 80004188 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005932:	08000613          	li	a2,128
    80005936:	f7040593          	addi	a1,s0,-144
    8000593a:	4501                	li	a0,0
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	34c080e7          	jalr	844(ra) # 80002c88 <argstr>
    80005944:	04054a63          	bltz	a0,80005998 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005948:	f6c40593          	addi	a1,s0,-148
    8000594c:	4505                	li	a0,1
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	2f6080e7          	jalr	758(ra) # 80002c44 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005956:	04054163          	bltz	a0,80005998 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000595a:	f6840593          	addi	a1,s0,-152
    8000595e:	4509                	li	a0,2
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	2e4080e7          	jalr	740(ra) # 80002c44 <argint>
     argint(1, &major) < 0 ||
    80005968:	02054863          	bltz	a0,80005998 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000596c:	f6841683          	lh	a3,-152(s0)
    80005970:	f6c41603          	lh	a2,-148(s0)
    80005974:	458d                	li	a1,3
    80005976:	f7040513          	addi	a0,s0,-144
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	776080e7          	jalr	1910(ra) # 800050f0 <create>
     argint(2, &minor) < 0 ||
    80005982:	c919                	beqz	a0,80005998 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	094080e7          	jalr	148(ra) # 80003a18 <iunlockput>
  end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	87c080e7          	jalr	-1924(ra) # 80004208 <end_op>
  return 0;
    80005994:	4501                	li	a0,0
    80005996:	a031                	j	800059a2 <sys_mknod+0x80>
    end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	870080e7          	jalr	-1936(ra) # 80004208 <end_op>
    return -1;
    800059a0:	557d                	li	a0,-1
}
    800059a2:	60ea                	ld	ra,152(sp)
    800059a4:	644a                	ld	s0,144(sp)
    800059a6:	610d                	addi	sp,sp,160
    800059a8:	8082                	ret

00000000800059aa <sys_chdir>:

uint64
sys_chdir(void)
{
    800059aa:	7135                	addi	sp,sp,-160
    800059ac:	ed06                	sd	ra,152(sp)
    800059ae:	e922                	sd	s0,144(sp)
    800059b0:	e526                	sd	s1,136(sp)
    800059b2:	e14a                	sd	s2,128(sp)
    800059b4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059b6:	ffffc097          	auipc	ra,0xffffc
    800059ba:	ff0080e7          	jalr	-16(ra) # 800019a6 <myproc>
    800059be:	892a                	mv	s2,a0
  
  begin_op();
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	7c8080e7          	jalr	1992(ra) # 80004188 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c8:	08000613          	li	a2,128
    800059cc:	f6040593          	addi	a1,s0,-160
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	2b6080e7          	jalr	694(ra) # 80002c88 <argstr>
    800059da:	04054b63          	bltz	a0,80005a30 <sys_chdir+0x86>
    800059de:	f6040513          	addi	a0,s0,-160
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	58a080e7          	jalr	1418(ra) # 80003f6c <namei>
    800059ea:	84aa                	mv	s1,a0
    800059ec:	c131                	beqz	a0,80005a30 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	dc8080e7          	jalr	-568(ra) # 800037b6 <ilock>
  if(ip->type != T_DIR){
    800059f6:	04449703          	lh	a4,68(s1)
    800059fa:	4785                	li	a5,1
    800059fc:	04f71063          	bne	a4,a5,80005a3c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a00:	8526                	mv	a0,s1
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	e76080e7          	jalr	-394(ra) # 80003878 <iunlock>
  iput(p->cwd);
    80005a0a:	15093503          	ld	a0,336(s2)
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	f62080e7          	jalr	-158(ra) # 80003970 <iput>
  end_op();
    80005a16:	ffffe097          	auipc	ra,0xffffe
    80005a1a:	7f2080e7          	jalr	2034(ra) # 80004208 <end_op>
  p->cwd = ip;
    80005a1e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a22:	4501                	li	a0,0
}
    80005a24:	60ea                	ld	ra,152(sp)
    80005a26:	644a                	ld	s0,144(sp)
    80005a28:	64aa                	ld	s1,136(sp)
    80005a2a:	690a                	ld	s2,128(sp)
    80005a2c:	610d                	addi	sp,sp,160
    80005a2e:	8082                	ret
    end_op();
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	7d8080e7          	jalr	2008(ra) # 80004208 <end_op>
    return -1;
    80005a38:	557d                	li	a0,-1
    80005a3a:	b7ed                	j	80005a24 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	fda080e7          	jalr	-38(ra) # 80003a18 <iunlockput>
    end_op();
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	7c2080e7          	jalr	1986(ra) # 80004208 <end_op>
    return -1;
    80005a4e:	557d                	li	a0,-1
    80005a50:	bfd1                	j	80005a24 <sys_chdir+0x7a>

0000000080005a52 <sys_exec>:

uint64
sys_exec(void)
{
    80005a52:	7145                	addi	sp,sp,-464
    80005a54:	e786                	sd	ra,456(sp)
    80005a56:	e3a2                	sd	s0,448(sp)
    80005a58:	ff26                	sd	s1,440(sp)
    80005a5a:	fb4a                	sd	s2,432(sp)
    80005a5c:	f74e                	sd	s3,424(sp)
    80005a5e:	f352                	sd	s4,416(sp)
    80005a60:	ef56                	sd	s5,408(sp)
    80005a62:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a64:	08000613          	li	a2,128
    80005a68:	f4040593          	addi	a1,s0,-192
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	21a080e7          	jalr	538(ra) # 80002c88 <argstr>
    return -1;
    80005a76:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a78:	0c054a63          	bltz	a0,80005b4c <sys_exec+0xfa>
    80005a7c:	e3840593          	addi	a1,s0,-456
    80005a80:	4505                	li	a0,1
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	1e4080e7          	jalr	484(ra) # 80002c66 <argaddr>
    80005a8a:	0c054163          	bltz	a0,80005b4c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a8e:	10000613          	li	a2,256
    80005a92:	4581                	li	a1,0
    80005a94:	e4040513          	addi	a0,s0,-448
    80005a98:	ffffb097          	auipc	ra,0xffffb
    80005a9c:	23a080e7          	jalr	570(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aa0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aa4:	89a6                	mv	s3,s1
    80005aa6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa8:	02000a13          	li	s4,32
    80005aac:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ab0:	00391513          	slli	a0,s2,0x3
    80005ab4:	e3040593          	addi	a1,s0,-464
    80005ab8:	e3843783          	ld	a5,-456(s0)
    80005abc:	953e                	add	a0,a0,a5
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	0ec080e7          	jalr	236(ra) # 80002baa <fetchaddr>
    80005ac6:	02054a63          	bltz	a0,80005afa <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aca:	e3043783          	ld	a5,-464(s0)
    80005ace:	c3b9                	beqz	a5,80005b14 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ad0:	ffffb097          	auipc	ra,0xffffb
    80005ad4:	016080e7          	jalr	22(ra) # 80000ae6 <kalloc>
    80005ad8:	85aa                	mv	a1,a0
    80005ada:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ade:	cd11                	beqz	a0,80005afa <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ae0:	6605                	lui	a2,0x1
    80005ae2:	e3043503          	ld	a0,-464(s0)
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	116080e7          	jalr	278(ra) # 80002bfc <fetchstr>
    80005aee:	00054663          	bltz	a0,80005afa <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005af2:	0905                	addi	s2,s2,1
    80005af4:	09a1                	addi	s3,s3,8
    80005af6:	fb491be3          	bne	s2,s4,80005aac <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afa:	10048913          	addi	s2,s1,256
    80005afe:	6088                	ld	a0,0(s1)
    80005b00:	c529                	beqz	a0,80005b4a <sys_exec+0xf8>
    kfree(argv[i]);
    80005b02:	ffffb097          	auipc	ra,0xffffb
    80005b06:	ee8080e7          	jalr	-280(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0a:	04a1                	addi	s1,s1,8
    80005b0c:	ff2499e3          	bne	s1,s2,80005afe <sys_exec+0xac>
  return -1;
    80005b10:	597d                	li	s2,-1
    80005b12:	a82d                	j	80005b4c <sys_exec+0xfa>
      argv[i] = 0;
    80005b14:	0a8e                	slli	s5,s5,0x3
    80005b16:	fc040793          	addi	a5,s0,-64
    80005b1a:	9abe                	add	s5,s5,a5
    80005b1c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b20:	e4040593          	addi	a1,s0,-448
    80005b24:	f4040513          	addi	a0,s0,-192
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	194080e7          	jalr	404(ra) # 80004cbc <exec>
    80005b30:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b32:	10048993          	addi	s3,s1,256
    80005b36:	6088                	ld	a0,0(s1)
    80005b38:	c911                	beqz	a0,80005b4c <sys_exec+0xfa>
    kfree(argv[i]);
    80005b3a:	ffffb097          	auipc	ra,0xffffb
    80005b3e:	eb0080e7          	jalr	-336(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b42:	04a1                	addi	s1,s1,8
    80005b44:	ff3499e3          	bne	s1,s3,80005b36 <sys_exec+0xe4>
    80005b48:	a011                	j	80005b4c <sys_exec+0xfa>
  return -1;
    80005b4a:	597d                	li	s2,-1
}
    80005b4c:	854a                	mv	a0,s2
    80005b4e:	60be                	ld	ra,456(sp)
    80005b50:	641e                	ld	s0,448(sp)
    80005b52:	74fa                	ld	s1,440(sp)
    80005b54:	795a                	ld	s2,432(sp)
    80005b56:	79ba                	ld	s3,424(sp)
    80005b58:	7a1a                	ld	s4,416(sp)
    80005b5a:	6afa                	ld	s5,408(sp)
    80005b5c:	6179                	addi	sp,sp,464
    80005b5e:	8082                	ret

0000000080005b60 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b60:	7139                	addi	sp,sp,-64
    80005b62:	fc06                	sd	ra,56(sp)
    80005b64:	f822                	sd	s0,48(sp)
    80005b66:	f426                	sd	s1,40(sp)
    80005b68:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b6a:	ffffc097          	auipc	ra,0xffffc
    80005b6e:	e3c080e7          	jalr	-452(ra) # 800019a6 <myproc>
    80005b72:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b74:	fd840593          	addi	a1,s0,-40
    80005b78:	4501                	li	a0,0
    80005b7a:	ffffd097          	auipc	ra,0xffffd
    80005b7e:	0ec080e7          	jalr	236(ra) # 80002c66 <argaddr>
    return -1;
    80005b82:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b84:	0e054063          	bltz	a0,80005c64 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b88:	fc840593          	addi	a1,s0,-56
    80005b8c:	fd040513          	addi	a0,s0,-48
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	dfc080e7          	jalr	-516(ra) # 8000498c <pipealloc>
    return -1;
    80005b98:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b9a:	0c054563          	bltz	a0,80005c64 <sys_pipe+0x104>
  fd0 = -1;
    80005b9e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ba2:	fd043503          	ld	a0,-48(s0)
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	508080e7          	jalr	1288(ra) # 800050ae <fdalloc>
    80005bae:	fca42223          	sw	a0,-60(s0)
    80005bb2:	08054c63          	bltz	a0,80005c4a <sys_pipe+0xea>
    80005bb6:	fc843503          	ld	a0,-56(s0)
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	4f4080e7          	jalr	1268(ra) # 800050ae <fdalloc>
    80005bc2:	fca42023          	sw	a0,-64(s0)
    80005bc6:	06054863          	bltz	a0,80005c36 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bca:	4691                	li	a3,4
    80005bcc:	fc440613          	addi	a2,s0,-60
    80005bd0:	fd843583          	ld	a1,-40(s0)
    80005bd4:	68a8                	ld	a0,80(s1)
    80005bd6:	ffffc097          	auipc	ra,0xffffc
    80005bda:	a66080e7          	jalr	-1434(ra) # 8000163c <copyout>
    80005bde:	02054063          	bltz	a0,80005bfe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005be2:	4691                	li	a3,4
    80005be4:	fc040613          	addi	a2,s0,-64
    80005be8:	fd843583          	ld	a1,-40(s0)
    80005bec:	0591                	addi	a1,a1,4
    80005bee:	68a8                	ld	a0,80(s1)
    80005bf0:	ffffc097          	auipc	ra,0xffffc
    80005bf4:	a4c080e7          	jalr	-1460(ra) # 8000163c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bfa:	06055563          	bgez	a0,80005c64 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bfe:	fc442783          	lw	a5,-60(s0)
    80005c02:	07e9                	addi	a5,a5,26
    80005c04:	078e                	slli	a5,a5,0x3
    80005c06:	97a6                	add	a5,a5,s1
    80005c08:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c0c:	fc042503          	lw	a0,-64(s0)
    80005c10:	0569                	addi	a0,a0,26
    80005c12:	050e                	slli	a0,a0,0x3
    80005c14:	9526                	add	a0,a0,s1
    80005c16:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c1a:	fd043503          	ld	a0,-48(s0)
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	a3e080e7          	jalr	-1474(ra) # 8000465c <fileclose>
    fileclose(wf);
    80005c26:	fc843503          	ld	a0,-56(s0)
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	a32080e7          	jalr	-1486(ra) # 8000465c <fileclose>
    return -1;
    80005c32:	57fd                	li	a5,-1
    80005c34:	a805                	j	80005c64 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c36:	fc442783          	lw	a5,-60(s0)
    80005c3a:	0007c863          	bltz	a5,80005c4a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c3e:	01a78513          	addi	a0,a5,26
    80005c42:	050e                	slli	a0,a0,0x3
    80005c44:	9526                	add	a0,a0,s1
    80005c46:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c4a:	fd043503          	ld	a0,-48(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	a0e080e7          	jalr	-1522(ra) # 8000465c <fileclose>
    fileclose(wf);
    80005c56:	fc843503          	ld	a0,-56(s0)
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	a02080e7          	jalr	-1534(ra) # 8000465c <fileclose>
    return -1;
    80005c62:	57fd                	li	a5,-1
}
    80005c64:	853e                	mv	a0,a5
    80005c66:	70e2                	ld	ra,56(sp)
    80005c68:	7442                	ld	s0,48(sp)
    80005c6a:	74a2                	ld	s1,40(sp)
    80005c6c:	6121                	addi	sp,sp,64
    80005c6e:	8082                	ret

0000000080005c70 <sys_mmap>:

uint64
sys_mmap(void)
{
    80005c70:	711d                	addi	sp,sp,-96
    80005c72:	ec86                	sd	ra,88(sp)
    80005c74:	e8a2                	sd	s0,80(sp)
    80005c76:	e4a6                	sd	s1,72(sp)
    80005c78:	e0ca                	sd	s2,64(sp)
    80005c7a:	fc4e                	sd	s3,56(sp)
    80005c7c:	1080                	addi	s0,sp,96
  uint64 addr;
  int length, prot, flags, fd, offset;
  struct file *file;
  struct proc *p = myproc();
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	d28080e7          	jalr	-728(ra) # 800019a6 <myproc>
    80005c86:	892a                	mv	s2,a0
  if(argaddr(0, &addr) || argint(1, &length) || argint(2, &prot) ||
    80005c88:	fc840593          	addi	a1,s0,-56
    80005c8c:	4501                	li	a0,0
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	fd8080e7          	jalr	-40(ra) # 80002c66 <argaddr>
    argint(3, &flags) || argfd(4, &fd, &file) || argint(5, &offset)) {
    return -1;
    80005c96:	57fd                	li	a5,-1
  if(argaddr(0, &addr) || argint(1, &length) || argint(2, &prot) ||
    80005c98:	ed45                	bnez	a0,80005d50 <sys_mmap+0xe0>
    80005c9a:	fc440593          	addi	a1,s0,-60
    80005c9e:	4505                	li	a0,1
    80005ca0:	ffffd097          	auipc	ra,0xffffd
    80005ca4:	fa4080e7          	jalr	-92(ra) # 80002c44 <argint>
    return -1;
    80005ca8:	57fd                	li	a5,-1
  if(argaddr(0, &addr) || argint(1, &length) || argint(2, &prot) ||
    80005caa:	e15d                	bnez	a0,80005d50 <sys_mmap+0xe0>
    80005cac:	fc040593          	addi	a1,s0,-64
    80005cb0:	4509                	li	a0,2
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	f92080e7          	jalr	-110(ra) # 80002c44 <argint>
    return -1;
    80005cba:	57fd                	li	a5,-1
  if(argaddr(0, &addr) || argint(1, &length) || argint(2, &prot) ||
    80005cbc:	e951                	bnez	a0,80005d50 <sys_mmap+0xe0>
    argint(3, &flags) || argfd(4, &fd, &file) || argint(5, &offset)) {
    80005cbe:	fbc40593          	addi	a1,s0,-68
    80005cc2:	450d                	li	a0,3
    80005cc4:	ffffd097          	auipc	ra,0xffffd
    80005cc8:	f80080e7          	jalr	-128(ra) # 80002c44 <argint>
    return -1;
    80005ccc:	57fd                	li	a5,-1
  if(argaddr(0, &addr) || argint(1, &length) || argint(2, &prot) ||
    80005cce:	e149                	bnez	a0,80005d50 <sys_mmap+0xe0>
    argint(3, &flags) || argfd(4, &fd, &file) || argint(5, &offset)) {
    80005cd0:	fa840613          	addi	a2,s0,-88
    80005cd4:	fb840593          	addi	a1,s0,-72
    80005cd8:	4511                	li	a0,4
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	36c080e7          	jalr	876(ra) # 80005046 <argfd>
    return -1;
    80005ce2:	57fd                	li	a5,-1
    argint(3, &flags) || argfd(4, &fd, &file) || argint(5, &offset)) {
    80005ce4:	e535                	bnez	a0,80005d50 <sys_mmap+0xe0>
    80005ce6:	fb440593          	addi	a1,s0,-76
    80005cea:	4515                	li	a0,5
    80005cec:	ffffd097          	auipc	ra,0xffffd
    80005cf0:	f58080e7          	jalr	-168(ra) # 80002c44 <argint>
    80005cf4:	84aa                	mv	s1,a0
    return -1;
    80005cf6:	57fd                	li	a5,-1
    argint(3, &flags) || argfd(4, &fd, &file) || argint(5, &offset)) {
    80005cf8:	ed21                	bnez	a0,80005d50 <sys_mmap+0xe0>
  }
  if(!file->writable && (prot & PROT_WRITE) && flags == MAP_SHARED)
    80005cfa:	fa843503          	ld	a0,-88(s0)
    80005cfe:	00954783          	lbu	a5,9(a0)
    80005d02:	eb91                	bnez	a5,80005d16 <sys_mmap+0xa6>
    80005d04:	fc042783          	lw	a5,-64(s0)
    80005d08:	8b89                	andi	a5,a5,2
    80005d0a:	c791                	beqz	a5,80005d16 <sys_mmap+0xa6>
    80005d0c:	fbc42703          	lw	a4,-68(s0)
    80005d10:	4785                	li	a5,1
    80005d12:	0af70863          	beq	a4,a5,80005dc2 <sys_mmap+0x152>
    return -1;
  length = PGROUNDUP(length);
    80005d16:	fc442683          	lw	a3,-60(s0)
    80005d1a:	6785                	lui	a5,0x1
    80005d1c:	37fd                	addiw	a5,a5,-1
    80005d1e:	9ebd                	addw	a3,a3,a5
    80005d20:	77fd                	lui	a5,0xfffff
    80005d22:	8efd                	and	a3,a3,a5
    80005d24:	2681                	sext.w	a3,a3
    80005d26:	fcd42223          	sw	a3,-60(s0)
  if(p->sz > MAXVA - length)
    80005d2a:	04893583          	ld	a1,72(s2)
    80005d2e:	4705                	li	a4,1
    80005d30:	171a                	slli	a4,a4,0x26
    80005d32:	8f15                	sub	a4,a4,a3
    return -1;
    80005d34:	57fd                	li	a5,-1
  if(p->sz > MAXVA - length)
    80005d36:	00b76d63          	bltu	a4,a1,80005d50 <sys_mmap+0xe0>
    80005d3a:	16890793          	addi	a5,s2,360
  for(int i = 0; i < VMASIZE; i++) {
    80005d3e:	4641                	li	a2,16
    //printf("mmap: %d, addr: %d, used: %d\n", i, p->vma[i].addr, p->vma[i].used);
    if(p->vma[i].used == 0) {
    80005d40:	4398                	lw	a4,0(a5)
    80005d42:	cf19                	beqz	a4,80005d60 <sys_mmap+0xf0>
  for(int i = 0; i < VMASIZE; i++) {
    80005d44:	2485                	addiw	s1,s1,1
    80005d46:	03078793          	addi	a5,a5,48 # fffffffffffff030 <end+0xffffffff7ffcd030>
    80005d4a:	fec49be3          	bne	s1,a2,80005d40 <sys_mmap+0xd0>
      p->sz += length;
      //printf("p->sz: %d\n", p->sz);
      return p->vma[i].addr;
    }
  }
  return -1;
    80005d4e:	57fd                	li	a5,-1
}
    80005d50:	853e                	mv	a0,a5
    80005d52:	60e6                	ld	ra,88(sp)
    80005d54:	6446                	ld	s0,80(sp)
    80005d56:	64a6                	ld	s1,72(sp)
    80005d58:	6906                	ld	s2,64(sp)
    80005d5a:	79e2                	ld	s3,56(sp)
    80005d5c:	6125                	addi	sp,sp,96
    80005d5e:	8082                	ret
      p->vma[i].used = 1;
    80005d60:	00149993          	slli	s3,s1,0x1
    80005d64:	009987b3          	add	a5,s3,s1
    80005d68:	0792                	slli	a5,a5,0x4
    80005d6a:	97ca                	add	a5,a5,s2
    80005d6c:	4705                	li	a4,1
    80005d6e:	16e7a423          	sw	a4,360(a5)
      p->vma[i].addr = p->sz;
    80005d72:	16b7b823          	sd	a1,368(a5)
      p->vma[i].length = length;
    80005d76:	16d7ac23          	sw	a3,376(a5)
      p->vma[i].prot = prot;
    80005d7a:	fc042703          	lw	a4,-64(s0)
    80005d7e:	16e7ae23          	sw	a4,380(a5)
      p->vma[i].flags = flags;
    80005d82:	fbc42703          	lw	a4,-68(s0)
    80005d86:	18e7a023          	sw	a4,384(a5)
      p->vma[i].fd = fd;
    80005d8a:	fb842703          	lw	a4,-72(s0)
    80005d8e:	18e7a223          	sw	a4,388(a5)
      p->vma[i].file = file;
    80005d92:	18a7b823          	sd	a0,400(a5)
      p->vma[i].offset = offset;
    80005d96:	fb442703          	lw	a4,-76(s0)
    80005d9a:	18e7a423          	sw	a4,392(a5)
      filedup(file);
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	86c080e7          	jalr	-1940(ra) # 8000460a <filedup>
      p->sz += length;
    80005da6:	fc442703          	lw	a4,-60(s0)
    80005daa:	04893783          	ld	a5,72(s2)
    80005dae:	97ba                	add	a5,a5,a4
    80005db0:	04f93423          	sd	a5,72(s2)
      return p->vma[i].addr;
    80005db4:	00998533          	add	a0,s3,s1
    80005db8:	0512                	slli	a0,a0,0x4
    80005dba:	954a                	add	a0,a0,s2
    80005dbc:	17053783          	ld	a5,368(a0)
    80005dc0:	bf41                	j	80005d50 <sys_mmap+0xe0>
    return -1;
    80005dc2:	57fd                	li	a5,-1
    80005dc4:	b771                	j	80005d50 <sys_mmap+0xe0>

0000000080005dc6 <sys_munmap>:

uint64
sys_munmap(void)
{
    80005dc6:	7139                	addi	sp,sp,-64
    80005dc8:	fc06                	sd	ra,56(sp)
    80005dca:	f822                	sd	s0,48(sp)
    80005dcc:	f426                	sd	s1,40(sp)
    80005dce:	f04a                	sd	s2,32(sp)
    80005dd0:	ec4e                	sd	s3,24(sp)
    80005dd2:	0080                	addi	s0,sp,64
  uint64 addr;
  int length;
  struct proc *p = myproc();
    80005dd4:	ffffc097          	auipc	ra,0xffffc
    80005dd8:	bd2080e7          	jalr	-1070(ra) # 800019a6 <myproc>
    80005ddc:	892a                	mv	s2,a0
  struct vma *vma = 0;
  if(argaddr(0, &addr) || argint(1, &length))
    80005dde:	fc840593          	addi	a1,s0,-56
    80005de2:	4501                	li	a0,0
    80005de4:	ffffd097          	auipc	ra,0xffffd
    80005de8:	e82080e7          	jalr	-382(ra) # 80002c66 <argaddr>
    return -1;
    80005dec:	57fd                	li	a5,-1
  if(argaddr(0, &addr) || argint(1, &length))
    80005dee:	e535                	bnez	a0,80005e5a <sys_munmap+0x94>
    80005df0:	fc440593          	addi	a1,s0,-60
    80005df4:	4505                	li	a0,1
    80005df6:	ffffd097          	auipc	ra,0xffffd
    80005dfa:	e4e080e7          	jalr	-434(ra) # 80002c44 <argint>
    80005dfe:	84aa                	mv	s1,a0
    return -1;
    80005e00:	57fd                	li	a5,-1
  if(argaddr(0, &addr) || argint(1, &length))
    80005e02:	ed21                	bnez	a0,80005e5a <sys_munmap+0x94>
  addr = PGROUNDDOWN(addr);
    80005e04:	77fd                	lui	a5,0xfffff
    80005e06:	fc843583          	ld	a1,-56(s0)
    80005e0a:	8dfd                	and	a1,a1,a5
    80005e0c:	fcb43423          	sd	a1,-56(s0)
  length = PGROUNDUP(length);
    80005e10:	fc442603          	lw	a2,-60(s0)
    80005e14:	6785                	lui	a5,0x1
    80005e16:	37fd                	addiw	a5,a5,-1
    80005e18:	9e3d                	addw	a2,a2,a5
    80005e1a:	77fd                	lui	a5,0xfffff
    80005e1c:	8e7d                	and	a2,a2,a5
    80005e1e:	2601                	sext.w	a2,a2
    80005e20:	fcc42223          	sw	a2,-60(s0)
  for(int i = 0; i < VMASIZE; i++) {
    80005e24:	17090793          	addi	a5,s2,368
    80005e28:	4541                	li	a0,16
    if (addr >= p->vma[i].addr || addr < p->vma[i].addr + p->vma[i].length) {
    80005e2a:	6394                	ld	a3,0(a5)
    80005e2c:	00d5fd63          	bgeu	a1,a3,80005e46 <sys_munmap+0x80>
    80005e30:	4798                	lw	a4,8(a5)
    80005e32:	9736                	add	a4,a4,a3
    80005e34:	00e5e963          	bltu	a1,a4,80005e46 <sys_munmap+0x80>
  for(int i = 0; i < VMASIZE; i++) {
    80005e38:	2485                	addiw	s1,s1,1
    80005e3a:	03078793          	addi	a5,a5,48 # fffffffffffff030 <end+0xffffffff7ffcd030>
    80005e3e:	fea496e3          	bne	s1,a0,80005e2a <sys_munmap+0x64>
      vma = &p->vma[i];
	  //printf("munmap: %d\t", i);
      break;
    }
  }
  if(vma == 0) return 0;
    80005e42:	4781                	li	a5,0
    80005e44:	a819                	j	80005e5a <sys_munmap+0x94>
  if(vma->addr == addr) {
    80005e46:	00149793          	slli	a5,s1,0x1
    80005e4a:	97a6                	add	a5,a5,s1
    80005e4c:	0792                	slli	a5,a5,0x4
    80005e4e:	97ca                	add	a5,a5,s2
    80005e50:	1707b703          	ld	a4,368(a5)
    if(vma->length == 0) {
      fileclose(vma->file);
      vma->used = 0;
    }
  }
  return 0;
    80005e54:	4781                	li	a5,0
  if(vma->addr == addr) {
    80005e56:	00e58a63          	beq	a1,a4,80005e6a <sys_munmap+0xa4>
}
    80005e5a:	853e                	mv	a0,a5
    80005e5c:	70e2                	ld	ra,56(sp)
    80005e5e:	7442                	ld	s0,48(sp)
    80005e60:	74a2                	ld	s1,40(sp)
    80005e62:	7902                	ld	s2,32(sp)
    80005e64:	69e2                	ld	s3,24(sp)
    80005e66:	6121                	addi	sp,sp,64
    80005e68:	8082                	ret
    vma->addr += length;
    80005e6a:	00149793          	slli	a5,s1,0x1
    80005e6e:	97a6                	add	a5,a5,s1
    80005e70:	0792                	slli	a5,a5,0x4
    80005e72:	97ca                	add	a5,a5,s2
    80005e74:	9732                	add	a4,a4,a2
    80005e76:	16e7b823          	sd	a4,368(a5)
    vma->length -= length;
    80005e7a:	1787a703          	lw	a4,376(a5)
    80005e7e:	9f11                	subw	a4,a4,a2
    80005e80:	16e7ac23          	sw	a4,376(a5)
    if(vma->flags & MAP_SHARED)
    80005e84:	1807a783          	lw	a5,384(a5)
    80005e88:	8b85                	andi	a5,a5,1
    80005e8a:	e3a5                	bnez	a5,80005eea <sys_munmap+0x124>
    uvmunmap(p->pagetable, addr, length/PGSIZE, 1);
    80005e8c:	fc442783          	lw	a5,-60(s0)
    80005e90:	41f7d61b          	sraiw	a2,a5,0x1f
    80005e94:	0146561b          	srliw	a2,a2,0x14
    80005e98:	9e3d                	addw	a2,a2,a5
    80005e9a:	4685                	li	a3,1
    80005e9c:	40c6561b          	sraiw	a2,a2,0xc
    80005ea0:	fc843583          	ld	a1,-56(s0)
    80005ea4:	05093503          	ld	a0,80(s2)
    80005ea8:	ffffb097          	auipc	ra,0xffffb
    80005eac:	3b2080e7          	jalr	946(ra) # 8000125a <uvmunmap>
    if(vma->length == 0) {
    80005eb0:	00149793          	slli	a5,s1,0x1
    80005eb4:	97a6                	add	a5,a5,s1
    80005eb6:	0792                	slli	a5,a5,0x4
    80005eb8:	97ca                	add	a5,a5,s2
    80005eba:	1787a703          	lw	a4,376(a5)
  return 0;
    80005ebe:	4781                	li	a5,0
    if(vma->length == 0) {
    80005ec0:	ff49                	bnez	a4,80005e5a <sys_munmap+0x94>
      fileclose(vma->file);
    80005ec2:	00149993          	slli	s3,s1,0x1
    80005ec6:	009987b3          	add	a5,s3,s1
    80005eca:	0792                	slli	a5,a5,0x4
    80005ecc:	97ca                	add	a5,a5,s2
    80005ece:	1907b503          	ld	a0,400(a5)
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	78a080e7          	jalr	1930(ra) # 8000465c <fileclose>
      vma->used = 0;
    80005eda:	009987b3          	add	a5,s3,s1
    80005ede:	0792                	slli	a5,a5,0x4
    80005ee0:	993e                	add	s2,s2,a5
    80005ee2:	16092423          	sw	zero,360(s2)
  return 0;
    80005ee6:	4781                	li	a5,0
    80005ee8:	bf8d                	j	80005e5a <sys_munmap+0x94>
      filewrite(vma->file, addr, length);
    80005eea:	00149793          	slli	a5,s1,0x1
    80005eee:	97a6                	add	a5,a5,s1
    80005ef0:	0792                	slli	a5,a5,0x4
    80005ef2:	97ca                	add	a5,a5,s2
    80005ef4:	1907b503          	ld	a0,400(a5)
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	960080e7          	jalr	-1696(ra) # 80004858 <filewrite>
    80005f00:	b771                	j	80005e8c <sys_munmap+0xc6>
	...

0000000080005f10 <kernelvec>:
    80005f10:	7111                	addi	sp,sp,-256
    80005f12:	e006                	sd	ra,0(sp)
    80005f14:	e40a                	sd	sp,8(sp)
    80005f16:	e80e                	sd	gp,16(sp)
    80005f18:	ec12                	sd	tp,24(sp)
    80005f1a:	f016                	sd	t0,32(sp)
    80005f1c:	f41a                	sd	t1,40(sp)
    80005f1e:	f81e                	sd	t2,48(sp)
    80005f20:	fc22                	sd	s0,56(sp)
    80005f22:	e0a6                	sd	s1,64(sp)
    80005f24:	e4aa                	sd	a0,72(sp)
    80005f26:	e8ae                	sd	a1,80(sp)
    80005f28:	ecb2                	sd	a2,88(sp)
    80005f2a:	f0b6                	sd	a3,96(sp)
    80005f2c:	f4ba                	sd	a4,104(sp)
    80005f2e:	f8be                	sd	a5,112(sp)
    80005f30:	fcc2                	sd	a6,120(sp)
    80005f32:	e146                	sd	a7,128(sp)
    80005f34:	e54a                	sd	s2,136(sp)
    80005f36:	e94e                	sd	s3,144(sp)
    80005f38:	ed52                	sd	s4,152(sp)
    80005f3a:	f156                	sd	s5,160(sp)
    80005f3c:	f55a                	sd	s6,168(sp)
    80005f3e:	f95e                	sd	s7,176(sp)
    80005f40:	fd62                	sd	s8,184(sp)
    80005f42:	e1e6                	sd	s9,192(sp)
    80005f44:	e5ea                	sd	s10,200(sp)
    80005f46:	e9ee                	sd	s11,208(sp)
    80005f48:	edf2                	sd	t3,216(sp)
    80005f4a:	f1f6                	sd	t4,224(sp)
    80005f4c:	f5fa                	sd	t5,232(sp)
    80005f4e:	f9fe                	sd	t6,240(sp)
    80005f50:	b27fc0ef          	jal	ra,80002a76 <kerneltrap>
    80005f54:	6082                	ld	ra,0(sp)
    80005f56:	6122                	ld	sp,8(sp)
    80005f58:	61c2                	ld	gp,16(sp)
    80005f5a:	7282                	ld	t0,32(sp)
    80005f5c:	7322                	ld	t1,40(sp)
    80005f5e:	73c2                	ld	t2,48(sp)
    80005f60:	7462                	ld	s0,56(sp)
    80005f62:	6486                	ld	s1,64(sp)
    80005f64:	6526                	ld	a0,72(sp)
    80005f66:	65c6                	ld	a1,80(sp)
    80005f68:	6666                	ld	a2,88(sp)
    80005f6a:	7686                	ld	a3,96(sp)
    80005f6c:	7726                	ld	a4,104(sp)
    80005f6e:	77c6                	ld	a5,112(sp)
    80005f70:	7866                	ld	a6,120(sp)
    80005f72:	688a                	ld	a7,128(sp)
    80005f74:	692a                	ld	s2,136(sp)
    80005f76:	69ca                	ld	s3,144(sp)
    80005f78:	6a6a                	ld	s4,152(sp)
    80005f7a:	7a8a                	ld	s5,160(sp)
    80005f7c:	7b2a                	ld	s6,168(sp)
    80005f7e:	7bca                	ld	s7,176(sp)
    80005f80:	7c6a                	ld	s8,184(sp)
    80005f82:	6c8e                	ld	s9,192(sp)
    80005f84:	6d2e                	ld	s10,200(sp)
    80005f86:	6dce                	ld	s11,208(sp)
    80005f88:	6e6e                	ld	t3,216(sp)
    80005f8a:	7e8e                	ld	t4,224(sp)
    80005f8c:	7f2e                	ld	t5,232(sp)
    80005f8e:	7fce                	ld	t6,240(sp)
    80005f90:	6111                	addi	sp,sp,256
    80005f92:	10200073          	sret
    80005f96:	00000013          	nop
    80005f9a:	00000013          	nop
    80005f9e:	0001                	nop

0000000080005fa0 <timervec>:
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	e10c                	sd	a1,0(a0)
    80005fa6:	e510                	sd	a2,8(a0)
    80005fa8:	e914                	sd	a3,16(a0)
    80005faa:	6d0c                	ld	a1,24(a0)
    80005fac:	7110                	ld	a2,32(a0)
    80005fae:	6194                	ld	a3,0(a1)
    80005fb0:	96b2                	add	a3,a3,a2
    80005fb2:	e194                	sd	a3,0(a1)
    80005fb4:	4589                	li	a1,2
    80005fb6:	14459073          	csrw	sip,a1
    80005fba:	6914                	ld	a3,16(a0)
    80005fbc:	6510                	ld	a2,8(a0)
    80005fbe:	610c                	ld	a1,0(a0)
    80005fc0:	34051573          	csrrw	a0,mscratch,a0
    80005fc4:	30200073          	mret
	...

0000000080005fca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fca:	1141                	addi	sp,sp,-16
    80005fcc:	e422                	sd	s0,8(sp)
    80005fce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fd0:	0c0007b7          	lui	a5,0xc000
    80005fd4:	4705                	li	a4,1
    80005fd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fd8:	c3d8                	sw	a4,4(a5)
}
    80005fda:	6422                	ld	s0,8(sp)
    80005fdc:	0141                	addi	sp,sp,16
    80005fde:	8082                	ret

0000000080005fe0 <plicinithart>:

void
plicinithart(void)
{
    80005fe0:	1141                	addi	sp,sp,-16
    80005fe2:	e406                	sd	ra,8(sp)
    80005fe4:	e022                	sd	s0,0(sp)
    80005fe6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	992080e7          	jalr	-1646(ra) # 8000197a <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ff0:	0085171b          	slliw	a4,a0,0x8
    80005ff4:	0c0027b7          	lui	a5,0xc002
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	40200713          	li	a4,1026
    80005ffe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006002:	00d5151b          	slliw	a0,a0,0xd
    80006006:	0c2017b7          	lui	a5,0xc201
    8000600a:	953e                	add	a0,a0,a5
    8000600c:	00052023          	sw	zero,0(a0)
}
    80006010:	60a2                	ld	ra,8(sp)
    80006012:	6402                	ld	s0,0(sp)
    80006014:	0141                	addi	sp,sp,16
    80006016:	8082                	ret

0000000080006018 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006018:	1141                	addi	sp,sp,-16
    8000601a:	e406                	sd	ra,8(sp)
    8000601c:	e022                	sd	s0,0(sp)
    8000601e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006020:	ffffc097          	auipc	ra,0xffffc
    80006024:	95a080e7          	jalr	-1702(ra) # 8000197a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006028:	00d5179b          	slliw	a5,a0,0xd
    8000602c:	0c201537          	lui	a0,0xc201
    80006030:	953e                	add	a0,a0,a5
  return irq;
}
    80006032:	4148                	lw	a0,4(a0)
    80006034:	60a2                	ld	ra,8(sp)
    80006036:	6402                	ld	s0,0(sp)
    80006038:	0141                	addi	sp,sp,16
    8000603a:	8082                	ret

000000008000603c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000603c:	1101                	addi	sp,sp,-32
    8000603e:	ec06                	sd	ra,24(sp)
    80006040:	e822                	sd	s0,16(sp)
    80006042:	e426                	sd	s1,8(sp)
    80006044:	1000                	addi	s0,sp,32
    80006046:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	932080e7          	jalr	-1742(ra) # 8000197a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006050:	00d5151b          	slliw	a0,a0,0xd
    80006054:	0c2017b7          	lui	a5,0xc201
    80006058:	97aa                	add	a5,a5,a0
    8000605a:	c3c4                	sw	s1,4(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6105                	addi	sp,sp,32
    80006064:	8082                	ret

0000000080006066 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006066:	1141                	addi	sp,sp,-16
    80006068:	e406                	sd	ra,8(sp)
    8000606a:	e022                	sd	s0,0(sp)
    8000606c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000606e:	479d                	li	a5,7
    80006070:	06a7c963          	blt	a5,a0,800060e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006074:	00029797          	auipc	a5,0x29
    80006078:	f8c78793          	addi	a5,a5,-116 # 8002f000 <disk>
    8000607c:	00a78733          	add	a4,a5,a0
    80006080:	6789                	lui	a5,0x2
    80006082:	97ba                	add	a5,a5,a4
    80006084:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006088:	e7ad                	bnez	a5,800060f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000608a:	00451793          	slli	a5,a0,0x4
    8000608e:	0002b717          	auipc	a4,0x2b
    80006092:	f7270713          	addi	a4,a4,-142 # 80031000 <disk+0x2000>
    80006096:	6314                	ld	a3,0(a4)
    80006098:	96be                	add	a3,a3,a5
    8000609a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000609e:	6314                	ld	a3,0(a4)
    800060a0:	96be                	add	a3,a3,a5
    800060a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800060a6:	6314                	ld	a3,0(a4)
    800060a8:	96be                	add	a3,a3,a5
    800060aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800060ae:	6318                	ld	a4,0(a4)
    800060b0:	97ba                	add	a5,a5,a4
    800060b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800060b6:	00029797          	auipc	a5,0x29
    800060ba:	f4a78793          	addi	a5,a5,-182 # 8002f000 <disk>
    800060be:	97aa                	add	a5,a5,a0
    800060c0:	6509                	lui	a0,0x2
    800060c2:	953e                	add	a0,a0,a5
    800060c4:	4785                	li	a5,1
    800060c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060ca:	0002b517          	auipc	a0,0x2b
    800060ce:	f4e50513          	addi	a0,a0,-178 # 80031018 <disk+0x2018>
    800060d2:	ffffc097          	auipc	ra,0xffffc
    800060d6:	30e080e7          	jalr	782(ra) # 800023e0 <wakeup>
}
    800060da:	60a2                	ld	ra,8(sp)
    800060dc:	6402                	ld	s0,0(sp)
    800060de:	0141                	addi	sp,sp,16
    800060e0:	8082                	ret
    panic("free_desc 1");
    800060e2:	00002517          	auipc	a0,0x2
    800060e6:	63650513          	addi	a0,a0,1590 # 80008718 <syscalls+0x330>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	446080e7          	jalr	1094(ra) # 80000530 <panic>
    panic("free_desc 2");
    800060f2:	00002517          	auipc	a0,0x2
    800060f6:	63650513          	addi	a0,a0,1590 # 80008728 <syscalls+0x340>
    800060fa:	ffffa097          	auipc	ra,0xffffa
    800060fe:	436080e7          	jalr	1078(ra) # 80000530 <panic>

0000000080006102 <virtio_disk_init>:
{
    80006102:	1101                	addi	sp,sp,-32
    80006104:	ec06                	sd	ra,24(sp)
    80006106:	e822                	sd	s0,16(sp)
    80006108:	e426                	sd	s1,8(sp)
    8000610a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000610c:	00002597          	auipc	a1,0x2
    80006110:	62c58593          	addi	a1,a1,1580 # 80008738 <syscalls+0x350>
    80006114:	0002b517          	auipc	a0,0x2b
    80006118:	01450513          	addi	a0,a0,20 # 80031128 <disk+0x2128>
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	a2a080e7          	jalr	-1494(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006124:	100017b7          	lui	a5,0x10001
    80006128:	4398                	lw	a4,0(a5)
    8000612a:	2701                	sext.w	a4,a4
    8000612c:	747277b7          	lui	a5,0x74727
    80006130:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006134:	0ef71163          	bne	a4,a5,80006216 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006138:	100017b7          	lui	a5,0x10001
    8000613c:	43dc                	lw	a5,4(a5)
    8000613e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006140:	4705                	li	a4,1
    80006142:	0ce79a63          	bne	a5,a4,80006216 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006146:	100017b7          	lui	a5,0x10001
    8000614a:	479c                	lw	a5,8(a5)
    8000614c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000614e:	4709                	li	a4,2
    80006150:	0ce79363          	bne	a5,a4,80006216 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006154:	100017b7          	lui	a5,0x10001
    80006158:	47d8                	lw	a4,12(a5)
    8000615a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000615c:	554d47b7          	lui	a5,0x554d4
    80006160:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006164:	0af71963          	bne	a4,a5,80006216 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006168:	100017b7          	lui	a5,0x10001
    8000616c:	4705                	li	a4,1
    8000616e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006170:	470d                	li	a4,3
    80006172:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006174:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006176:	c7ffe737          	lui	a4,0xc7ffe
    8000617a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc75f>
    8000617e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006180:	2701                	sext.w	a4,a4
    80006182:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006184:	472d                	li	a4,11
    80006186:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006188:	473d                	li	a4,15
    8000618a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000618c:	6705                	lui	a4,0x1
    8000618e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006190:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006194:	5bdc                	lw	a5,52(a5)
    80006196:	2781                	sext.w	a5,a5
  if(max == 0)
    80006198:	c7d9                	beqz	a5,80006226 <virtio_disk_init+0x124>
  if(max < NUM)
    8000619a:	471d                	li	a4,7
    8000619c:	08f77d63          	bgeu	a4,a5,80006236 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061a0:	100014b7          	lui	s1,0x10001
    800061a4:	47a1                	li	a5,8
    800061a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800061a8:	6609                	lui	a2,0x2
    800061aa:	4581                	li	a1,0
    800061ac:	00029517          	auipc	a0,0x29
    800061b0:	e5450513          	addi	a0,a0,-428 # 8002f000 <disk>
    800061b4:	ffffb097          	auipc	ra,0xffffb
    800061b8:	b1e080e7          	jalr	-1250(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800061bc:	00029717          	auipc	a4,0x29
    800061c0:	e4470713          	addi	a4,a4,-444 # 8002f000 <disk>
    800061c4:	00c75793          	srli	a5,a4,0xc
    800061c8:	2781                	sext.w	a5,a5
    800061ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800061cc:	0002b797          	auipc	a5,0x2b
    800061d0:	e3478793          	addi	a5,a5,-460 # 80031000 <disk+0x2000>
    800061d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800061d6:	00029717          	auipc	a4,0x29
    800061da:	eaa70713          	addi	a4,a4,-342 # 8002f080 <disk+0x80>
    800061de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061e0:	0002a717          	auipc	a4,0x2a
    800061e4:	e2070713          	addi	a4,a4,-480 # 80030000 <disk+0x1000>
    800061e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061ea:	4705                	li	a4,1
    800061ec:	00e78c23          	sb	a4,24(a5)
    800061f0:	00e78ca3          	sb	a4,25(a5)
    800061f4:	00e78d23          	sb	a4,26(a5)
    800061f8:	00e78da3          	sb	a4,27(a5)
    800061fc:	00e78e23          	sb	a4,28(a5)
    80006200:	00e78ea3          	sb	a4,29(a5)
    80006204:	00e78f23          	sb	a4,30(a5)
    80006208:	00e78fa3          	sb	a4,31(a5)
}
    8000620c:	60e2                	ld	ra,24(sp)
    8000620e:	6442                	ld	s0,16(sp)
    80006210:	64a2                	ld	s1,8(sp)
    80006212:	6105                	addi	sp,sp,32
    80006214:	8082                	ret
    panic("could not find virtio disk");
    80006216:	00002517          	auipc	a0,0x2
    8000621a:	53250513          	addi	a0,a0,1330 # 80008748 <syscalls+0x360>
    8000621e:	ffffa097          	auipc	ra,0xffffa
    80006222:	312080e7          	jalr	786(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006226:	00002517          	auipc	a0,0x2
    8000622a:	54250513          	addi	a0,a0,1346 # 80008768 <syscalls+0x380>
    8000622e:	ffffa097          	auipc	ra,0xffffa
    80006232:	302080e7          	jalr	770(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006236:	00002517          	auipc	a0,0x2
    8000623a:	55250513          	addi	a0,a0,1362 # 80008788 <syscalls+0x3a0>
    8000623e:	ffffa097          	auipc	ra,0xffffa
    80006242:	2f2080e7          	jalr	754(ra) # 80000530 <panic>

0000000080006246 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006246:	7159                	addi	sp,sp,-112
    80006248:	f486                	sd	ra,104(sp)
    8000624a:	f0a2                	sd	s0,96(sp)
    8000624c:	eca6                	sd	s1,88(sp)
    8000624e:	e8ca                	sd	s2,80(sp)
    80006250:	e4ce                	sd	s3,72(sp)
    80006252:	e0d2                	sd	s4,64(sp)
    80006254:	fc56                	sd	s5,56(sp)
    80006256:	f85a                	sd	s6,48(sp)
    80006258:	f45e                	sd	s7,40(sp)
    8000625a:	f062                	sd	s8,32(sp)
    8000625c:	ec66                	sd	s9,24(sp)
    8000625e:	e86a                	sd	s10,16(sp)
    80006260:	1880                	addi	s0,sp,112
    80006262:	892a                	mv	s2,a0
    80006264:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006266:	00c52c83          	lw	s9,12(a0)
    8000626a:	001c9c9b          	slliw	s9,s9,0x1
    8000626e:	1c82                	slli	s9,s9,0x20
    80006270:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006274:	0002b517          	auipc	a0,0x2b
    80006278:	eb450513          	addi	a0,a0,-332 # 80031128 <disk+0x2128>
    8000627c:	ffffb097          	auipc	ra,0xffffb
    80006280:	95a080e7          	jalr	-1702(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006284:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006286:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006288:	00029b97          	auipc	s7,0x29
    8000628c:	d78b8b93          	addi	s7,s7,-648 # 8002f000 <disk>
    80006290:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006292:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006294:	8a4e                	mv	s4,s3
    80006296:	a051                	j	8000631a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006298:	00fb86b3          	add	a3,s7,a5
    8000629c:	96da                	add	a3,a3,s6
    8000629e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800062a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800062a4:	0207c563          	bltz	a5,800062ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800062a8:	2485                	addiw	s1,s1,1
    800062aa:	0711                	addi	a4,a4,4
    800062ac:	25548063          	beq	s1,s5,800064ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800062b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800062b2:	0002b697          	auipc	a3,0x2b
    800062b6:	d6668693          	addi	a3,a3,-666 # 80031018 <disk+0x2018>
    800062ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800062bc:	0006c583          	lbu	a1,0(a3)
    800062c0:	fde1                	bnez	a1,80006298 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800062c2:	2785                	addiw	a5,a5,1
    800062c4:	0685                	addi	a3,a3,1
    800062c6:	ff879be3          	bne	a5,s8,800062bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062ca:	57fd                	li	a5,-1
    800062cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800062ce:	02905a63          	blez	s1,80006302 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062d2:	f9042503          	lw	a0,-112(s0)
    800062d6:	00000097          	auipc	ra,0x0
    800062da:	d90080e7          	jalr	-624(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    800062de:	4785                	li	a5,1
    800062e0:	0297d163          	bge	a5,s1,80006302 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062e4:	f9442503          	lw	a0,-108(s0)
    800062e8:	00000097          	auipc	ra,0x0
    800062ec:	d7e080e7          	jalr	-642(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    800062f0:	4789                	li	a5,2
    800062f2:	0097d863          	bge	a5,s1,80006302 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062f6:	f9842503          	lw	a0,-104(s0)
    800062fa:	00000097          	auipc	ra,0x0
    800062fe:	d6c080e7          	jalr	-660(ra) # 80006066 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006302:	0002b597          	auipc	a1,0x2b
    80006306:	e2658593          	addi	a1,a1,-474 # 80031128 <disk+0x2128>
    8000630a:	0002b517          	auipc	a0,0x2b
    8000630e:	d0e50513          	addi	a0,a0,-754 # 80031018 <disk+0x2018>
    80006312:	ffffc097          	auipc	ra,0xffffc
    80006316:	f48080e7          	jalr	-184(ra) # 8000225a <sleep>
  for(int i = 0; i < 3; i++){
    8000631a:	f9040713          	addi	a4,s0,-112
    8000631e:	84ce                	mv	s1,s3
    80006320:	bf41                	j	800062b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006322:	20058713          	addi	a4,a1,512
    80006326:	00471693          	slli	a3,a4,0x4
    8000632a:	00029717          	auipc	a4,0x29
    8000632e:	cd670713          	addi	a4,a4,-810 # 8002f000 <disk>
    80006332:	9736                	add	a4,a4,a3
    80006334:	4685                	li	a3,1
    80006336:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000633a:	20058713          	addi	a4,a1,512
    8000633e:	00471693          	slli	a3,a4,0x4
    80006342:	00029717          	auipc	a4,0x29
    80006346:	cbe70713          	addi	a4,a4,-834 # 8002f000 <disk>
    8000634a:	9736                	add	a4,a4,a3
    8000634c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006350:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006354:	7679                	lui	a2,0xffffe
    80006356:	963e                	add	a2,a2,a5
    80006358:	0002b697          	auipc	a3,0x2b
    8000635c:	ca868693          	addi	a3,a3,-856 # 80031000 <disk+0x2000>
    80006360:	6298                	ld	a4,0(a3)
    80006362:	9732                	add	a4,a4,a2
    80006364:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006366:	6298                	ld	a4,0(a3)
    80006368:	9732                	add	a4,a4,a2
    8000636a:	4541                	li	a0,16
    8000636c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000636e:	6298                	ld	a4,0(a3)
    80006370:	9732                	add	a4,a4,a2
    80006372:	4505                	li	a0,1
    80006374:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006378:	f9442703          	lw	a4,-108(s0)
    8000637c:	6288                	ld	a0,0(a3)
    8000637e:	962a                	add	a2,a2,a0
    80006380:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcc00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006384:	0712                	slli	a4,a4,0x4
    80006386:	6290                	ld	a2,0(a3)
    80006388:	963a                	add	a2,a2,a4
    8000638a:	05890513          	addi	a0,s2,88
    8000638e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006390:	6294                	ld	a3,0(a3)
    80006392:	96ba                	add	a3,a3,a4
    80006394:	40000613          	li	a2,1024
    80006398:	c690                	sw	a2,8(a3)
  if(write)
    8000639a:	140d0063          	beqz	s10,800064da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000639e:	0002b697          	auipc	a3,0x2b
    800063a2:	c626b683          	ld	a3,-926(a3) # 80031000 <disk+0x2000>
    800063a6:	96ba                	add	a3,a3,a4
    800063a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063ac:	00029817          	auipc	a6,0x29
    800063b0:	c5480813          	addi	a6,a6,-940 # 8002f000 <disk>
    800063b4:	0002b517          	auipc	a0,0x2b
    800063b8:	c4c50513          	addi	a0,a0,-948 # 80031000 <disk+0x2000>
    800063bc:	6114                	ld	a3,0(a0)
    800063be:	96ba                	add	a3,a3,a4
    800063c0:	00c6d603          	lhu	a2,12(a3)
    800063c4:	00166613          	ori	a2,a2,1
    800063c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063cc:	f9842683          	lw	a3,-104(s0)
    800063d0:	6110                	ld	a2,0(a0)
    800063d2:	9732                	add	a4,a4,a2
    800063d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063d8:	20058613          	addi	a2,a1,512
    800063dc:	0612                	slli	a2,a2,0x4
    800063de:	9642                	add	a2,a2,a6
    800063e0:	577d                	li	a4,-1
    800063e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063e6:	00469713          	slli	a4,a3,0x4
    800063ea:	6114                	ld	a3,0(a0)
    800063ec:	96ba                	add	a3,a3,a4
    800063ee:	03078793          	addi	a5,a5,48
    800063f2:	97c2                	add	a5,a5,a6
    800063f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800063f6:	611c                	ld	a5,0(a0)
    800063f8:	97ba                	add	a5,a5,a4
    800063fa:	4685                	li	a3,1
    800063fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063fe:	611c                	ld	a5,0(a0)
    80006400:	97ba                	add	a5,a5,a4
    80006402:	4809                	li	a6,2
    80006404:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006408:	611c                	ld	a5,0(a0)
    8000640a:	973e                	add	a4,a4,a5
    8000640c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006410:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006414:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006418:	6518                	ld	a4,8(a0)
    8000641a:	00275783          	lhu	a5,2(a4)
    8000641e:	8b9d                	andi	a5,a5,7
    80006420:	0786                	slli	a5,a5,0x1
    80006422:	97ba                	add	a5,a5,a4
    80006424:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006428:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000642c:	6518                	ld	a4,8(a0)
    8000642e:	00275783          	lhu	a5,2(a4)
    80006432:	2785                	addiw	a5,a5,1
    80006434:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006438:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006444:	00492703          	lw	a4,4(s2)
    80006448:	4785                	li	a5,1
    8000644a:	02f71163          	bne	a4,a5,8000646c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000644e:	0002b997          	auipc	s3,0x2b
    80006452:	cda98993          	addi	s3,s3,-806 # 80031128 <disk+0x2128>
  while(b->disk == 1) {
    80006456:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006458:	85ce                	mv	a1,s3
    8000645a:	854a                	mv	a0,s2
    8000645c:	ffffc097          	auipc	ra,0xffffc
    80006460:	dfe080e7          	jalr	-514(ra) # 8000225a <sleep>
  while(b->disk == 1) {
    80006464:	00492783          	lw	a5,4(s2)
    80006468:	fe9788e3          	beq	a5,s1,80006458 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000646c:	f9042903          	lw	s2,-112(s0)
    80006470:	20090793          	addi	a5,s2,512
    80006474:	00479713          	slli	a4,a5,0x4
    80006478:	00029797          	auipc	a5,0x29
    8000647c:	b8878793          	addi	a5,a5,-1144 # 8002f000 <disk>
    80006480:	97ba                	add	a5,a5,a4
    80006482:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006486:	0002b997          	auipc	s3,0x2b
    8000648a:	b7a98993          	addi	s3,s3,-1158 # 80031000 <disk+0x2000>
    8000648e:	00491713          	slli	a4,s2,0x4
    80006492:	0009b783          	ld	a5,0(s3)
    80006496:	97ba                	add	a5,a5,a4
    80006498:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000649c:	854a                	mv	a0,s2
    8000649e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064a2:	00000097          	auipc	ra,0x0
    800064a6:	bc4080e7          	jalr	-1084(ra) # 80006066 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064aa:	8885                	andi	s1,s1,1
    800064ac:	f0ed                	bnez	s1,8000648e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064ae:	0002b517          	auipc	a0,0x2b
    800064b2:	c7a50513          	addi	a0,a0,-902 # 80031128 <disk+0x2128>
    800064b6:	ffffa097          	auipc	ra,0xffffa
    800064ba:	7d4080e7          	jalr	2004(ra) # 80000c8a <release>
}
    800064be:	70a6                	ld	ra,104(sp)
    800064c0:	7406                	ld	s0,96(sp)
    800064c2:	64e6                	ld	s1,88(sp)
    800064c4:	6946                	ld	s2,80(sp)
    800064c6:	69a6                	ld	s3,72(sp)
    800064c8:	6a06                	ld	s4,64(sp)
    800064ca:	7ae2                	ld	s5,56(sp)
    800064cc:	7b42                	ld	s6,48(sp)
    800064ce:	7ba2                	ld	s7,40(sp)
    800064d0:	7c02                	ld	s8,32(sp)
    800064d2:	6ce2                	ld	s9,24(sp)
    800064d4:	6d42                	ld	s10,16(sp)
    800064d6:	6165                	addi	sp,sp,112
    800064d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064da:	0002b697          	auipc	a3,0x2b
    800064de:	b266b683          	ld	a3,-1242(a3) # 80031000 <disk+0x2000>
    800064e2:	96ba                	add	a3,a3,a4
    800064e4:	4609                	li	a2,2
    800064e6:	00c69623          	sh	a2,12(a3)
    800064ea:	b5c9                	j	800063ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064ec:	f9042583          	lw	a1,-112(s0)
    800064f0:	20058793          	addi	a5,a1,512
    800064f4:	0792                	slli	a5,a5,0x4
    800064f6:	00029517          	auipc	a0,0x29
    800064fa:	bb250513          	addi	a0,a0,-1102 # 8002f0a8 <disk+0xa8>
    800064fe:	953e                	add	a0,a0,a5
  if(write)
    80006500:	e20d11e3          	bnez	s10,80006322 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006504:	20058713          	addi	a4,a1,512
    80006508:	00471693          	slli	a3,a4,0x4
    8000650c:	00029717          	auipc	a4,0x29
    80006510:	af470713          	addi	a4,a4,-1292 # 8002f000 <disk>
    80006514:	9736                	add	a4,a4,a3
    80006516:	0a072423          	sw	zero,168(a4)
    8000651a:	b505                	j	8000633a <virtio_disk_rw+0xf4>

000000008000651c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000651c:	1101                	addi	sp,sp,-32
    8000651e:	ec06                	sd	ra,24(sp)
    80006520:	e822                	sd	s0,16(sp)
    80006522:	e426                	sd	s1,8(sp)
    80006524:	e04a                	sd	s2,0(sp)
    80006526:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006528:	0002b517          	auipc	a0,0x2b
    8000652c:	c0050513          	addi	a0,a0,-1024 # 80031128 <disk+0x2128>
    80006530:	ffffa097          	auipc	ra,0xffffa
    80006534:	6a6080e7          	jalr	1702(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006538:	10001737          	lui	a4,0x10001
    8000653c:	533c                	lw	a5,96(a4)
    8000653e:	8b8d                	andi	a5,a5,3
    80006540:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006542:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006546:	0002b797          	auipc	a5,0x2b
    8000654a:	aba78793          	addi	a5,a5,-1350 # 80031000 <disk+0x2000>
    8000654e:	6b94                	ld	a3,16(a5)
    80006550:	0207d703          	lhu	a4,32(a5)
    80006554:	0026d783          	lhu	a5,2(a3)
    80006558:	06f70163          	beq	a4,a5,800065ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000655c:	00029917          	auipc	s2,0x29
    80006560:	aa490913          	addi	s2,s2,-1372 # 8002f000 <disk>
    80006564:	0002b497          	auipc	s1,0x2b
    80006568:	a9c48493          	addi	s1,s1,-1380 # 80031000 <disk+0x2000>
    __sync_synchronize();
    8000656c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006570:	6898                	ld	a4,16(s1)
    80006572:	0204d783          	lhu	a5,32(s1)
    80006576:	8b9d                	andi	a5,a5,7
    80006578:	078e                	slli	a5,a5,0x3
    8000657a:	97ba                	add	a5,a5,a4
    8000657c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000657e:	20078713          	addi	a4,a5,512
    80006582:	0712                	slli	a4,a4,0x4
    80006584:	974a                	add	a4,a4,s2
    80006586:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000658a:	e731                	bnez	a4,800065d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000658c:	20078793          	addi	a5,a5,512
    80006590:	0792                	slli	a5,a5,0x4
    80006592:	97ca                	add	a5,a5,s2
    80006594:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006596:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000659a:	ffffc097          	auipc	ra,0xffffc
    8000659e:	e46080e7          	jalr	-442(ra) # 800023e0 <wakeup>

    disk.used_idx += 1;
    800065a2:	0204d783          	lhu	a5,32(s1)
    800065a6:	2785                	addiw	a5,a5,1
    800065a8:	17c2                	slli	a5,a5,0x30
    800065aa:	93c1                	srli	a5,a5,0x30
    800065ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800065b0:	6898                	ld	a4,16(s1)
    800065b2:	00275703          	lhu	a4,2(a4)
    800065b6:	faf71be3          	bne	a4,a5,8000656c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800065ba:	0002b517          	auipc	a0,0x2b
    800065be:	b6e50513          	addi	a0,a0,-1170 # 80031128 <disk+0x2128>
    800065c2:	ffffa097          	auipc	ra,0xffffa
    800065c6:	6c8080e7          	jalr	1736(ra) # 80000c8a <release>
}
    800065ca:	60e2                	ld	ra,24(sp)
    800065cc:	6442                	ld	s0,16(sp)
    800065ce:	64a2                	ld	s1,8(sp)
    800065d0:	6902                	ld	s2,0(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret
      panic("virtio_disk_intr status");
    800065d6:	00002517          	auipc	a0,0x2
    800065da:	1d250513          	addi	a0,a0,466 # 800087a8 <syscalls+0x3c0>
    800065de:	ffffa097          	auipc	ra,0xffffa
    800065e2:	f52080e7          	jalr	-174(ra) # 80000530 <panic>
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
