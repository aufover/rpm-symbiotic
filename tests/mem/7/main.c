#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a = malloc(0);
  *a = 42;
}
