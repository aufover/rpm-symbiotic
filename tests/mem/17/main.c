#include<stdlib.h>
typedef struct {
  int a;
  void *b;
} foo;


int main (int argc, char** argv)
{
  foo *a = malloc(sizeof(foo));
  free(a);
  return 0;
}
