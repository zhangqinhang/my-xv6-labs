#include "kernel/types.h"
#include "user/user.h"
#include "stddef.h"
//使用 UNIX 系统调用编写一个程序 pingpong ，在一对管道上实现两个进程之间的通信。父进程应该通过第一个管道给子进程发送一个信息 “ping”，子进程接收父进程的信息后打印 "<pid>: received ping" ，其中是其进程 ID 。然后子进程通过另一个管道发送一个信息 “pong” 给父进程，父进程接收子进程的信息然后打印 "<pid>: received pong" ，然后退出

int
main(int argc, char *argv[])
{
    int ptoc_fd[2], ctop_fd[2];//文件描述符，用于创建管道
    pipe(ptoc_fd);
    pipe(ctop_fd);
    char buf[8];
    if (fork() == 0) {
        //子进程
        read(ptoc_fd[0], buf, 4);
        printf("%d: received %s\n", getpid(), buf);
        write(ctop_fd[1], "pong", strlen("pong"));
    }
    else {
        //父进程
        write(ptoc_fd[1], "ping", strlen("ping"));
        wait(NULL);
        read(ctop_fd[0], buf, 4);
        printf("%d: received %s\n", getpid(), buf);
    }
    exit(0);
}

