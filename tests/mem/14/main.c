#include<stdlib.h>

int* foo (void)
{
  int *a = malloc(sizeof(int));
  return a;
}

int main (int argc, char** argv)
{
  int *a;
  a = foo();
  *a = 42;
  free(a);
  return 0;
}
