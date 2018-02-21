#include <Recorder.hpp>

Recorder::Recorder(std::string _filename, Recorder::Mode _mode)
{
    std::fstream::openmode mode;

    if(_mode == Recorder::readable)
    {
        mode = std::fstream::in | std::fstream::binary;
    }
    else
    {
        mode = std::fstream::out | std::fstream::ate | std::fstream::binary;
    }

    m_file.open(_filename, mode);
}

Recorder::~Recorder()
{
    m_file.flush();
    m_file.close();
}

void Recorder::write(Record & _rec, unsigned long _pos)
{
    m_file.seekp(_pos * sizeof(Record), std::ios::beg);
    m_file.write((char *)(& _rec), sizeof(Record));
}


void Recorder::read(Record & _rec, unsigned long _pos)
{
    m_file.seekg(_pos * sizeof(Record), std::ios::beg);
    m_file.read((char *)(& _rec), sizeof(Record));
}
