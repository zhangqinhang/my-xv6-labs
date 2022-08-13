#include "kernel/types.h"
#include "user/user.h"
//为 xv6 系统实现 UNIX 的 sleep 程序。你的 sleep 程序应该使当前进程暂停相应的时钟周期数，时钟周期数由用户指定。例如执行 sleep 100 ，则当前进程暂停，等待 100 个时钟周期后才继续执行。
int
main(int argc, char *argv[])
{
    //参数不满两个，打印错误信息
    if (argc != 2)
    {
        write(2, "Usage: sleep time\n", strlen("Usage: sleep time\n"));
        exit(1);
    }
    //把字符串的参数转换成为整型
    int time = atoi(argv[1]);
    //调用系统的sleep函数，传入转换好的整形参数
    sleep(time);
    exit(0);
    //测试代码：./grade-lab-util sleep
}
