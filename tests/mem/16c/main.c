#include<stdlib.h>

void foo (int *a)
{
  a = malloc(sizeof(int));
}

void bar (int *a)
{
  free(a);
}

int main (int argc, char** argv)
{
  int *a;
  foo(a);
  *a = 42;
  bar(&a);
  return 0;
}
