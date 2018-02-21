#ifndef RECORDER__HPP
#define RECORDER__HPP

#include <fstream>
#include <string>
#include <Record.hpp>

class Recorder
{
public:
    enum Mode
    {
        readable = 0,
        writable = 1
    };

    explicit Recorder(std::string _filename, Recorder::Mode _mode);
    virtual ~Recorder();

    void write(Record & _rec, unsigned long _pos);
    void read(Record & _rec, unsigned long _pos);

private:
    std::fstream m_file;
};

#endif
