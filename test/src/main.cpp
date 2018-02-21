#include <iostream>
#include <string>
#include <Record.hpp>
#include <Recorder.hpp>

std::string filename = "file.save";

int main()
{
    {
        Recorder recorder(filename, Recorder::writable);
        Record empty;

        for(int k = 0; k < 10; k++)
        {
            recorder.write(empty, k);
        }

        Record noEmpty;
        noEmpty.setData(49);
        recorder.write(noEmpty, 7);
        noEmpty.setData(50);
        recorder.write(noEmpty, 9);
    }

    {
        Recorder recorder(filename, Recorder::readable);
        Record temp;

        for(int k = 0; k < 10; k++)
        {
            recorder.read(temp, k);
            std::cout << temp.getData() << '\n';
        }
    }
}
