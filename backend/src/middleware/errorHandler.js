import { ZodError } from "zod";


export function errorHandler(err, req, res, next) {
    if(err instanceof ZodError){
        return res.status(400).json({
            error: { code:'VALIDATION_ERROR', message: 'Invalid request', details:err.flatten().fieldErrors},
        });
    }

    const status = err.status || 500;
    if(status >= 500) console.error(err);

    res.status(status).json({
        error: {
            code: err.code || 'INTERNAL_ERROR',
            message: status >= 500 ? 'Something went wrong' : err.message,
        },
    });
}