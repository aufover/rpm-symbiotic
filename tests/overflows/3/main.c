#include<limits.h>
int main (int argc, char** argv)
{
  signed char a = SCHAR_MAX;
  a += 10;//this should not trigger overflow error
}
