// const connection =require('./db.js');
import connection from './db.js';
const exeCommand=(command)=>{
    return new Promise((resolve,reject)=>{
        connection.query(command,(err,result)=>{
            if(err) reject(err)
            else resolve(result)
        })

    })
}
export default exeCommand;
